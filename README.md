# 📉 SaaS Customer Churn Analysis & Retention Dashboard

**End-to-end data analytics project using Python, MySQL, and Power BI to find why a B2B SaaS company loses customers, and which active customers are most at risk next.**

![Python](https://img.shields.io/badge/Python-Pandas%20%7C%20NumPy-3776AB?logo=python&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-Analysis-4479A1?logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

---

## 📌 Table of Contents
1. [Business Problem](#-business-problem)
2. [Key Results at a Glance](#-key-results-at-a-glance)
3. [Dataset](#-dataset)
4. [Tools & Workflow](#-tools--workflow)
5. [Data Cleaning (Python)](#-data-cleaning-python)
6. [Analysis (MySQL)](#-analysis-mysql)
7. [Key Insights](#-key-insights)
8. [Dashboard (Power BI)](#-dashboard-power-bi)
9. [Recommendations](#-recommendations)
10. [Limitations & Next Steps](#-limitations--next-steps)
11. [How to Run](#-how-to-run)
12. [About Me](#-about-me)

---

## 🎯 Business Problem

A B2B SaaS company is losing paying customers every month. New signups are not enough to cover the Monthly Recurring Revenue (MRR) leaking out through cancellations.

**Goal:** Analyse customer usage, support, and payment data to:
- Find **where** customers are being lost
- Understand **why** they cancel
- Flag **active customers at risk** so the Customer Success team can act early

---

## 🚀 Key Results at a Glance

| Metric | Value |
|---|---|
| Customers analysed | **43,912** |
| Customer churn rate | **14.94%** (6,559 customers) |
| Total MRR | **$137.39M** |
| MRR lost to churn | **$14.44M** (10.51%) |
| Month-1 churn | **52.35%** |
| Churn without onboarding vs with | **39.5% vs 8.0%** (~5x higher) |
| Active MRR flagged as High Risk | **~$23M** |

---

## 📂 Dataset

- **Source:** Raw customer-level SaaS dataset (`Saas_Churn_Raw_Dataset.csv`, 44,440 rows, 24 columns)
- **After cleaning:** 43,912 rows (`Saas_Churn_Cleaned_Data.csv`)
- **Grain:** One row per customer

| Category | Columns |
|---|---|
| **Customer profile** | `Customer_Id`, `Signup_Date`, `Plan_Type`, `Industry`, `Company_Size`, `Country`, `Acquisition_Channel` |
| **Subscription** | `Billing_Cycle`, `Seats_Purchased`, `Seats_Active`, `Mrr`, `Onboarding_Completed` |
| **Product usage** | `Avg_Monthly_Logins`, `Features_Used_Count`, `Days_Since_Last_Login` |
| **Support** | `Support_Tickets_90D`, `Avg_Resolution_Hours`, `Csat_Score` |
| **Payments** | `Failed_Payments_6M`, `Payment_Method` |
| **Outcome** | `Customer_Status`, `Churn_Date`, `Tenure_Months`, `Churn_Reason` |

---

## 🛠 Tools & Workflow

| Stage | Tool | What I did |
|---|---|---|
| 1. Cleaning | **Python** (Pandas, NumPy), Jupyter | Removed duplicates, standardised text, handled nulls, fixed dates, engineered `Tenure_Months` |
| 2. Analysis | **MySQL** | Aggregations, `CASE WHEN` bucketing, window functions, risk scoring |
| 3. Visualisation | **Power BI** | Interactive executive dashboard with slicers |
| 4. Storytelling | **PowerPoint** | 10-slide insight deck with "So what" takeaways |

```
Raw CSV  →  Python (clean)  →  MySQL (analyse)  →  Power BI (visualise)  →  Presentation
```

The analysis is structured around three questions:
- **Part A: What happened?** Where are we losing customers (plan, company size, billing, tenure)?
- **Part B: Why did it happen?** Root causes (usage, seats, onboarding, support)
- **Part C: Who is next?** Which active customers should the team contact first?

---

## 🧹 Data Cleaning (Python)

Notebook: [`Saas_Churn_Data_Cleaning.ipynb`](Saas_Churn_Data_Cleaning.ipynb)

- Checked shape, data types, null counts, and duplicate rows; **dropped duplicates**
- **Standardised column names** to Title_Case (e.g. `Plan_Type`, `Csat_Score`)
- **Cleaned categorical text:** trimmed whitespace, fixed casing, replaced underscores in `Payment_Method`
- **Unified inconsistent labels:** `U.S.A` / `Usa` → `USA`, `U.K` / `Uk` → `UK`, `Uae` → `UAE`, `Upi` → `UPI`
- **Handled missing values:**
  - `Industry` and `Acquisition_Channel` → `"Unknown"`
  - `Churn_Reason` for churned customers → `"Not Recorded"`; active customers → `"Unknown"`
  - `Avg_Resolution_Hours` missing but tickets > 0 → `0`
- **Parsed mixed-format dates** into proper date types
- **Removed invalid records** where `Churn_Date` was earlier than `Signup_Date`
- **Feature engineering:** calculated `Tenure_Months` (signup to churn date, or to 30 Nov 2025 for active customers)
- Final validation: no duplicate rows, no duplicate `Customer_Id`, nulls checked, exported the cleaned CSV

**Result:** 44,440 raw rows → **43,912** clean rows.

---

## 🗄 Analysis (MySQL)

Script: [`Saas_Churn_Analysis.sql`](Saas_Churn_Analysis.sql)

SQL techniques used:
- Conditional aggregation (`COUNT(CASE WHEN ...)`, `SUM(CASE WHEN ...)`)
- `GROUP BY` across multiple dimensions
- Window functions (`SUM(COUNT(*)) OVER()`) for percentage share
- `CASE WHEN` to build ticket buckets and a **rule-based risk score**
- `NULLIF` to avoid divide-by-zero in seat utilisation
- `FIELD()` for custom sort order

Each query in the script is followed by commented business insights.

<details>
<summary><b>Example: Active customer risk scoring query</b></summary>

```sql
SELECT Customer_Id, Plan_Type, Mrr, Avg_Monthly_Logins,
       Days_Since_Last_Login, Failed_Payments_6M, Csat_Score,
       CASE
         WHEN Days_Since_Last_Login > 30 OR Avg_Monthly_Logins < 3
              OR Failed_Payments_6M >= 2 OR Csat_Score <= 2 THEN 'High Risk'
         WHEN Days_Since_Last_Login BETWEEN 15 AND 30
              OR Csat_Score = 3 THEN 'Medium Risk'
         ELSE 'Low Risk'
       END AS Churn_Risk_Level
FROM saas_churn
WHERE Customer_Status = 'Active'
ORDER BY Mrr DESC;
```
</details>

---

## 💡 Key Insights

### Part A: What happened
- **Basic plan loses the most customers** (17.10% churn, 3,311 customers), but **Enterprise loses the most money** ($7.31M MRR lost) even with the lowest churn rate (8.80%).
- **Smaller companies churn more:** 18.1% for 1-10 employees vs 9.0% for 1000+ employees.
- **Monthly billing churns far more** than annual: **17.5% vs 10.2%**.
- **The first 90 days decide everything:** churn is **52.35% in Month 1**, 37.84% in Month 2, and 25.17% in Month 3, then settles to about 10% after Month 5.

### Part B: Why it happened
- **Top churn reasons:** Low Product Usage (32.37%) and Pricing Too High (22.73%) together drive **55%+** of all churn.
- **Churned customers used the product far less:**

| Metric | Churned | Active |
|---|---|---|
| Avg monthly logins | 10.62 | 22.52 |
| Features used | 4.22 | 6.84 |
| Days since last login | 17.81 | 7.68 |
| Seat utilisation | 57.02% | 77.18% |
| CSAT score | 2.85 | 3.43 |
| Avg resolution time (hrs) | 13.46 | 10.99 |

- **Onboarding is the biggest controllable factor:** 39.5% churn without onboarding vs 8.0% with it.
- **More tickets, more churn:** 12.05% (0 tickets) rising to 22.57% (4+ tickets), and the 4+ group waits about 17.6 hours for resolution.
- **Combined risk:** Monthly-billed customers who skipped onboarding are the most fragile segment.

### Part C: Who is next
- A rule-based scoring system splits active customers into **High / Medium / Low risk**, sorted by MRR so the biggest accounts get saved first.
- About **$23M of active MRR** sits in the High Risk bucket.

---

## 📊 Dashboard (Power BI)

Files: [`Saas_Churn_Dashboard.pbix`](Saas_Churn_Dashboard.pbix) · [`Saas_Churn_Dashboard.pdf`](Saas_Churn_Dashboard.pdf)

**Executive SaaS Churn & Retention Overview** includes:
- **KPI cards:** Total Customers, Customer Churn Rate, Total MRR, MRR Lost, MRR Churn Rate
- **Slicers:** Plan Type, Industry, Acquisition Channel, Billing Cycle
- **Visuals:**
  - Churn Rate by Customer Tenure
  - Churn Rate vs Revenue Impact (by plan)
  - Churn Rate by Ticket Volume
  - Top Churn Drivers
  - Active Customer Churn Risk Breakdown
  - Churn Rate by Onboarding Status

> To open the `.pbix` file you need [Power BI Desktop](https://powerbi.microsoft.com/desktop/) (free, Windows).

---

## ✅ Recommendations

1. **Fix the first 90 days:** make onboarding mandatory with a guided walkthrough and a 30-day check-in call.
2. **Target the highest-risk segment first:** monthly-billed customers who have not completed onboarding.
3. **Move monthly users to annual plans** with a small discount to improve retention and stabilise revenue.
4. **Use hands-on account management for Enterprise** (biggest dollar loss) and **automated self-serve retention flows for small companies**.
5. **Prioritise repeat-ticket customers** with faster support and escalation rules.
6. **Act on seat under-utilisation:** offer team training or a seat downgrade before the customer cancels.
7. **Give Customer Success the weekly High Risk list**, sorted by MRR.

---

## 🚧 Limitations & Next Steps

- Findings are **descriptive, not causal**: they show what is associated with churn, not what proves it.
- The risk score is **rule-based** with thresholds chosen from the patterns in the data.
- **Next step:** build a predictive churn model (Logistic Regression / XGBoost) on these features and validate it with ROC-AUC and precision/recall.

---


## 🧪 How to Run

1. **Clone the repo**
   ```bash
   git clone https://github.com/<your-username>/saas-churn-analysis.git
   cd saas-churn-analysis
   ```
2. **Clean the data (optional, cleaned file is included)**
   ```bash
   pip install pandas numpy jupyter
   jupyter notebook notebooks/Saas_Churn_Data_Cleaning.ipynb
   ```
3. **Run the SQL analysis**
   - Import `Saas_Churn_Cleaned_Data.csv` into MySQL (table `saas_churn`, schema is at the top of the SQL file)
   - Run `Saas_Churn_Analysis.sql`
4. **Explore the dashboard**
   - Open `Saas_Churn_Dashboard.pbix` in Power BI Desktop, or view the PDF.

---

## 👤 About Me

**Sunny Yadav** | Aspiring Data Analyst
Skills: SQL · Python · Power BI · Data Cleaning · Data Storytelling

📧 ysunny7600@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/sunny-yadav-180ba2227/) · 💻 [GitHub](https://github.com/Sunny7600)

⭐ If you found this project useful, consider giving it a star!

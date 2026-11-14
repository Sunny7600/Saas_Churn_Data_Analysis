CREATE DATABASE saas_db;
USE saas_db;
DROP TABLE IF EXISTS saas_churn;

CREATE TABLE saas_churn (
    Customer_Id VARCHAR(50),
    Signup_Date DATE,
    Plan_Type VARCHAR(50),
    Industry VARCHAR(100),
    Company_Size VARCHAR(50),
    Country VARCHAR(50),
    Acquisition_Channel VARCHAR(50),
    Billing_Cycle VARCHAR(50),
    Seats_Purchased INT,
    Seats_Active INT,
    Mrr DECIMAL(10, 2),
    Onboarding_Completed VARCHAR(10),
    Avg_Monthly_Logins DECIMAL(10, 2),
    Features_Used_Count INT,
    Days_Since_Last_Login INT,
    Support_Tickets_90D INT,
    Avg_Resolution_Hours DECIMAL(10, 2),
    Csat_Score DECIMAL(3, 2),
    Failed_Payments_6M INT,
    Payment_Method VARCHAR(50),
    Customer_Status VARCHAR(50),
    Churn_Date DATE NULL,
    Tenure_Months INT,
    Churn_Reason VARCHAR(255)
);


-- Business Problem: A B2B SaaS company is facing a customer loss problem, where many users are canceling their paid subscriptions every month. Because of this, the company is losing Monthly Recurring Revenue (MRR) despite acquiring new customers. 
-- The goal of this project is to analyze customer usage data, support logs, and payment patterns to find the main reasons behind customer cancellation and identify high-risk users before they leave, so the customer success team can take early action to retain them.

-- How I structured this analysis:
-- Part A - What Happened: Checking where we are losing customers (overall numbers, plans, company size, billing type, and tenure).
-- Part B - Why It Happened: Finding the actual reasons behind churn (user activity, seat usage, onboarding, and support issues).
-- Part C - Risk Check: Flagging current active users who might leave soon so we can reach out early.

-- Start Analysing Data

-- -------x--------x---------x----------

-- PART A - WHAT HAPPENED (where we are losing customers?)

-- Overall Churn Numbers:

-- 1. Around 14.94% of total customers churned (6,559 out of 43,912 users).
-- 2. Because of this, we lost 10.51% of our total monthly revenue ($14.44M lost out of $137.39M).
-- 3. This is a pretty big drop in recurring revenue, so we definitely need to focus on keeping existing users.

Select
count(*) as Total_Customers,
count(case when Customer_Status = 'Churned' then 1 end) as Churned_Customers,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(sum(Mrr), 2) as Total_MRR,
round(sum(case when Customer_Status = 'Churned' then Mrr end), 2) as MRR_Lost,
round(sum(case when Customer_Status = 'Churned' then Mrr end) * 100.0 / sum(Mrr), 2) as MRR_Churn_Rate_Pct
from saas_churn;

-- -------x--------x---------x----------

-- Churn by Plan Type:

-- 1. Enterprise users leave the least (8.80%), but because their plans cost so much, losing them still hurts the most ($7.31M lost).
-- 2. Basic plan has the highest churn rate at 17.10% (3,311 users left), with the Pro plan right behind it at 15.14% (2,599 users left).
-- 3. Basically, lower-tier plans lose way more people in volume, but losing just a handful of big Enterprise clients makes the biggest dent in our revenue.

Select Plan_Type,
count(*) as Total_Customers,
count(case when Customer_Status = 'Churned' then 1 end) as Churned_Count,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(sum(case when Customer_Status = 'Churned' then Mrr end), 2) as Revenue_Lost
from saas_churn
group by Plan_Type
order by Revenue_Lost desc;

-- -------x--------x---------x----------

-- Churn by Company Size:

-- 1. Very small companies (1-10 employees) cancel the most at 18.1%, while enterprise-level companies (1000+ employees) stick around way better with only 9.0% churn.
-- 2. As companies get bigger, churn drops down steadily—looks like smaller companies are much more price-sensitive or lack long-term stability.
-- 3. We should probably handle small accounts with automated, self-serve retention flows, while bigger companies definitely need hands-on account management to keep them happy.

Select Company_Size,
count(*) as Total_Customers,
count(case when Customer_Status = 'Churned' then 1 end) as Churned_Customers,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(sum(case when Customer_Status = 'Churned' then Mrr end), 2) as Revenue_Lost
from saas_churn
group by Company_Size
order by field(Company_Size, '1-10 employees', '11-50 employees', '51-200 employees', '201-1000 employees', '1000+ employees');

-- -------x--------x---------x----------

-- Churn by Billing Cycle:

-- 1. People on monthly plans cancel way more (17.5%) compared to yearly subscribers (10.2%).
-- 2. Annual plans lock users in for longer and give them enough time to actually experience the product's value, which keeps retention high.
-- 3. Pushing monthly users toward yearly plans by offering a small discount would probably help steady our monthly revenue and cut down on churn.

Select Billing_Cycle,
count(*) as Total_Customers,
count(case when Customer_Status = 'Churned' then 1 end) as Churned_Customers,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(sum(case when Customer_Status = 'Churned' then Mrr end), 2) as Revenue_Lost
from saas_churn
group by Billing_Cycle
order by Churn_Rate_Pct desc;

-- -------x--------x---------x----------

-- Customer Tenure & Onboarding:

-- 1. Most people leave right at the beginning—churn spikes heavily in Month 1 (52.35%) and stays pretty high through Month 2 (37.84%) and Month 3 (25.17%).
-- 2. This clearly points to major onboarding friction, meaning new users are struggling to figure out the product or see its value early on.
-- 3. Once users stick around past Month 5, retention stabilizes nicely down to around 10%. Fixing our early setup and onboarding help should be our main priority to stop this initial drop-off.

Select Tenure_Months,
count(*) as Total_Customers,
count(case when Customer_Status = 'Churned' then 1 end) as Churned_Customers,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct
from saas_churn
group by Tenure_Months
order by Tenure_Months asc;

-- -------x--------x---------x----------

-- PART B - WHY HAPPENED (Root Cause Analysis)

-- Main Reasons Why Customers Churned:

-- 1. "Low Product Usage" is the biggest reason people cancel, making up 32.37% of all churn (2,123 users).
-- 2. "Pricing Too High" comes in second at 22.73% (1,491 users).
-- 3. Together, low engagement and pricing issues cause over half (55%+) of all cancellations, showing that users either aren't adopting the tool properly or don't feel they are getting their money's worth.

Select Churn_Reason,
count(*) as Churned_Count,
round(sum(Mrr), 2) as Revenue_Lost,
round(count(*) * 100.0 / sum(count(*)) over(), 2) as Percentage_Share
from saas_churn
where Customer_Status = 'Churned'
group by Churn_Reason
order by Churned_Count desc;

-- -------x--------x---------x----------

-- Product Usage & Engagement:

-- 1. People who cancelled logged in way less—averaging just 10.62 times a month compared to 22.52 logins for active users (more than a 50% drop).
-- 2. Churned users also explored fewer features (4.22 vs 6.84 for active users), which shows they probably didn't get onboarded properly or never found the core tools useful.
-- 3. Inactivity is more than double for users who left (17.81 inactive days on average vs 7.68 days for active ones), making lack of logins a very clear early warning sign.

Select Customer_Status,
round(avg(Avg_Monthly_Logins), 2) as Avg_Logins,
round(avg(Features_Used_Count), 2) as Avg_Features_Used,
round(avg(Days_Since_Last_Login), 2) as Avg_Days_Inactive
from saas_churn
group by Customer_Status;

-- -------x--------x---------x----------

-- Seat Usage & License Adoption:

-- 1. Customers who cancelled were only using about 57.02% of their paid seats (around 30.9 active seats out of 56.6 bought), whereas active users use 77.18%.
-- 2. When teams pay for a bunch of licenses that sit empty, they quickly feel like they're wasting money on unused software.
-- 3. Tracking low seat usage early can help our success team step in—maybe offer team training or let them downgrade their seat count—before they get frustrated and cancel altogether.

Select Customer_Status,
round(avg(Seats_Purchased), 1) as Avg_Seats_Bought,
round(avg(Seats_Active), 1) as Avg_Seats_Active,
round(avg(Seats_Active * 100.0 / nullif(Seats_Purchased, 0)), 2) as Seat_Utilization_Pct
from saas_churn
group by Customer_Status;

-- -------x--------x---------x----------

-- How Onboarding Affects Churn Rate:

-- 1. Users who skip onboarding cancel at a massive 39.5%, compared to just 8.0% for those who finish it (nearly 5 times higher).
-- 2. Looking at this alongside the Month 1-3 drop-off, it's clear that weak onboarding is the biggest problem we can actually control.
-- 3. Making setup mandatory—like adding a quick guided walkthrough or a 30-day check-in call—would immediately cut down early cancellations.

Select Onboarding_Completed,
count(*) as Total_Customers,
count(case when Customer_Status = 'Churned' then 1 end) as Churned_Customers,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(sum(case when Customer_Status = 'Churned' then Mrr end), 2) as Revenue_Lost,
round(avg(Features_Used_Count), 2) as Avg_Features_Used
from saas_churn
group by Onboarding_Completed
order by Churn_Rate_Pct desc;

-- -------x--------x---------x----------

-- Support Experience & CSAT:

-- 1. Customers who left were noticeably less happy, giving an average satisfaction score (CSAT) of 2.85 compared to 3.43 from active users.
-- 2. It also took longer to fix their issues—around 13.46 hours on average versus 10.99 hours for active users—showing clear delays in our support queue.
-- 3. Churned accounts raised slightly more tickets too (1.44 vs 1.21 in 90 days), which means slow fixes and lingering bugs are pushing people away.

Select Customer_Status,
round(avg(Support_Tickets_90D), 2) as Avg_Tickets_90D,
round(avg(Avg_Resolution_Hours), 2) as Avg_Resolution_Time,
round(avg(Csat_Score), 2) as Avg_CSAT
from saas_churn
group by Customer_Status;

-- -------x--------x---------x----------

-- Support Ticket Volume & Escalations:

-- 1. Churn climbs steadily as people submit more tickets—jumping from 12.05% for users with 0 tickets up to 22.57% for accounts with 4 or more tickets.
-- 2. The '4+ Tickets' group also waits the longest for fixes (17.6 hours on average), which shows that recurring or messy problems really frustrate customers.
-- 3. Lots of tickets paired with slow response times is a huge red flag. Setting up faster, priority support rules for repeat-ticket users should help save these accounts.


Select case when Support_Tickets_90D = 0 then '0 Tickets'
when Support_Tickets_90D between 1 and 3 then '1-3 Tickets'
else '4+ Tickets' end as Ticket_Bucket, count(*) as Total_Users,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(avg(Avg_Resolution_Hours), 1) as Avg_Resolution_Time
from saas_churn
group by Ticket_Bucket;

-- -------x--------x---------x----------

-- Onboarding + Billing Cycle Combined Risk:

-- 1. Putting our two biggest risk factors together helps us spot the most fragile group of customers.
-- 2. Monthly users who haven't finished onboarding are by far the most likely to cancel, so our team should reach out to this specific group first.

Select Onboarding_Completed, Billing_Cycle,
count(*) as Total_Customers,
round(count(case when Customer_Status = 'Churned' then 1 end) * 100.0 / count(*), 2) as Churn_Rate_Pct,
round(sum(case when Customer_Status = 'Churned' then Mrr end), 2) as Revenue_Lost
from saas_churn
group by Onboarding_Completed, Billing_Cycle
order by Churn_Rate_Pct desc;

-- -------x--------x---------x----------

-- PART C - RISK OBSERVATION

-- Customer Churn Risk Scoring (Early Warning System) Observation:

-- Active Customer Risk Scoring:

-- 1. Grouped all current active users into 3 clear risk buckets so the retention team knows who needs help first:

--    - High Risk: Users who haven't logged in for over 30 days, log in fewer than 3 times a month, gave a bad CSAT score (2 or below), or had 2+ failed payments. We need to reach out to them right away.
--    - Medium Risk: Users showing early warning signs, like being inactive for 15-30 days or giving an average CSAT score of 3.
--    - Low Risk: Active, happy customers with no payment issues.

-- 2. Sorting the list by highest MRR first puts our biggest Enterprise clients right at the top, helping the success team save the most revenue first.

Select Customer_Id, Plan_Type, Mrr, Avg_Monthly_Logins, Days_Since_Last_Login, Failed_Payments_6M, Csat_Score,
case when Days_Since_Last_Login > 30 or Avg_Monthly_Logins < 3 or Failed_Payments_6M >= 2 or Csat_Score <= 2 then 'High Risk' 
when Days_Since_Last_Login between 15 and 30 or Csat_Score = 3 then 'Medium Risk'
else 'Low Risk' end as Churn_Risk_Level
from saas_churn
where Customer_Status = 'Active'
order by Mrr desc;

-- -------x--------x---------x----------

-- END --

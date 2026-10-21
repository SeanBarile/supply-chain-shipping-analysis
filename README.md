# Supply Chain Shipping Analysis

## Overview

An exploratory analysis of the DataCo Smart Supply Chain dataset, using SQL for analysis and Tableau for visualization. This project is in process. One business question fully answered so far, with more planned.

## Background

15 years of experience in fulfillment, inventory, and operations gave me a habit of noticing when numbers don't add up and digging into why. This project applies that instinct to a public retail supply chain dataset, using it to build and demonstrate SQL and Tableau skills.

## Dataset

[DataCo Smart Supply Chain for Big Data Analysis](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)

About 180,000 rows covering orders, shipping modes, delivery status, product categories, and customer/order details. Sourced from Kaggle.

## Question 1: Which shipping mode has the highest late-delivery rate?

**Why this question?**
Shipping mode reliability directly affects customer trust/satisfaction along with operational cost. I wanted to see whether faster, more expensive shipping options actually deliver on their promise.

```sql
-- Main question: late delivery rate shipping mode
SELECT "Shipping Mode",
       AVG("Late_delivery_risk") * 100 as avg_late_delivery_pct
FROM orders
GROUP BY "Shipping Mode"
ORDER BY avg_late_delivery_pct DESC;
```

**Finding:**
First Class had the highest recorded late-delivery rate at 95.3%, followed by Second Class (76.6%), Same Day (45.7%), and Standard Class (38.1%).

These percentages represent the share of order-item records flagged as late within each shipping mode, including canceled shipments in the total record counts.

![Recorded Late-Delivery Rate by Shipping Mode](/images/Recorded%20Late-Delivery%20Rate%20by%20Shipping%20Mode.png)

**Interpretation:**
Based on my operations experience, I suspected the higher late-delivery rates were related to delivery promise windows rather than differences in handling quality. Faster shipping modes generally have tighter delivery windows, meaning similar shipping times could result in different late-delivery classifications.

To investigate this, I compared scheduled and actual shipping times across the four shipping modes:

| Shipping Mode  | Scheduled (days) | Actual (days) |
| -------------- | ---------------- | ------------- |
| First Class    | 1                | 2             |
| Second Class   | 2                | ~4            |
| Same Day       | 0                | ~0.5          |
| Standard Class | 4                | ~4            |

The results were consistent with my hypothesis. One finding stood out: Second Class averaged 3.99 actual shipping days, nearly identical to Standard Class at 3.996 days, despite having a scheduled window of 2 days compared with Standard Class's 4 days.

This suggests that the difference in delivery promises helps explain why Second Class has a substantially higher recorded late-delivery rate than Standard Class.

**Follow-up Finding:**
First Class has a scheduled shipping window of 1 day but consistently shows 2 actual shipping days, so I expected every First Class record to be flagged as late. However, the late rate was 95.3% when you'd think it should be 100%. Of the 27,814 First Class records, 26,513 were flagged as late and 1,301 were not.

To find out why, I looked at how real shipping days are distributed within each shipping mode. First Class is always exactly 2 days. Same Day is split between 0 and 1. Second Class and Standard Class are spread almost evenly across 2 to 6 days.

I compared Delivery Status against whether real days exceeded scheduled days. Every record labeled "Late delivery" showed an actual shipping time greater than its scheduled time. Records labeled "Shipping on time" or "Advance shipping" did not. Records labeled "Shipping canceled" showed both outcomes because their canceled status remained unchanged regardless of whether actual shipping days exceeded scheduled days. Late_delivery_risk is a 0/1 version of Delivery Status, so those match on every row.

```sql
-- Check whether Late_delivery_risk and Delivery Status agree
SELECT "Delivery Status",
       "Late_delivery_risk",
       COUNT(*) as total_rows
FROM orders
GROUP BY "Delivery Status",
         "Late_delivery_risk";
-- Result: perfect 1:1 match across all ~180,000 rows
-- Every "Late delivery" status has risk=1; all others have risk=0
-- The fields are consistent, but their relationship's direction is unknown
```

This also explains the earlier discrepancy between the 26,513 First Class records flagged as late and the 1,301 that were not, despite having identical shipping-day counts. The 1,301 "not late" rows all had a Delivery Status of "Shipping canceled." Records labeled "Shipping canceled" are not flagged as late, regardless of their recorded shipping-day counts.

**Conclusion:**
First Class had a recorded late-delivery rate of approximately 95%. All First Class records showed 2 actual shipping days against a scheduled window of 1 day. The rate wasn't 100% because 1,301 records were labeled "Shipping canceled" rather than "Late delivery."

The shipping-time patterns also suggest that parts of the dataset may be artificially generated. First Class consistently shows 2 actual shipping days, while Second Class and Standard Class have unusually uniform distributions between 2 and 6 days. These patterns limit how confidently the results can be applied to real-world shipping performance.

**Dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/sean.barile/viz/SupplyChainShippingModeAnalysis/Sheet1)

## What's next?

- A second question examining product category and profit margins.

## Files

- `analysis.sql` -- All queries used, including data-quality checks, in the order they were run.
- `decisions_log.md` -- Reasoning behind key choices and findings along the way.

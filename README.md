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
       AVG("Late_delivery_risk" * 100) as avg_late_delivery
FROM orders
GROUP BY "Shipping Mode"
ORDER BY avg_late_delivery DESC;
```

**Finding:**
First Class orders were late 95.3% of the time. This is by far the highest of any shipping mode. Second Class followed at 76.6%. Same Day was late 45.7% of the time, and Standard Class had the lowest rate at 38.1%.

![Late delivery rate by shipping mode](images/late_rate_by_shipping_mode.png)

**Interpretation:**
Based on my own operations background, I suspected this was tied to delivery promise windows rather than handling quality. Faster shipping modes are usually held to stricter, tighter delivery windows, making the same real-world delays more likely to register as "late". I tested this by comparing scheduled vs. real shipping days:

| Shipping Mode  | Scheduled (days) | Real (days) |
| -------------- | ---------------- | ----------- |
| First Class    | 1                | 2           |
| Second Class   | 2                | ~4          |
| Same Day       | 0                | ~0.5        |
| Standard Class | 4                | ~4          |

This supported the hypothesis, but also surfaced something more specific: Second Class's actual shipping time (3.99 days) is nearly identical to Standard Class's (3.996 days), despite Second Class promising a much shorter window. Second Class and Standard Class both average about 4 real days, but Second Class promises 2 and Standard promises 4. This is why Second Class is late so much more often.

**Follow-up Finding:**
First Class promises 1 day and always takes 2, so I expected every First Class order to be late. However, the late rate was 95.3% when you'd think it should be 100%. Of the 27,814 First Class orders, 26,513 were late and 1,301 were not.

To find out why, I looked at how real shipping days are distributed within each shipping mode. First Class is always exactly 2 days. Same Day is split between 0 and 1. Second Class and Standard Class are spread almost evenly across 2 to 6 days.

I compared Delivery Status against whether real days exceeded scheduled days. Every "Late delivery" order took longer than scheduled. Every "Shipping on time" and "Advance shipping" order didn't. "Shipping canceled" orders went both ways because they are labeled canceled no matter what the day counts say. Late_delivery_risk is a 0/1 version of Delivery Status, so those match on every row.

```sql
-- Follow-up: checked whether Late_delivery_risk is actually derived from Delivery Status instead of date/day-count fields
SELECT "Delivery Status",
       "Late_delivery_risk",
       COUNT(*) as total_rows
FROM orders
GROUP BY "Delivery Status",
         "Late_delivery_risk";
-- Result: perfect 1:1 match across all ~180,000 rows
-- Every "Late delivery" status row has risk=1, every other status has risk=0
-- Confirms Late_delivery_risk comes from Delivery Status
```

This also explains the earlier 26,513 vs 1,301 discrepancy among First Class orders with identical day counts. The 1,301 "not late" rows all had a Delivery Status of "Shipping canceled." Canceled orders never actually ship, so they are excluded from the late-delivery flag regardless of what the day counts show.

**Conclusion:**
First Class is late about 95% of the time because it promises 1 day and always takes 2. It isn't 100% because 1,301 First Class orders were labeled as canceled orders.

The shipping times do appear to be generated. First Class is exactly 2 days every time, and the other modes spread evenly across 2 to 6 days. These results show how this dataset is built and not how a real company might perform.

**Dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/sean.barile/viz/SupplyChainShippingModeAnalysis/Sheet1)

## What's next?

- A second question examining product category and profit margins.

## Files

- `analysis.sql` -- All queries used, including data-quality checks, in the order they were run.
- `decisions_log.md` -- Reasoning behind key choices and findings along the way.

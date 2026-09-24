# Supply Chain Shipping Analysis

## Overview

An exploratory analysis of the DataCo Smart Supply Chain dataset, using SQL for analysis and Tableau for visualization. This project is in process. One business question fully answered so far, with more planned.

## Background

15 years of experience in fulfillment, inventory, and operations gave me a habit of noticing when numbers don't add up and digging into why. This project applies that instinct to a public retail supply chain dataset, using it to build and demonstrate SQL and Tableau skills.

## Dataset

[DataCo Smart Supply Chain for Big Data Analysis](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis)
~ 180,000 rows covering orders, shipping modes, delivery status, product categories, and customer/order details. Sourced from Kaggle.

## Question 1: Which shipping mode has the highest late-delivery rate?

**Why this question?:**
Shipping mode reliability directly affects customer trust/satisfaction along with operational cost. I wanted to see whether faster, more expensive shipping options actually deliver on their promise.

**Finding:**
First Class orders were late 95.3% of the time. This is by far the highest of any shipping mode. Second Class followed at 76.6%. Same Day was late 45.7% of the time, and Standard Class had the lowest rate at 38.1%.

**Interpretation:**
Based on my own operations background, I suspected this was tied to delivery promise windows rather than handling quality. Faster shipping modes are usually held to stricter, tighter delivery windows, making the same real-world delays more likely to register as "late". I tested this by comparing scheduled vs. real shipping days:

| Shipping Mode  | Scheduled (days) | Real (days) |
| -------------- | ---------------- | ----------- |
| First Class    | 1                | 2           |
| Second Class   | 2                | ~4          |
| Same Day       | 0                | ~0.5        |
| Standard Class | 4                | ~4          |

This supported the hypothesis, but also surfaced something more specific: Second Class's actual shipping time (3.99 days) is nearly identical to Standard Class's (3.996 days), despite Second Class promising a much shorter window. This suggests Second Class orders may not be receiving meaningfully different handling than Standard Class. They are simply held to a faster promise on what looks like the same process.

**Follow-up Finding:**
I decided to dig deeper into the scheduled vs real comparison and found that it doesn't fully explain the late-delivery flag. Among First Class orders with identical values (1 day scheduled, 2 days real), 26,513 are flagged as late while 1,301 with the exact same day counts are not. This means 'Late_delivery_risk' isn't a simple comparison of these two columns. It is likely derived from something more granular, like actual order/shipping dates. I wasn't able to fully determine the exact mechanism with the fields available, but wanted to flag this discrepancy rather than present the day-count comparison as a complete explanation.

**Data Quality Note:**
First Class's "Days for shipping (real)" column showed zero variance. Every order shows exactly 2 days, with no spread. Real operational data almost always has some variation, so it looked like possible synthetic data or rounded field rather than a direct measure.

The follow up finding above supports this. Since, "Late_delivery_risk" has disagreeing rows with identical day-count values (26,513 late vs 1,301 not late, despite matching scheduled/real days), there must be some underlying variation. Likely in the actual order and shipping dates. I wasn't able to confirm this without checking actual date values directly, but the two findings together point in the same direction.

**Dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/sean.barile/viz/SupplyChainShippingModeAnalysis/Sheet1)

## What's next?

- Investigate what actually drives Late_delivery_risk at the date level, since it doesn't align perfectly with day-count comparisons.
- A second question examining product category and profit margins.
- Investigating whether the Second Class/Standard Class similarity holds across other metrics, not just shipping days.

## Files

- `analysis.sql` -- All queries used, including data-quality checks, in the order they were run.
- `decisions_log.txt` -- Reasoning behind key choices and findings along the way.

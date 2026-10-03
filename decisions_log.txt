DECISIONS LOG

Checked order date column for nulls. Found none.

Checked for duplicate Order Ids. Found 45,902 that repeat. Confirmed this is to be expected, not an error. Each row represents one order item, not a full order. So an order with multiple product shows up as multiple rows sharing the same Order Id.

Checked how order date was stored. This came back as text and not a real date type. Decided, for now, this doesn't matter for the first question. Since I'm using the Late_delivery_risk flag instead of calculating days late directly. No date conversion is needed.

Dataset has two possible columns for "was it late". Delivery Status (multiple categories including cancelled orders) and Late_delivery_risk (a flag). The word "risk" made me think that it sounded like it might be a probability, not a fact. Checked the dataset's description file directly instead of guessing. Confirmed it is a clean 0/1 flag: 1 = late, 0 = not late. Chose this column over Delivery Status since it avoids the issue of how to treat cancelled orders.

Ran the shipping-mode late-rate query. The results were surprising. First Class was late 95.3% of the time, the worst of any shipping mode, while Standard Class (the cheapest, slowest option) was late the least at 38.1%. I expected the opposite.

Based on my own operations background (15 years in fulfillment), I suspected this wasn't about handling quality but about delivery promise windows. Faster shipping modes are usually held to a stricter, tighter standard, so the same real-world delay is more likely to appear as "late" for fast shipping mode than a slow one.

Testing this by comparing scheduled vs. real shipping days. Results supported the hypothesis. First Class promises 1 day but takes 2, roughly double. But it also brought about something more specific: Second Class's real shipping time (3.99 days) nearly matches Standard Class's (3.996 days), despite Second Class promising a much shorter window. This suggests that Second Class may not actually be getting different handling than Standard, just a shorter promise on what looks like the same process.

Ran a min/max check on scheduled vs. real days to see if the averages were hiding variation. Found that First Class shows zero variance in real shipping days. Every single order is exactly 2 days with no spread at all. Real operational data almost always has some natural variation (staffing, volume, weather), so I suspect this field may be synthetic or rounded rather than a genuine measurement. Confirmed by browsing individual First Class rows directly. They consistently showed 2, no exceptions.

Noticed something that didn't add up. If First Class always shows scheduled = 1 and real = 2, every First Class order should be late, but the late rate was 95.3% and not 100%. I wanted to know why.

First hypothesis was could null values by hiding the gap? Since MIN/MAX functions ignore nulls silently, I tested directly. I ran a count comparing total rows against non-null counts for both day columns and the late flag, filtering by First Class. I found no gap, ruling out nulls as the explanation.

I ran a grouped query on First Class, combining scheduled days, real days, and the late flag together. Found that identical day-count values (1 scheduled, 2 real) produce two different outcomes. 26,513 rows flagged late, 1,301 rows with the exact same day counts not flagged late. This means Late_delivery_risk isn't a simple comparison of these two columns, but comes from something more granular. Possibly actual order/shipping dates rather than rounded day counts. I wasn't able to fully confirm the exact mechanism with the fields available, but flagged it as an open question rather than presenting the day-count comparison as a complete explanation.

This finding also supports the earlier data-quality suspicion. If the late flag disagrees on rows with identical day-count values, there must be real underlying variation that the day-count columns aren't capturing. This supports the idea that "Days for shipping (real)" may be a rounded field rather than a raw measurement.

Went back to the open question about why First Class wasn't 100% late despite always showing scheduled=1, real=2. Looked at the actual order and shipping date values instead of the day-count columns. I found the shipping date is always exactly the same number of days after order date, down to the same exact time. Checked this against Standard Class too. The same pattern was there, just a different offset. This looks like a fixed formula, not real shipping dates, which supports the zero-variance suspicion from earlier.

Since the dates look synthetic, I wanted to check whether Late_delivery_risk was actually coming from Delivery Status instead. Grouping the full dataset by both columns, I found a perfect match. Every "Late delivery" status row has risk=1, everything else has risk=0, no exceptions. This means the late flag isn't calculated from dates at all. It is directly translated from Delivery Status.

I filtered the original 26,513 vs. 1,301 split from earlier specifically for Delivery Status within that subset. The 1,301 "not late" rows all turned out to be cancelled orders. This makes sense as cancelled orders never actually ship, so they wouldn't be marked as late regardless of what the date fields say. This fully resolves the earlier open question.
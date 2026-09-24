-- =====================================================
-- Supply Chain Analysis
-- Queries run in order, including data-quality checks
-- =====================================================

-- Check for missing order dates
SELECT COUNT(*) - COUNT("order date (DateOrders)")
FROM orders;
-- Result: 0 nulls

-- Check for duplicate Order Ids
-- Confirmed this is expected: each row is an order item, not a full order
SELECT "Order Id", COUNT(*)
FROM orders
GROUP BY "Order Id"
HAVING COUNT(*) > 1;
-- Result: 45,902 Order Ids appear more than once, consistent with multi-item orders

-- Check how order date is stored
SELECT typeof("order date (DateOrders)")
FROM orders
LIMIT 5;
-- Result: text, not a real date type

-- Confirmed Late_delivery_risk is a 0/1 flag, not a probability
-- Verified against the dataset's description file "1 = late, 0 = not late"

-- Main question: late delivery rate shipping mode
SELECT "Shipping Mode",
       AVG("Late_delivery_risk" * 100) as avg_late_delivery
FROM orders
GROUP BY "Shipping Mode"
ORDER BY avg_late_delivery DESC;

-- Follow-up: scheduled vs real shipping days, to test the hypothesis that faster shipping modes are held to tighter delivery windows
SELECT "Shipping Mode",
       AVG("Days for shipment (scheduled)") as avg_scheduled_shipping,
       AVG("Days for shipping (real)") as avg_real_shipping
FROM orders
GROUP BY "Shipping Mode";

-- Follow-up: min/max range check, to see if averages were hiding real variation
SELECT "Shipping Mode",
       MIN("Days for shipment (scheduled)") as min_scheduled_shipping,
       MAX("Days for shipment (scheduled)") as max_scheduled_shipping,
       MIN("Days for shipping (real)") as min_real_shipping,
       MAX("Days for shipping (real)") as max_real_shipping
FROM orders
GROUP BY "Shipping Mode";
-- Result: First Class shows zero variance in real shipping days
-- (min = max = 2), unusual for real operational data
-- Flagged as possible data quality issue

-- Follow-up: null check on First Class specifically, to rule out missing data as the explanation for 95.3% (not 100%) late rate
SELECT COUNT(*) as total_rows,
       COUNT("Days for shipping (real)") as non_null_real,
       COUNT("Days for shipment (scheduled)") as non_null_scheduled,
       COUNT("Late_delivery_risk") as non_null_flag
FROM orders
WHERE "Shipping Mode" = 'First Class';
-- Result: no nulls

-- Follow-up: grouped check to see if Late_delivery_risk aligns with scheduled/real day comparison
SELECT "Days for shipment (scheduled)",
       "Days for shipping (real)",
       "Late_delivery_risk",
       COUNT(*) as row_count
FROM orders
WHERE "Shipping Mode" = 'First Class'
GROUP BY "Days for shipment (scheduled)",
         "Days for shipping (real)",
         "Late_delivery_risk"
ORDER BY row_count DESC;
-- Result: identical scheduled/real values (1, 2) produce two different outcomes
-- 26,513 rows flagged late, 1,301 rows with the same day counts not flagged late
-- Confirms Late_delivery_risk is not a simple comparison of these two columns
-- Test A: Valid update
-- This sets an initial last_sale_date (no previous value or increasing date)
-- Expected: SUCCESS + NOTICE from trigger

UPDATE go_products
SET last_sale_date = DATE '2026-03-01'
WHERE product_number = 109110;

-- Test C: Prepare state before insert
-- Set an older date so the trigger can update it forward
-- Expected: SUCCESS

UPDATE go_products
SET last_sale_date = DATE '2026-03-10'
WHERE product_number = 109110;

-- Test D: Single INSERT
-- Inserts one sale → statement-level trigger fires once
-- Then updates go_products → row-level trigger fires once

INSERT INTO go_daily_sales
(retailer_code, product_number, order_method_code,
 date, quantity, unit_price, unit_sale_price)
VALUES
(1201, 109110, 4, CURRENT_DATE, 5, 100, 90);

-- Test E: Prepare multiple products
-- Set initial dates for multiple products
-- Expected: SUCCESS

UPDATE go_products
SET last_sale_date = DATE '2026-03-10'
WHERE product_number IN (112110, 115110);

-- Test F: Bulk INSERT
-- Inserts multiple rows in one statement
-- Statement-level trigger fires once
-- Row-level trigger fires once per affected product (2 products)

INSERT INTO go_daily_sales
(retailer_code, product_number, order_method_code,
 date, quantity, unit_price, unit_sale_price)
VALUES
(1201, 112110, 4, CURRENT_DATE, 2, 100, 90),
(1201, 115110, 4, CURRENT_DATE, 4, 200, 180),
(1201, 112110, 4, CURRENT_DATE, 1, 100, 95);
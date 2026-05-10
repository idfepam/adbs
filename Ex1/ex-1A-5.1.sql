CREATE MATERIALIZED VIEW monthly_product_sales AS
SELECT
    product_number,
    EXTRACT(YEAR FROM date) AS year,
    EXTRACT(MONTH FROM date) AS month,
    SUM(quantity * unit_sale_price) AS total_revenue
FROM go_daily_sales
GROUP BY product_number, year, month;
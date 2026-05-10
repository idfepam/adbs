WITH ranked_sales AS (
    SELECT
        product_number,
        month,
        total_revenue,
        RANK() OVER (
            PARTITION BY product_number
            ORDER BY total_revenue DESC
        ) AS rank
    FROM monthly_product_sales
    WHERE year = 2018
)
SELECT
    product_number,
    month,
    total_revenue
FROM ranked_sales
WHERE rank = 1;
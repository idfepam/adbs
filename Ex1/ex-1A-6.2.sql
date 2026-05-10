CREATE TEMP TABLE temp_distinct_sales_dates AS
SELECT DISTINCT
    product_number,
    date
FROM go_daily_sales;

WITH RECURSIVE streaks AS (
    SELECT
        product_number,
        date AS start_date,
        date AS current_date,
        1 AS streak_length
    FROM temp_distinct_sales_dates

    UNION ALL

    SELECT
        s.product_number,
        s.start_date,
        d.date AS current_date,
        s.streak_length + 1
    FROM streaks s
    JOIN temp_distinct_sales_dates d
      ON d.product_number = s.product_number
     AND d.date = s.current_date + INTERVAL '1 day'
),
max_streaks AS (
    SELECT
        product_number,
        MAX(streak_length) AS longest_streak
    FROM streaks
    GROUP BY product_number
)
SELECT
    product_number,
    longest_streak
FROM max_streaks
ORDER BY longest_streak DESC, product_number;
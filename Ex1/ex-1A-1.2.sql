CREATE OR REPLACE FUNCTION get_monthly_sales_cursor(
    p_product_id INT, p_year INT)
RETURNS TABLE(month_num INT, total_sales NUMERIC)
AS $$
DECLARE
    i INT;
    db_month INT;
    db_total NUMERIC;

    sales_cursor CURSOR FOR
        SELECT
            EXTRACT(MONTH FROM date)::INT AS month_num,
            SUM(quantity * unit_sale_price) AS total_sales
        FROM go_daily_sales
        WHERE product_number = p_product_id
          AND EXTRACT(YEAR FROM date) = p_year
        GROUP BY EXTRACT(MONTH FROM date)
        ORDER BY EXTRACT(MONTH FROM date);
BEGIN
    OPEN sales_cursor;

    FETCH sales_cursor INTO db_month, db_total;

    FOR i IN 1..12 LOOP
        IF db_month = i THEN
            month_num := i;
            total_sales := COALESCE(db_total, 0);
            RETURN NEXT;

            FETCH sales_cursor INTO db_month, db_total;
        ELSE
            month_num := i;
            total_sales := 0;
            RETURN NEXT;
        END IF;
    END LOOP;

    CLOSE sales_cursor;
END;
$$ LANGUAGE plpgsql;
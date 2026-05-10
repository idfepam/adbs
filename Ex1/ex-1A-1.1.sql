CREATE OR REPLACE FUNCTION get_monthly_sales(p_product_id INT, p_year INT)
RETURNS TABLE(month_num INT, total_sales NUMERIC)
AS $$
DECLARE
    i INT;
    monthly_total NUMERIC;
BEGIN
    FOR i IN 1..12 LOOP
        SELECT COALESCE(SUM(quantity * unit_sale_price), 0)
        INTO monthly_total
        FROM go_daily_sales
        WHERE product_number = p_product_id
          AND EXTRACT(YEAR FROM date) = p_year
          AND EXTRACT(MONTH FROM date) = i;

        month_num := i;
        total_sales := monthly_total;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
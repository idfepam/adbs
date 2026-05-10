CREATE OR REPLACE FUNCTION update_last_sale_date_after_insert()
RETURNS TRIGGER
AS $$
BEGIN
    UPDATE go_products
    SET last_sale_date = CURRENT_DATE
    WHERE product_number IN (
        SELECT DISTINCT product_number
        FROM new_sales
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_sale_date_after_insert
AFTER INSERT ON go_daily_sales
REFERENCING NEW TABLE AS new_sales
FOR EACH STATEMENT
EXECUTE FUNCTION update_last_sale_date_after_insert();
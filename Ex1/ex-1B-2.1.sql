CREATE OR REPLACE FUNCTION validate_last_sale_date()
RETURNS TRIGGER
AS $$
BEGIN
    IF OLD.last_sale_date IS NOT NULL
       AND NEW.last_sale_date < OLD.last_sale_date THEN
        RAISE EXCEPTION
            'last_sale_date cannot move backwards: old=%, new=%',
            OLD.last_sale_date, NEW.last_sale_date;
    END IF;

    RAISE NOTICE
        'last_sale_date updated successfully for product %: % -> %',
        NEW.product_number, OLD.last_sale_date, NEW.last_sale_date;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_last_sale_date
BEFORE UPDATE OF last_sale_date ON go_products
FOR EACH ROW
EXECUTE FUNCTION validate_last_sale_date();
-- Recalculates order total when line items change
CREATE OR REPLACE FUNCTION sales.trg_update_order_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id BIGINT;
BEGIN
    -- Determine which order_id to update
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;

    -- Call the function to calculate the new total and update the order record
    UPDATE sales.order
    SET total_amount = sales.calculate_order_total(v_order_id)
    WHERE order_id = v_order_id;
    
    RETURN NULL; -- Signal to PostgreSQL that this is a trigger
END;
$$;

-- Trigger Attach the function to the order_item table
CREATE TRIGGER trg_order_item_changes
AFTER INSERT OR UPDATE OR DELETE ON sales.order_item
FOR EACH ROW
EXECUTE FUNCTION sales.trg_update_order_total();

-- Checks for an existing review by the same customer for the same product
CREATE OR REPLACE FUNCTION catalog.trg_prevent_duplicate_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if a review already exists for this customer and product
    IF EXISTS (
        SELECT 1 
        FROM catalog.review 
        WHERE customer_id = NEW.customer_id 
          AND product_id = NEW.product_id
    ) THEN
        RAISE EXCEPTION 'Customer % has already submitted a review for Product %.', NEW.customer_id, NEW.product_id
        USING HINT = 'Only one review per customer per product is allowed.';
    END IF;

    RETURN NEW;
END;
$$;

-- Attach the function to the review table
CREATE TRIGGER trg_check_duplicate_review
BEFORE INSERT OR UPDATE OF customer_id, product_id ON catalog.review
FOR EACH ROW
EXECUTE FUNCTION catalog.trg_prevent_duplicate_review();
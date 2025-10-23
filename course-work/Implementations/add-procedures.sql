-- Places a new order and records the payment in a single transaction
CREATE OR REPLACE PROCEDURE sales.place_new_order(
    p_customer_id BIGINT,
    p_shipping_address VARCHAR,
    p_payment_method VARCHAR,
    p_items JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id BIGINT;
    v_total_amount NUMERIC(10, 2) := 0;
    v_item RECORD;
BEGIN
    -- 1. Create the new order record
    INSERT INTO sales.order (customer_id, shipping_address, status, total_amount)
    VALUES (p_customer_id, p_shipping_address, 'Processing', 0.00)
    RETURNING order_id INTO v_order_id;

    -- 2. Insert order items and calculate total amount
    FOR v_item IN
        SELECT (item->>'product_id')::BIGINT AS product_id,
               (item->>'quantity')::INTEGER AS quantity,
               (item->>'price_at_purchase')::NUMERIC(10, 2) AS price_at_purchase
        FROM jsonb_array_elements(p_items) AS item
    LOOP
        INSERT INTO sales.order_item (order_id, product_id, quantity, price_at_purchase)
        VALUES (v_order_id, v_item.product_id, v_item.quantity, v_item.price_at_purchase);
        
        v_total_amount := v_total_amount + (v_item.quantity * v_item.price_at_purchase);
    END LOOP;

    -- 3. Update the total_amount on the order record
    UPDATE sales.order SET total_amount = v_total_amount WHERE order_id = v_order_id;

    -- 4. Create the initial payment record (simplified, assuming instant success)
    INSERT INTO sales.payment (order_id, payment_date, payment_method, amount, status)
    VALUES (v_order_id, NOW(), p_payment_method, v_total_amount, 'Processing');

END;
$$;

-- Update product stock based on a change in order fulfillment status
CREATE OR REPLACE PROCEDURE catalog.update_product_stock(
    p_product_id BIGINT,
    p_quantity_change INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE catalog.product
    SET stock = stock - p_quantity_change
    WHERE product_id = p_product_id;
END;
$$;
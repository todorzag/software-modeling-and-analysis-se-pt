-- Calculate Order Total Amount
CREATE OR REPLACE FUNCTION sales.calculate_order_total(p_order_id BIGINT)
RETURNS NUMERIC(10, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_amount NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(oi.quantity * oi.price_at_purchase), 0)
    INTO v_total_amount
    FROM sales.order_item oi
    WHERE oi.order_id = p_order_id;

    RETURN v_total_amount;
END;
$$;

-- Get Seller's Average Product Rating
CREATE OR REPLACE FUNCTION catalog.get_seller_avg_rating(p_seller_id BIGINT)
RETURNS NUMERIC(3, 2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_avg_rating NUMERIC(3, 2);
BEGIN
    SELECT AVG(r.rating)
    INTO v_avg_rating
    FROM catalog.review r
    JOIN catalog.product p ON r.product_id = p.product_id
    WHERE p.seller_id = p_seller_id;

    RETURN COALESCE(v_avg_rating, 0.00);
END;
$$;
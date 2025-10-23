-- 1. CATALOG SCHEMA DATA
-- 1.1 CATEGORY Table
INSERT INTO catalog.category (name, description) VALUES
('Electronics', 'Devices for personal and home use.'),
('Books', 'Fiction and non-fiction titles.'),
('Apparel', 'Clothing, shoes, and accessories.');

-- 1.2 SELLER Table
INSERT INTO catalog.seller (name, email, phone, rating, commission_rate) VALUES
('TechGlobal Inc.', 'sales@techglobal.com', '555-0101', 4.75, 0.1200),
('BookWorm Central', 'contact@bookworm.net', '555-0102', 4.90, 0.0800),
('StyleZone Fashion', 'support@stylezone.com', '555-0103', 4.50, 0.1500);

-- 1.3 CUSTOMER Table
INSERT INTO catalog.customer (name, email, phone, address, registration_date) VALUES
('Alice Smith', 'alice.smith@example.com', '555-1001', '123 Oak St, Anytown', '2024-01-15 10:00:00+02'),
('Bob Johnson', 'bob.j@example.com', '555-1002', '456 Pine Ave, Otherville', '2024-03-20 15:30:00+02'),
('Charlie Brown', 'charlie.b@example.com', '555-1003', '789 Maple Rd, Metropolis', '2025-05-10 11:00:00+03');

-- 1.4 PRODUCT Table
INSERT INTO catalog.product (seller_id, category_id, name, stock, price, description) VALUES
((SELECT seller_id FROM catalog.seller WHERE name = 'TechGlobal Inc.'), (SELECT category_id FROM catalog.category WHERE name = 'Electronics'), 'Wireless Noise-Cancelling Headphones', 50, 99.99, 'Premium sound quality with active noise cancellation.'),
((SELECT seller_id FROM catalog.seller WHERE name = 'BookWorm Central'), (SELECT category_id FROM catalog.category WHERE name = 'Books'), 'The PostgreSQL Handbook', 120, 39.50, 'A comprehensive guide to database management.'),
((SELECT seller_id FROM catalog.seller WHERE name = 'StyleZone Fashion'), (SELECT category_id FROM catalog.category WHERE name = 'Apparel'), 'Casual Cotton T-Shirt', 200, 19.99, '100% organic cotton, various colors.'),
((SELECT seller_id FROM catalog.seller WHERE name = 'BookWorm Central'), (SELECT category_id FROM catalog.category WHERE name = 'Books'), 'Sci-Fi Novel: Galactic Dawn', 75, 15.00, 'Best-selling space opera.');

-- 1.5 REVIEW Table
INSERT INTO catalog.review (customer_id, product_id, comment, rating, review_date) VALUES
((SELECT customer_id FROM catalog.customer WHERE name = 'Alice Smith'), 
 (SELECT product_id FROM catalog.product WHERE name = 'Wireless Noise-Cancelling Headphones'), 
 'Excellent headphones for the price!', 5, '2025-10-22 15:00:00+03');

INSERT INTO catalog.review (customer_id, product_id, comment, rating, review_date) VALUES
((SELECT customer_id FROM catalog.customer WHERE name = 'Bob Johnson'), 
 (SELECT product_id FROM catalog.product WHERE name = 'The PostgreSQL Handbook'), 
 'Very detailed but a bit dry.', 4, '2025-10-20 10:00:00+03');

INSERT INTO catalog.review (customer_id, product_id, comment, rating, review_date) VALUES
((SELECT customer_id FROM catalog.customer WHERE name = 'Alice Smith'), 
 (SELECT product_id FROM catalog.product WHERE name = 'Casual Cotton T-Shirt'), 
 'Soft and fits true to size.', 5, '2025-10-23 10:00:00+03');

-- 2. SALES SCHEMA DATA
-- Get customer IDs
DO $$
DECLARE
    alice_id BIGINT := (SELECT customer_id FROM catalog.customer WHERE name = 'Alice Smith');
    bob_id BIGINT := (SELECT customer_id FROM catalog.customer WHERE name = 'Bob Johnson');
    
    headphone_id BIGINT := (SELECT product_id FROM catalog.product WHERE name = 'Wireless Noise-Cancelling Headphones');
    sql_book_id BIGINT := (SELECT product_id FROM catalog.product WHERE name = 'The PostgreSQL Handbook');
    scifi_book_id BIGINT := (SELECT product_id FROM catalog.product WHERE name = 'Sci-Fi Novel: Galactic Dawn');
BEGIN

    CALL sales.place_new_order(
        p_customer_id => alice_id,
        p_shipping_address => '123 Oak St, Anytown',
        p_payment_method => 'VISA',
        p_items => jsonb_build_array(
            jsonb_build_object('product_id', headphone_id, 'quantity', 1, 'price_at_purchase', 99.99),
            jsonb_build_object('product_id', sql_book_id, 'quantity', 1, 'price_at_purchase', 39.50)
        )
    );

    -- 2.2 Order 2: Bob buys 3 Sci-Fi Books
    CALL sales.place_new_order(
        p_customer_id => bob_id,
        p_shipping_address => '456 Pine Ave, Otherville',
        p_payment_method => 'MasterCard',
        p_items => jsonb_build_array(
            jsonb_build_object('product_id', scifi_book_id, 'quantity', 3, 'price_at_purchase', 15.00)
        )
    );

END $$;

-- 2.3 PAYMENT adjustments
UPDATE sales.payment
SET transaction_fee = amount * 0.02
WHERE payment_method = 'VISA';

UPDATE sales.payment
SET transaction_fee = amount * 0.015
WHERE payment_method = 'MasterCard';


-- 3. TRIGGER TEST
-- 3.1 Insert a new item to Order 2
INSERT INTO sales.order_item (order_id, product_id, quantity, price_at_purchase)
VALUES (
    (SELECT order_id FROM sales.order WHERE customer_id = (SELECT customer_id FROM catalog.customer WHERE name = 'Bob Johnson')), 
    (SELECT product_id FROM catalog.product WHERE name = 'Casual Cotton T-Shirt'), 
    2, 
    19.99
);
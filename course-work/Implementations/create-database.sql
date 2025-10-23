-- DATABASE AND SCHEMA SETUP

CREATE DATABASE amazon_ecommerce_db;

-- Run the subsequent commands after connecting to the new database.

CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS catalog;

-- CATALOG SCHEMA TABLES

CREATE TABLE catalog.category (
    category_id     SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,
    description     VARCHAR(255)
);

CREATE TABLE catalog.seller (
    seller_id       BIGSERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE,
    phone           VARCHAR(20),
    rating          NUMERIC(3, 2),
    commission_rate NUMERIC(5, 4)
);

CREATE TABLE catalog.product (
    product_id      BIGSERIAL PRIMARY KEY,
    seller_id       BIGINT NOT NULL REFERENCES catalog.seller(seller_id),
    category_id     INTEGER NOT NULL REFERENCES catalog.category(category_id),
    name            VARCHAR(200) NOT NULL,
    stock           INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    price           NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    description     TEXT
);

CREATE TABLE catalog.customer (
    customer_id         BIGSERIAL PRIMARY KEY,
    phone               VARCHAR(20),
    name                VARCHAR(100) NOT NULL,
    email               VARCHAR(150) UNIQUE NOT NULL,
    address             VARCHAR(255),
    registration_date   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE catalog.review (
    review_id       BIGSERIAL PRIMARY KEY,
    customer_id     BIGINT NOT NULL REFERENCES catalog.customer(customer_id),
    product_id      BIGINT NOT NULL REFERENCES catalog.product(product_id),
    comment         TEXT,
    rating          NUMERIC(3,2) NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_date     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

--SALES SCHEMA TABLES

CREATE TABLE sales.order (
    order_id            BIGSERIAL PRIMARY KEY,
    customer_id         BIGINT NOT NULL REFERENCES catalog.customer(customer_id),
    order_date          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    shipping_address    VARCHAR(255),
    status              VARCHAR(30) NOT NULL,
    total_amount        NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    is_gift             BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE sales.payment (
    payment_id          BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL UNIQUE REFERENCES sales.order(order_id),
    payment_date        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    payment_method      VARCHAR(50) NOT NULL,
    amount              NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    status              VARCHAR(30) NOT NULL,
    transaction_fee     NUMERIC(6, 2) DEFAULT 0
);

CREATE TABLE sales.order_item (
    order_id            BIGINT NOT NULL REFERENCES sales.order(order_id),
    product_id          BIGINT NOT NULL REFERENCES catalog.product(product_id),
    
    quantity            INTEGER NOT NULL CHECK (quantity > 0),
    price_at_purchase   NUMERIC(10, 2) NOT NULL CHECK (price_at_purchase >= 0),
    
    PRIMARY KEY (order_id, product_id)
);
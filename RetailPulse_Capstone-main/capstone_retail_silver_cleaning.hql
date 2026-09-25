CREATE DATABASE IF NOT EXISTS silver;

CREATE EXTERNAL TABLE IF NOT EXISTS silver.customers (
    customer_id INT,
    full_name STRING,
    email STRING,
    phone STRING,
    country_code STRING,
    signup_at TIMESTAMP,
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/customers';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.orders (
    order_id BIGINT,
    customer_id INT,
    store_id INT,
    order_status STRING,
    order_timestamp TIMESTAMP,
    order_total DECIMAL(12,2),
    discount_amount DECIMAL(12,2),
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/orders';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.order_items (
    order_item_id BIGINT,
    order_id BIGINT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    line_discount DECIMAL(12,2),
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/order_items';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.payments (
    payment_id BIGINT,
    order_id BIGINT,
    payment_method STRING,
    payment_status STRING,
    amount DECIMAL(12,2),
    paid_at TIMESTAMP,
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/payments';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.inventory_snapshots (
    inventory_snapshot_id BIGINT,
    product_id INT,
    store_id INT,
    stock_on_hand INT,
    snapshot_at TIMESTAMP,
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/inventory_snapshots';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.stores (
    store_id INT,
    store_name STRING,
    city STRING,
    country_code STRING,
    opened_at DATE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/stores';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.fulfillment_events (
    fulfillment_event_id BIGINT,
    order_id BIGINT,
    event_type STRING,
    event_timestamp TIMESTAMP,
    warehouse_code STRING,
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/fulfillment_events';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.products (
    product_id INT,
    sku STRING,
    product_name STRING,
    category STRING,
    unit_cost DECIMAL(12,2),
    list_price DECIMAL(12,2),
    updated_at TIMESTAMP
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/silver/products';

INSERT OVERWRITE TABLE silver.customers
SELECT
    customer_id,
    full_name,
    CASE
        WHEN email IS NULL OR LOWER(TRIM(email)) = 'null' OR TRIM(email) = '' THEN 'unknown'
        ELSE TRIM(email)
    END AS email,
    phone,
    CASE LOWER(TRIM(country_code))
        WHEN 'egypt' THEN 'EG'
        WHEN 'egy' THEN 'EG'
        WHEN 'eg' THEN 'EG'
        WHEN 'jordan' THEN 'JO'
        WHEN 'jo' THEN 'JO'
        WHEN 'uae' THEN 'AE'
        WHEN 'ae' THEN 'AE'
        WHEN 'ksa' THEN 'SA'
        WHEN 'sa' THEN 'SA'
        ELSE UPPER(TRIM(country_code))
    END AS country_code,
    signup_at,
    updated_at
FROM bronze.customers;

INSERT OVERWRITE TABLE silver.orders
SELECT
    order_id,
    customer_id,
    store_id,
    LOWER(TRIM(order_status)) AS order_status,
    order_timestamp,
    order_total,
    discount_amount,
    updated_at
FROM bronze.orders;

INSERT OVERWRITE TABLE silver.order_items
SELECT
    order_item_id,
    order_id,
    product_id,
    ABS(quantity) AS quantity,
    unit_price,
    line_discount,
    updated_at
FROM bronze.order_items;

INSERT OVERWRITE TABLE silver.payments
SELECT
    payment_id,
    order_id,
    LOWER(TRIM(payment_method)) AS payment_method,
    LOWER(TRIM(payment_status)) AS payment_status,
    amount,
    paid_at,
    updated_at
FROM bronze.payments;

INSERT OVERWRITE TABLE silver.inventory_snapshots
SELECT
    inventory_snapshot_id,
    product_id,
    store_id,
    stock_on_hand,
    snapshot_at,
    updated_at
FROM bronze.inventory_snapshots;

INSERT OVERWRITE TABLE silver.stores
SELECT
    store_id,
    store_name,
    city,
    country_code,
    opened_at
FROM bronze.stores;

INSERT OVERWRITE TABLE silver.fulfillment_events
SELECT
    fulfillment_event_id,
    order_id,
    event_type,
    event_timestamp,
    warehouse_code,
    updated_at
FROM bronze.fulfillment_events;

INSERT OVERWRITE TABLE silver.products
SELECT
    product_id,
    sku,
    product_name,
    category,
    unit_cost,
    list_price,
    updated_at
FROM bronze.products;
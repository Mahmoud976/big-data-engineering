CREATE DATABASE IF NOT EXISTS bronze;
USE bronze;

CREATE EXTERNAL TABLE IF NOT EXISTS customers (
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
LOCATION '/user/hadoop/bronze/customers';

CREATE EXTERNAL TABLE IF NOT EXISTS fulfillment_events (
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
LOCATION '/user/hadoop/bronze/fulfillment_events';

CREATE EXTERNAL TABLE IF NOT EXISTS inventory_snapshots (
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
LOCATION '/user/hadoop/bronze/inventory_snapshots';

CREATE EXTERNAL TABLE IF NOT EXISTS order_items (
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
LOCATION '/user/hadoop/bronze/order_items';

CREATE EXTERNAL TABLE IF NOT EXISTS orders (
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
LOCATION '/user/hadoop/bronze/orders';

CREATE EXTERNAL TABLE IF NOT EXISTS payments (
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
LOCATION '/user/hadoop/bronze/payments';

CREATE EXTERNAL TABLE IF NOT EXISTS products (
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
LOCATION '/user/hadoop/bronze/products';

CREATE EXTERNAL TABLE IF NOT EXISTS stores (
    store_id INT,
    store_name STRING,
    city STRING,
    country_code STRING,
    opened_at DATE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/bronze/stores';
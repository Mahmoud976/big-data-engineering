CREATE DATABASE IF NOT EXISTS gold;

CREATE EXTERNAL TABLE IF NOT EXISTS gold.dim_customer (
    customer_key BIGINT,
    customer_id INT,
    full_name STRING,
    email STRING,
    phone STRING,
    country_code STRING,
    signup_date_key INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/dim_customer';

CREATE EXTERNAL TABLE IF NOT EXISTS gold.dim_product (
    product_key BIGINT,
    product_id INT,
    sku STRING,
    product_name STRING,
    category STRING,
    unit_cost DECIMAL(12,2),
    list_price DECIMAL(12,2)
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/dim_product';

CREATE EXTERNAL TABLE IF NOT EXISTS gold.dim_store (
    store_key BIGINT,
    store_id INT,
    store_name STRING,
    country_code STRING,
    opened_date_key INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/dim_store';

CREATE EXTERNAL TABLE IF NOT EXISTS gold.fact_order_items (
    order_item_key BIGINT,
    order_id BIGINT,
    customer_key BIGINT,
    product_key BIGINT,
    store_key BIGINT,
    order_date_key INT,
    quantity INT,
    unit_price DECIMAL(12,2),
    line_discount DECIMAL(12,2),
    gross_amount DECIMAL(14,2),
    net_amount DECIMAL(14,2)
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/fact_order_items';

CREATE EXTERNAL TABLE IF NOT EXISTS gold.dim_date (
    date_key INT,
    full_date DATE,
    day INT,
    day_name STRING,
    week INT,
    month INT,
    month_name STRING,
    quarter INT,
    year INT,
    is_weekend BOOLEAN
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/dim_date';
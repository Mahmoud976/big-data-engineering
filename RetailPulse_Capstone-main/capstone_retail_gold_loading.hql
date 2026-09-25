USE gold;

INSERT OVERWRITE TABLE gold.dim_customer
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    customer_id,
    full_name,
    email,
    phone,
    country_code,
    CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(signup_at AS STRING), 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') AS INT) AS signup_date_key
FROM silver.customers;

INSERT OVERWRITE TABLE gold.dim_product
SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key,
    product_id,
    sku,
    product_name,
    category,
    unit_cost,
    list_price
FROM silver.products;

INSERT OVERWRITE TABLE gold.dim_store
SELECT
    ROW_NUMBER() OVER (ORDER BY store_id) AS store_key,
    store_id,
    store_name,
    country_code,
    CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(opened_at AS STRING), 'yyyy-MM-dd'), 'yyyyMMdd') AS INT) AS opened_date_key
FROM silver.stores;

INSERT OVERWRITE TABLE gold.dim_date
SELECT DISTINCT
    CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(date_value, 'yyyy-MM-dd'), 'yyyyMMdd') AS INT) AS date_key,
    CAST(date_value AS DATE) AS full_date,
    CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(date_value, 'yyyy-MM-dd'), 'dd') AS INT) AS day,
    FROM_UNIXTIME(UNIX_TIMESTAMP(date_value, 'yyyy-MM-dd'), 'EEEE') AS day_name,
    WEEKOFYEAR(CAST(date_value AS DATE)) AS week,
    MONTH(CAST(date_value AS DATE)) AS month,
    FROM_UNIXTIME(UNIX_TIMESTAMP(date_value, 'yyyy-MM-dd'), 'MMMM') AS month_name,
    QUARTER(CAST(date_value AS DATE)) AS quarter,
    YEAR(CAST(date_value AS DATE)) AS year,
    CASE WHEN DAYOFWEEK(CAST(date_value AS DATE)) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM (
    SELECT DATE_FORMAT(order_timestamp, 'yyyy-MM-dd') AS date_value FROM silver.orders
    UNION ALL
    SELECT DATE_FORMAT(signup_at, 'yyyy-MM-dd') AS date_value FROM silver.customers
    UNION ALL
    SELECT CAST(opened_at AS STRING) AS date_value FROM silver.stores
) dates;

INSERT OVERWRITE TABLE gold.fact_order_items
SELECT
    ROW_NUMBER() OVER (ORDER BY oi.order_item_id) AS order_item_key,
    oi.order_id,
    dc.customer_key,
    dp.product_key,
    ds.store_key,
    CAST(FROM_UNIXTIME(UNIX_TIMESTAMP(CAST(o.order_timestamp AS STRING), 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') AS INT) AS order_date_key,
    oi.quantity,
    oi.unit_price,
    COALESCE(oi.line_discount, CAST(0 AS DECIMAL(12,2))) AS line_discount,
    CAST(oi.quantity * oi.unit_price AS DECIMAL(14,2)) AS gross_amount,
    CAST((oi.quantity * oi.unit_price) - COALESCE(oi.line_discount, CAST(0 AS DECIMAL(12,2))) AS DECIMAL(14,2)) AS net_amount
FROM silver.order_items oi
JOIN silver.orders o ON oi.order_id = o.order_id
LEFT JOIN gold.dim_customer dc ON o.customer_id = dc.customer_id
LEFT JOIN gold.dim_product dp ON oi.product_id = dp.product_id
LEFT JOIN gold.dim_store ds ON o.store_id = ds.store_id;
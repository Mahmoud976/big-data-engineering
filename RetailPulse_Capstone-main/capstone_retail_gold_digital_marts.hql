CREATE DATABASE IF NOT EXISTS gold;

DROP TABLE IF EXISTS gold.fact_digital_session;

CREATE EXTERNAL TABLE gold.fact_digital_session (
    session_id STRING,
    customer_id INT,
    store_id INT,
    channel STRING,
    session_start_ts STRING,
    session_end_ts STRING,
    first_view_ts STRING,
    first_cart_ts STRING,
    first_checkout_ts STRING,
    order_confirmed_ts STRING,
    order_id INT,
    event_count BIGINT,
    `has_late_event` INT,
    `has_view` BOOLEAN,
    `has_cart` BOOLEAN,
    `has_checkout` BOOLEAN,
    `has_order` BOOLEAN,
    date_key INT,
        loaded_at STRING
)
PARTITIONED BY (session_date STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/fact_digital_session';

MSCK REPAIR TABLE gold.fact_digital_session;

DROP TABLE IF EXISTS gold.mart_digital_funnel_daily;

CREATE EXTERNAL TABLE gold.mart_digital_funnel_daily (
    date_key INT,
    channel STRING,
    store_id INT,
    sessions BIGINT,
    sessions_viewed BIGINT,
    sessions_carted BIGINT,
    sessions_checkout BIGINT,
    sessions_ordered BIGINT,
    view_to_cart_rate DOUBLE,
    cart_to_checkout_rate DOUBLE,
    checkout_to_order_rate DOUBLE,
    overall_conversion_rate DOUBLE,
        loaded_at STRING
)
PARTITIONED BY (session_date STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/mart_digital_funnel_daily';

MSCK REPAIR TABLE gold.mart_digital_funnel_daily;

DROP TABLE IF EXISTS gold.mart_data_quality_summary;

CREATE EXTERNAL TABLE gold.mart_data_quality_summary (
    run_id STRING,
    run_ts STRING,
    source_table STRING,
    outcome STRING,
    row_count BIGINT,
    total_source_rows INT,
    pct_of_total DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/hadoop/gold/mart_data_quality_summary';
-- ============================================================
-- GoAsia Dataset — Snowflake Setup SQL
-- ============================================================
-- Run this script in Snowsight or SnowSQL to create the GoAsia
-- database, schemas, stages, tables, and load data.
-- Pattern follows Meridian Bank reference setup.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- 1. DATABASE & SCHEMAS
CREATE DATABASE IF NOT EXISTS GOASIA;

CREATE SCHEMA IF NOT EXISTS GOASIA.SHARED;
CREATE SCHEMA IF NOT EXISTS GOASIA.RIDES;
CREATE SCHEMA IF NOT EXISTS GOASIA.LOGISTICS;
CREATE SCHEMA IF NOT EXISTS GOASIA.DOCUMENTS;
CREATE SCHEMA IF NOT EXISTS GOASIA.SEARCH_SERVICES;
CREATE SCHEMA IF NOT EXISTS GOASIA.SEMANTIC_VIEWS;
CREATE SCHEMA IF NOT EXISTS GOASIA.AGENTS;

-- 2. INTERNAL STAGE (single shared stage, organized by subdirectory)
CREATE OR REPLACE STAGE GOASIA.SHARED.DATA_STAGE
    FILE_FORMAT = (TYPE = PARQUET)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Upload Parquet files from local terminal (run these snow CLI commands before executing COPY INTO):

-- Shared dimensions (3 files)
-- snow stage copy data/structured/shared/dim_country.parquet @GOASIA.SHARED.DATA_STAGE/shared/
-- snow stage copy data/structured/shared/dim_city.parquet @GOASIA.SHARED.DATA_STAGE/shared/
-- snow stage copy data/structured/shared/dim_zone.parquet @GOASIA.SHARED.DATA_STAGE/shared/

-- Rides domain (9 files)
-- snow stage copy data/structured/rides/dim_driver.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/dim_rider.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/dim_vehicle.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/fact_trip.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/fact_trip_event.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/fact_surge_pricing.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/fact_driver_earning.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/fact_rider_payment.parquet @GOASIA.SHARED.DATA_STAGE/rides/
-- snow stage copy data/structured/rides/fact_promo_usage.parquet @GOASIA.SHARED.DATA_STAGE/rides/

-- Logistics domain (10 files)
-- snow stage copy data/structured/logistics/dim_shipper.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/dim_courier.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/dim_warehouse.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/dim_parcel_type.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/fact_shipment.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/fact_parcel_event.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/fact_route_leg.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/fact_sla_breach.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/fact_courier_earning.parquet @GOASIA.SHARED.DATA_STAGE/logistics/
-- snow stage copy data/structured/logistics/fact_shipper_invoice.parquet @GOASIA.SHARED.DATA_STAGE/logistics/

-- ============================================================
-- 3. SHARED DIMENSION TABLES
-- ============================================================

CREATE OR REPLACE TABLE GOASIA.SHARED.DIM_COUNTRY (
    country_cd     VARCHAR(5),
    country_name   VARCHAR(50),
    region         VARCHAR(30),
    currency       VARCHAR(5),
    timezone       VARCHAR(40)
);

CREATE OR REPLACE TABLE GOASIA.SHARED.DIM_CITY (
    city_id        VARCHAR(20),
    city_name      VARCHAR(60),
    country_cd     VARCHAR(5),
    population     INT,
    tier           VARCHAR(5),
    launch_date    DATE
);

CREATE OR REPLACE TABLE GOASIA.SHARED.DIM_ZONE (
    zone_id        VARCHAR(20),
    zone_name      VARCHAR(80),
    city_id        VARCHAR(20),
    zone_type      VARCHAR(20),
    lat            FLOAT,
    lng            FLOAT,
    area_km2       FLOAT
);

-- ============================================================
-- 4. RIDES DOMAIN TABLES
-- ============================================================

CREATE OR REPLACE TABLE GOASIA.RIDES.DIM_DRIVER (
    driver_id      VARCHAR(20),
    driver_name    VARCHAR(80),
    city_id        VARCHAR(20),
    vehicle_type   VARCHAR(15),
    rating         FLOAT,
    signup_date    DATE,
    status         VARCHAR(15),
    tier           VARCHAR(10),
    total_trips    INT,
    is_active      BOOLEAN
);

CREATE OR REPLACE TABLE GOASIA.RIDES.DIM_RIDER (
    rider_id       VARCHAR(20),
    rider_name     VARCHAR(80),
    city_id        VARCHAR(20),
    signup_date    DATE,
    tier           VARCHAR(10),
    lifetime_rides INT,
    lifetime_spend FLOAT,
    is_active      BOOLEAN
);

CREATE OR REPLACE TABLE GOASIA.RIDES.DIM_VEHICLE (
    vehicle_id     VARCHAR(20),
    driver_id      VARCHAR(20),
    make           VARCHAR(30),
    model          VARCHAR(30),
    year           INT,
    vehicle_type   VARCHAR(15),
    plate_number   VARCHAR(20),
    fuel_type      VARCHAR(10)
);

CREATE OR REPLACE TABLE GOASIA.RIDES.FACT_TRIP (
    trip_id            VARCHAR(20),
    rider_id           VARCHAR(20),
    driver_id          VARCHAR(20),
    vehicle_id         VARCHAR(20),
    zone_pickup        VARCHAR(20),
    zone_dropoff       VARCHAR(20),
    request_ts         TIMESTAMP_NTZ,
    pickup_ts          TIMESTAMP_NTZ,
    dropoff_ts         TIMESTAMP_NTZ,
    distance_km        FLOAT,
    duration_min       FLOAT,
    fare               FLOAT,
    surge_multiplier   FLOAT,
    tip                FLOAT,
    payment_method     VARCHAR(15),
    status             VARCHAR(20),
    is_completed       BOOLEAN,
    total_fare_amount  FLOAT,
    rating_driver      FLOAT,
    rating_rider       FLOAT
);

CREATE OR REPLACE TABLE GOASIA.RIDES.FACT_TRIP_EVENT (
    event_id       VARCHAR(20),
    trip_id        VARCHAR(20),
    event_type     VARCHAR(20),
    event_ts       TIMESTAMP_NTZ,
    description    VARCHAR(200)
);

CREATE OR REPLACE TABLE GOASIA.RIDES.FACT_SURGE_PRICING (
    surge_id       VARCHAR(20),
    zone_id        VARCHAR(20),
    surge_start    TIMESTAMP_NTZ,
    surge_end      TIMESTAMP_NTZ,
    multiplier     FLOAT,
    demand_count   INT,
    supply_count   INT,
    reason         VARCHAR(20)
);

CREATE OR REPLACE TABLE GOASIA.RIDES.FACT_DRIVER_EARNING (
    earning_id        VARCHAR(20),
    driver_id         VARCHAR(20),
    date              DATE,
    trips_completed   INT,
    gross_earning     FLOAT,
    commission        FLOAT,
    bonus             FLOAT,
    incentive         FLOAT,
    net_earning       FLOAT
);

CREATE OR REPLACE TABLE GOASIA.RIDES.FACT_RIDER_PAYMENT (
    payment_id      VARCHAR(20),
    rider_id        VARCHAR(20),
    trip_id         VARCHAR(20),
    amount          FLOAT,
    payment_method  VARCHAR(15),
    promo_discount  FLOAT,
    final_amount    FLOAT,
    status          VARCHAR(15)
);

CREATE OR REPLACE TABLE GOASIA.RIDES.FACT_PROMO_USAGE (
    promo_id       VARCHAR(20),
    rider_id       VARCHAR(20),
    campaign_name  VARCHAR(30),
    discount_type  VARCHAR(15),
    discount_value FLOAT,
    trip_id        VARCHAR(20),
    redeemed_date  DATE
);

-- ============================================================
-- 5. LOGISTICS DOMAIN TABLES
-- ============================================================

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.DIM_SHIPPER (
    shipper_id     VARCHAR(20),
    company_name   VARCHAR(100),
    industry       VARCHAR(30),
    city_id        VARCHAR(20),
    tier           VARCHAR(15),
    monthly_volume INT,
    contract_type  VARCHAR(15),
    signup_date    DATE,
    is_active      BOOLEAN
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.DIM_COURIER (
    courier_id     VARCHAR(20),
    courier_name   VARCHAR(80),
    city_id        VARCHAR(20),
    vehicle_type   VARCHAR(15),
    capacity_kg    FLOAT,
    rating         FLOAT,
    status         VARCHAR(15),
    signup_date    DATE,
    is_active      BOOLEAN
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.DIM_WAREHOUSE (
    warehouse_id     VARCHAR(20),
    warehouse_name   VARCHAR(80),
    city_id          VARCHAR(20),
    zone_id          VARCHAR(20),
    capacity_parcels INT,
    type             VARCHAR(20),
    is_cold_chain    BOOLEAN
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.DIM_PARCEL_TYPE (
    parcel_type_id   VARCHAR(20),
    type_name        VARCHAR(30),
    max_weight_kg    FLOAT,
    sla_hours        INT,
    base_rate        FLOAT
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.FACT_SHIPMENT (
    shipment_id          VARCHAR(20),
    shipper_id           VARCHAR(20),
    courier_id           VARCHAR(20),
    parcel_type_id       VARCHAR(20),
    origin_zone          VARCHAR(20),
    dest_zone            VARCHAR(20),
    origin_warehouse     VARCHAR(20),
    dest_warehouse       VARCHAR(20),
    created_ts           TIMESTAMP_NTZ,
    picked_up_ts         TIMESTAMP_NTZ,
    delivered_ts         TIMESTAMP_NTZ,
    weight_kg            FLOAT,
    declared_value       FLOAT,
    shipping_fee         FLOAT,
    status               VARCHAR(20),
    is_delivered         BOOLEAN,
    sla_met              BOOLEAN,
    delivery_attempt_count INT
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.FACT_PARCEL_EVENT (
    event_id       VARCHAR(20),
    shipment_id    VARCHAR(20),
    event_type     VARCHAR(30),
    event_ts       TIMESTAMP_NTZ,
    warehouse_id   VARCHAR(20),
    notes          VARCHAR(200)
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.FACT_ROUTE_LEG (
    leg_id           VARCHAR(20),
    shipment_id      VARCHAR(20),
    leg_number       INT,
    origin_warehouse VARCHAR(20),
    dest_warehouse   VARCHAR(20),
    courier_id       VARCHAR(20),
    depart_ts        TIMESTAMP_NTZ,
    arrive_ts        TIMESTAMP_NTZ,
    distance_km      FLOAT,
    cost             FLOAT
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.FACT_SLA_BREACH (
    breach_id            VARCHAR(20),
    shipment_id          VARCHAR(20),
    breach_type          VARCHAR(20),
    breach_hours         FLOAT,
    root_cause           VARCHAR(30),
    compensation_amount  FLOAT
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.FACT_COURIER_EARNING (
    earning_id          VARCHAR(20),
    courier_id          VARCHAR(20),
    date                DATE,
    deliveries_completed INT,
    gross_earning       FLOAT,
    fuel_allowance      FLOAT,
    bonus               FLOAT,
    net_earning         FLOAT
);

CREATE OR REPLACE TABLE GOASIA.LOGISTICS.FACT_SHIPPER_INVOICE (
    invoice_id       VARCHAR(20),
    shipper_id       VARCHAR(20),
    month            DATE,
    total_shipments  INT,
    total_weight_kg  FLOAT,
    gross_amount     FLOAT,
    discount         FLOAT,
    tax              FLOAT,
    net_amount       FLOAT,
    status           VARCHAR(15)
);

-- ============================================================
-- 6. DOCUMENT TABLE (for Cortex Search)
-- ============================================================

CREATE OR REPLACE TABLE GOASIA.DOCUMENTS.RAW_DOCUMENTS (
    doc_id         INT AUTOINCREMENT,
    doc_type       VARCHAR(50),
    content        VARCHAR(16777216),
    source_file    VARCHAR(100),
    created_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================
-- 7. DATA LOADING (run after uploading parquet to stage)
-- ============================================================

-- Shared dimensions
COPY INTO GOASIA.SHARED.DIM_COUNTRY FROM @GOASIA.SHARED.DATA_STAGE/shared/dim_country.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.SHARED.DIM_CITY
FROM (
    SELECT
        $1:city_id::VARCHAR(20),
        $1:city_name::VARCHAR(60),
        $1:country_cd::VARCHAR(5),
        $1:population::INT,
        $1:tier::VARCHAR(5),
        NVL(TRY_TO_DATE($1:launch_date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:launch_date::VARCHAR, 38, 0), 9)))
    FROM @GOASIA.SHARED.DATA_STAGE/shared/dim_city.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.SHARED.DIM_ZONE FROM @GOASIA.SHARED.DATA_STAGE/shared/dim_zone.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Rides domain
COPY INTO GOASIA.RIDES.DIM_DRIVER
FROM (
    SELECT
        $1:driver_id::VARCHAR(20),
        $1:driver_name::VARCHAR(80),
        $1:city_id::VARCHAR(20),
        $1:vehicle_type::VARCHAR(15),
        $1:rating::FLOAT,
        NVL(TRY_TO_DATE($1:signup_date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:signup_date::VARCHAR, 38, 0), 9))),
        $1:status::VARCHAR(15),
        $1:tier::VARCHAR(10),
        $1:total_trips::INT,
        $1:is_active::BOOLEAN
    FROM @GOASIA.SHARED.DATA_STAGE/rides/dim_driver.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.RIDES.DIM_RIDER
FROM (
    SELECT
        $1:rider_id::VARCHAR(20),
        $1:rider_name::VARCHAR(80),
        $1:city_id::VARCHAR(20),
        NVL(TRY_TO_DATE($1:signup_date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:signup_date::VARCHAR, 38, 0), 9))),
        $1:tier::VARCHAR(10),
        $1:lifetime_rides::INT,
        $1:lifetime_spend::FLOAT,
        $1:is_active::BOOLEAN
    FROM @GOASIA.SHARED.DATA_STAGE/rides/dim_rider.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.RIDES.DIM_VEHICLE FROM @GOASIA.SHARED.DATA_STAGE/rides/dim_vehicle.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.RIDES.FACT_TRIP FROM @GOASIA.SHARED.DATA_STAGE/rides/fact_trip.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.RIDES.FACT_TRIP_EVENT FROM @GOASIA.SHARED.DATA_STAGE/rides/fact_trip_event.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.RIDES.FACT_SURGE_PRICING FROM @GOASIA.SHARED.DATA_STAGE/rides/fact_surge_pricing.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.RIDES.FACT_DRIVER_EARNING
FROM (
    SELECT
        $1:earning_id::VARCHAR(20),
        $1:driver_id::VARCHAR(20),
        NVL(TRY_TO_DATE($1:date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:date::VARCHAR, 38, 0), 9))),
        $1:trips_completed::INT,
        $1:gross_earning::FLOAT,
        $1:commission::FLOAT,
        $1:bonus::FLOAT,
        $1:incentive::FLOAT,
        $1:net_earning::FLOAT
    FROM @GOASIA.SHARED.DATA_STAGE/rides/fact_driver_earning.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.RIDES.FACT_RIDER_PAYMENT FROM @GOASIA.SHARED.DATA_STAGE/rides/fact_rider_payment.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.RIDES.FACT_PROMO_USAGE
FROM (
    SELECT
        $1:promo_id::VARCHAR(20),
        $1:rider_id::VARCHAR(20),
        $1:campaign_name::VARCHAR(30),
        $1:discount_type::VARCHAR(15),
        $1:discount_value::FLOAT,
        $1:trip_id::VARCHAR(20),
        NVL(TRY_TO_DATE($1:redeemed_date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:redeemed_date::VARCHAR, 38, 0), 9)))
    FROM @GOASIA.SHARED.DATA_STAGE/rides/fact_promo_usage.parquet
)
FILE_FORMAT = (TYPE = PARQUET);

-- Logistics domain
COPY INTO GOASIA.LOGISTICS.DIM_SHIPPER
FROM (
    SELECT
        $1:shipper_id::VARCHAR(20),
        $1:company_name::VARCHAR(100),
        $1:industry::VARCHAR(30),
        $1:city_id::VARCHAR(20),
        $1:tier::VARCHAR(15),
        $1:monthly_volume::INT,
        $1:contract_type::VARCHAR(15),
        NVL(TRY_TO_DATE($1:signup_date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:signup_date::VARCHAR, 38, 0), 9))),
        $1:is_active::BOOLEAN
    FROM @GOASIA.SHARED.DATA_STAGE/logistics/dim_shipper.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.LOGISTICS.DIM_COURIER
FROM (
    SELECT
        $1:courier_id::VARCHAR(20),
        $1:courier_name::VARCHAR(80),
        $1:city_id::VARCHAR(20),
        $1:vehicle_type::VARCHAR(15),
        $1:capacity_kg::FLOAT,
        $1:rating::FLOAT,
        $1:status::VARCHAR(15),
        NVL(TRY_TO_DATE($1:signup_date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:signup_date::VARCHAR, 38, 0), 9))),
        $1:is_active::BOOLEAN
    FROM @GOASIA.SHARED.DATA_STAGE/logistics/dim_courier.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.LOGISTICS.DIM_WAREHOUSE FROM @GOASIA.SHARED.DATA_STAGE/logistics/dim_warehouse.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.LOGISTICS.DIM_PARCEL_TYPE FROM @GOASIA.SHARED.DATA_STAGE/logistics/dim_parcel_type.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.LOGISTICS.FACT_SHIPMENT FROM @GOASIA.SHARED.DATA_STAGE/logistics/fact_shipment.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.LOGISTICS.FACT_PARCEL_EVENT FROM @GOASIA.SHARED.DATA_STAGE/logistics/fact_parcel_event.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.LOGISTICS.FACT_ROUTE_LEG FROM @GOASIA.SHARED.DATA_STAGE/logistics/fact_route_leg.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.LOGISTICS.FACT_SLA_BREACH FROM @GOASIA.SHARED.DATA_STAGE/logistics/fact_sla_breach.parquet
    FILE_FORMAT = (TYPE = PARQUET) MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
COPY INTO GOASIA.LOGISTICS.FACT_COURIER_EARNING
FROM (
    SELECT
        $1:earning_id::VARCHAR(20),
        $1:courier_id::VARCHAR(20),
        NVL(TRY_TO_DATE($1:date::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:date::VARCHAR, 38, 0), 9))),
        $1:deliveries_completed::INT,
        $1:gross_earning::FLOAT,
        $1:fuel_allowance::FLOAT,
        $1:bonus::FLOAT,
        $1:net_earning::FLOAT
    FROM @GOASIA.SHARED.DATA_STAGE/logistics/fact_courier_earning.parquet
)
FILE_FORMAT = (TYPE = PARQUET);
COPY INTO GOASIA.LOGISTICS.FACT_SHIPPER_INVOICE
FROM (
    SELECT
        $1:invoice_id::VARCHAR(20),
        $1:shipper_id::VARCHAR(20),
        NVL(TRY_TO_DATE($1:month::VARCHAR), TO_DATE(TO_TIMESTAMP(TRY_TO_NUMBER($1:month::VARCHAR, 38, 0), 9))),
        $1:total_shipments::INT,
        $1:total_weight_kg::FLOAT,
        $1:gross_amount::FLOAT,
        $1:discount::FLOAT,
        $1:tax::FLOAT,
        $1:net_amount::FLOAT,
        $1:status::VARCHAR(15)
    FROM @GOASIA.SHARED.DATA_STAGE/logistics/fact_shipper_invoice.parquet
)
FILE_FORMAT = (TYPE = PARQUET);

-- ============================================================
-- 8. BENCHMARK TRAP DATA — Post-Load Refinements
-- ============================================================
-- Override shipper tier/industry/volume on confusing name pairs
-- so disambiguation failures produce dramatically wrong results.

UPDATE GOASIA.LOGISTICS.DIM_SHIPPER
SET tier = 'ENTERPRISE', industry = 'ECOMMERCE', monthly_volume = 8500
WHERE shipper_id = 'SHP-000001';

UPDATE GOASIA.LOGISTICS.DIM_SHIPPER
SET tier = 'INDIVIDUAL', industry = 'RETAIL', monthly_volume = 120
WHERE shipper_id = 'SHP-000002';

UPDATE GOASIA.LOGISTICS.DIM_SHIPPER
SET tier = 'ENTERPRISE', industry = 'ELECTRONICS', monthly_volume = 6200
WHERE shipper_id = 'SHP-000003';

UPDATE GOASIA.LOGISTICS.DIM_SHIPPER
SET tier = 'SMB', industry = 'FASHION', monthly_volume = 450
WHERE shipper_id = 'SHP-000004';

UPDATE GOASIA.LOGISTICS.DIM_SHIPPER
SET tier = 'ENTERPRISE', industry = 'MANUFACTURING', monthly_volume = 7800
WHERE shipper_id = 'SHP-000005';

UPDATE GOASIA.LOGISTICS.DIM_SHIPPER
SET tier = 'INDIVIDUAL', industry = 'FASHION', monthly_volume = 90
WHERE shipper_id = 'SHP-000006';

-- ============================================================
-- 9. VERIFY ROW COUNTS
-- ============================================================
SELECT 'SHARED' AS domain, t.table_name, t.row_count
FROM GOASIA.INFORMATION_SCHEMA.TABLES t WHERE t.table_schema = 'SHARED' AND t.table_type = 'BASE TABLE'
UNION ALL
SELECT 'RIDES', t.table_name, t.row_count
FROM GOASIA.INFORMATION_SCHEMA.TABLES t WHERE t.table_schema = 'RIDES' AND t.table_type = 'BASE TABLE'
UNION ALL
SELECT 'LOGISTICS', t.table_name, t.row_count
FROM GOASIA.INFORMATION_SCHEMA.TABLES t WHERE t.table_schema = 'LOGISTICS' AND t.table_type = 'BASE TABLE'
ORDER BY 1, 2;

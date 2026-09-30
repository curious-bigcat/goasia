-- ============================================================
-- GoAsia — Document Loading & Cortex Search Setup
-- ============================================================
-- Run AFTER 01_create_tables.sql and 02_upload_data.sh
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE GOASIA;
USE WAREHOUSE DEMO_WH;

-- ============================================================
-- 1. LOAD DOCUMENTS INTO RAW_DOCUMENTS TABLE
-- ============================================================
-- Parse each document file: split on '---' delimiter to create
-- one row per document record.

-- First, create a temporary stage-read approach using a stream
-- to split documents. We'll use a Python UDF for this.

CREATE OR REPLACE FUNCTION GOASIA.DOCUMENTS.SPLIT_DOCS(content VARCHAR)
RETURNS TABLE(doc_text VARCHAR)
LANGUAGE SQL
AS
$$
    SELECT VALUE::VARCHAR AS doc_text
    FROM TABLE(SPLIT_TO_TABLE(content, '---'))
    WHERE VALUE IS NOT NULL AND TRIM(VALUE) != ''
$$;

-- Load raw text files as single-column rows
CREATE OR REPLACE TABLE GOASIA.DOCUMENTS.DOC_STAGING (
    line_content VARCHAR(16777216),
    source_file  VARCHAR(100)
);

-- For each document type, you can load via:
COPY INTO GOASIA.DOCUMENTS.DOC_STAGING (line_content, source_file)
   FROM (SELECT $1, METADATA$FILENAME FROM @GOASIA.SHARED.DATA_STAGE/documents/)
   FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = 'NONE' RECORD_DELIMITER = '\n')
   PATTERN = '.*\.txt';


-- ============================================================
-- 2. CORTEX SEARCH SERVICE — RIDES DOCUMENTS
-- ============================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE GOASIA.SEARCH_SERVICES.RIDES_DOC_SEARCH
  ON content
  ATTRIBUTES doc_type
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 day'
  AS (
    SELECT
      doc_id,
      doc_type,
      content,
      source_file,
      created_at
    FROM GOASIA.DOCUMENTS.RAW_DOCUMENTS
    WHERE doc_type IN ('incident_reports','rider_complaints','safety_audits','support_chats','driver_surveys')
  );

-- ============================================================
-- 3. CORTEX SEARCH SERVICE — LOGISTICS DOCUMENTS
-- ============================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE GOASIA.SEARCH_SERVICES.LOGISTICS_DOC_SEARCH
  ON content
  ATTRIBUTES doc_type
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 day'
  AS (
    SELECT
      doc_id,
      doc_type,
      content,
      source_file,
      created_at
    FROM GOASIA.DOCUMENTS.RAW_DOCUMENTS
    WHERE doc_type IN ('regulatory_filings','news_articles','market_research')
  );

-- ============================================================
-- 4. CORTEX SEARCH SERVICE — ALL DOCUMENTS (combined)
-- ============================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE GOASIA.SEARCH_SERVICES.ALL_DOC_SEARCH
  ON content
  ATTRIBUTES doc_type
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 day'
  AS (
    SELECT
      doc_id,
      doc_type,
      content,
      source_file,
      created_at
    FROM GOASIA.DOCUMENTS.RAW_DOCUMENTS
  );

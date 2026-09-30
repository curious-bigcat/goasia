# GoAsia — Snowflake Participant Setup Guide

> For TechUp26 APJC session: Cortex Agent vs Genie Agent Benchmark
>
> Time required: ~20 minutes

---

## What's Already Built (by the session host)

| Component | Details |
|-----------|---------|
| **GOASIA database** | 22 tables, 250M+ rows across SHARED, RIDES, LOGISTICS schemas |
| **38K documents** | Incident reports, rider complaints, driver surveys, safety audits, support chats, regulatory filings, news articles, market research |
| **Replication group** | `GOASIA_REPL` — ready for you to pull into your account |

## What You Will Build

| Component | Details |
|-----------|---------|
| **GOASIA_LOCAL database** | Your local database for Cortex objects (replicated DB is read-only) |
| **3 Cortex Search services** | RIDES_DOC_SEARCH (28K docs), LOGISTICS_DOC_SEARCH (10K docs), ALL_DOC_SEARCH (38K docs) |
| **2 Semantic Views** | RIDES_SEMANTIC_VIEW (11 tables), LOGISTICS_SEMANTIC_VIEW (11 tables) — created via Autopilot wizard |
| **1 Cortex Agent** | GOASIA_AGENT with 5 tools (2 semantic views + 3 Cortex Search services) |

---

## Prerequisites

- ACCOUNTADMIN role on your Snowflake account
- A warehouse (any size — XS is fine for setup, S or M for querying 250M rows)

---

## Step 1: Pull the GoAsia Dataset (Replication)

The GoAsia database (22 tables, 250M+ rows, 38K documents) is shared from the provider account via replication. Run these 3 commands to pull it into your account.

```sql
USE ROLE ACCOUNTADMIN;

-- 1. Create a replica of the replication group
CREATE REPLICATION GROUP GOASIA_REPL
  AS REPLICA OF SFSEAPAC.BSURESH.GOASIA_REPL;

-- 2. Pull the data (~5-10 minutes for 9GB)
ALTER REPLICATION GROUP GOASIA_REPL REFRESH;
```

Wait for the refresh to complete, then verify:

```sql
-- 3. Verify the data arrived
SELECT table_schema, table_name, row_count
FROM GOASIA.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE' AND row_count > 0
ORDER BY table_schema, table_name;
```

You should see 22+ tables with 250M+ total rows across SHARED, RIDES, LOGISTICS, and DOCUMENTS schemas.

> **Note**: The replicated GOASIA database is **read-only**. You cannot create new objects (semantic views, search services, agents) inside it. We'll create those in a separate database in the next steps.

---

## Step 2: Create Your Local Database for Cortex Objects

Since the replicated database is read-only, create a local database to hold your Cortex Search services, semantic views, and agent.

```sql
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS GOASIA_LOCAL;
CREATE SCHEMA IF NOT EXISTS GOASIA_LOCAL.SEARCH_SERVICES;
CREATE SCHEMA IF NOT EXISTS GOASIA_LOCAL.SEMANTIC_VIEWS;
CREATE SCHEMA IF NOT EXISTS GOASIA_LOCAL.AGENTS;
```

---

## Step 3: Create Cortex Search Services

These index the 38K documents from the replicated RAW_DOCUMENTS table for natural language search.

> **Important**: Replace `DEMO_WH` with your warehouse name if different.

```sql
USE ROLE SYSADMIN;
USE WAREHOUSE DEMO_WH;  -- Replace with your warehouse

-- 3A. Rides Document Search (28K docs: incidents, complaints, safety, chats, surveys)
CREATE OR REPLACE CORTEX SEARCH SERVICE GOASIA_LOCAL.SEARCH_SERVICES.RIDES_DOC_SEARCH
  ON content
  ATTRIBUTES doc_type
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 day'
  AS (
    SELECT doc_id, doc_type, content, source_file, created_at
    FROM GOASIA.DOCUMENTS.RAW_DOCUMENTS
    WHERE doc_type IN ('incident_reports','rider_complaints','safety_audits','support_chats','driver_surveys')
  );

-- 3B. Logistics Document Search (10K docs: regulatory, news, market research)
CREATE OR REPLACE CORTEX SEARCH SERVICE GOASIA_LOCAL.SEARCH_SERVICES.LOGISTICS_DOC_SEARCH
  ON content
  ATTRIBUTES doc_type
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 day'
  AS (
    SELECT doc_id, doc_type, content, source_file, created_at
    FROM GOASIA.DOCUMENTS.RAW_DOCUMENTS
    WHERE doc_type IN ('regulatory_filings','news_articles','market_research')
  );

-- 3C. All Document Search (38K docs: all 8 types combined)
CREATE OR REPLACE CORTEX SEARCH SERVICE GOASIA_LOCAL.SEARCH_SERVICES.ALL_DOC_SEARCH
  ON content
  ATTRIBUTES doc_type
  WAREHOUSE = DEMO_WH
  TARGET_LAG = '1 day'
  AS (
    SELECT doc_id, doc_type, content, source_file, created_at
    FROM GOASIA.DOCUMENTS.RAW_DOCUMENTS
  );
```

Verify all 3 services are active:

```sql
SHOW CORTEX SEARCH SERVICES IN SCHEMA GOASIA_LOCAL.SEARCH_SERVICES;
-- Check: indexing_state = ACTIVE, source_data_num_rows > 0
-- If rows show 0, wait 1-2 minutes and check again
```

---

## Step 4: Create Semantic Views (Autopilot Wizard)

Semantic views are created via the Autopilot wizard in Workspaces.

### 4A. Rides Semantic View

1. In Snowsight, navigate to **Workspaces**
2. Click **Add new** → **Semantic View**
3. Select location:
   - **Database**: `GOASIA_LOCAL`
   - **Schema**: `SEMANTIC_VIEWS`
   - **Name**: `RIDES_SEMANTIC_VIEW`
4. Enter a description (e.g., "GoAsia ride-hailing operations across APJC")
5. Click **Next**
6. Skip the context step (no SQL queries or file uploads needed), click **Next**
7. Under **Select tables**, add these 11 tables from the replicated GOASIA database:

| # | Schema | Table |
|---|--------|-------|
| 1 | `GOASIA.RIDES` | `FACT_TRIP` |
| 2 | `GOASIA.RIDES` | `DIM_DRIVER` |
| 3 | `GOASIA.RIDES` | `DIM_RIDER` |
| 4 | `GOASIA.RIDES` | `DIM_VEHICLE` |
| 5 | `GOASIA.RIDES` | `FACT_SURGE_PRICING` |
| 6 | `GOASIA.RIDES` | `FACT_DRIVER_EARNING` |
| 7 | `GOASIA.RIDES` | `FACT_RIDER_PAYMENT` |
| 8 | `GOASIA.RIDES` | `FACT_PROMO_USAGE` |
| 9 | `GOASIA.SHARED` | `DIM_CITY` |
| 10 | `GOASIA.SHARED` | `DIM_COUNTRY` |
| 11 | `GOASIA.SHARED` | `DIM_ZONE` |

8. Under **Select columns**, select all columns
9. Enable **Add sample values** and **Add AI-generated descriptions**
10. Click **Create and save**, then **Save and run**
11. Wait for generation to complete (1-2 minutes)
12. When Autopilot generates suggestions (metrics, relationships, synonyms, verified queries) — **Accept ALL suggestions**
13. Click **Deploy**

### 4B. Logistics Semantic View

1. Go back to **Workspaces** → **Add new** → **Semantic View**
2. Select location:
   - **Database**: `GOASIA_LOCAL`
   - **Schema**: `SEMANTIC_VIEWS`
   - **Name**: `LOGISTICS_SEMANTIC_VIEW`
3. Enter a description (e.g., "GoAsia logistics and delivery operations across APJC")
4. Click **Next**
5. Skip the context step, click **Next**
6. Under **Select tables**, add these 11 tables:

| # | Schema | Table |
|---|--------|-------|
| 1 | `GOASIA.LOGISTICS` | `FACT_SHIPMENT` |
| 2 | `GOASIA.LOGISTICS` | `DIM_SHIPPER` |
| 3 | `GOASIA.LOGISTICS` | `DIM_COURIER` |
| 4 | `GOASIA.LOGISTICS` | `DIM_WAREHOUSE` |
| 5 | `GOASIA.LOGISTICS` | `DIM_PARCEL_TYPE` |
| 6 | `GOASIA.LOGISTICS` | `FACT_SLA_BREACH` |
| 7 | `GOASIA.LOGISTICS` | `FACT_COURIER_EARNING` |
| 8 | `GOASIA.LOGISTICS` | `FACT_SHIPPER_INVOICE` |
| 9 | `GOASIA.LOGISTICS` | `FACT_ROUTE_LEG` |
| 10 | `GOASIA.SHARED` | `DIM_CITY` |
| 11 | `GOASIA.SHARED` | `DIM_COUNTRY` |

7. Under **Select columns**, select all columns
8. Enable **Add sample values** and **Add AI-generated descriptions**
9. Click **Create and save**, then **Save and run**
10. Wait for generation to complete (1-2 minutes)
11. When Autopilot generates suggestions — **Accept ALL suggestions**
12. Click **Deploy**

---

## Step 5: Create the Cortex Agent (UI)

1. Navigate to **Snowsight > AI & ML > Cortex AI > Agents**
2. Click **+ Create Agent**
3. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `GOASIA_AGENT` |
| **Database** | `GOASIA_LOCAL` |
| **Schema** | `AGENTS` |

4. **Add Tools** (5 total):

**Semantic View tools (2):**

| Tool Type | Source |
|-----------|--------|
| Semantic View | `GOASIA_LOCAL.SEMANTIC_VIEWS.RIDES_SEMANTIC_VIEW` |
| Semantic View | `GOASIA_LOCAL.SEMANTIC_VIEWS.LOGISTICS_SEMANTIC_VIEW` |

For each semantic view tool:
   - Click **Generate with Cortex AI** to auto-generate the description
   - Under **Warehouse**, select **Custom** and choose your warehouse (e.g., `DEMO_WH` or your own)

**Cortex Search tools (3):**

For each Cortex Search tool, use Cortex AI to generate the description.

| Tool Type | Source |
|-----------|--------|
| Cortex Search | `GOASIA_LOCAL.SEARCH_SERVICES.RIDES_DOC_SEARCH` |
| Cortex Search | `GOASIA_LOCAL.SEARCH_SERVICES.LOGISTICS_DOC_SEARCH` |
| Cortex Search | `GOASIA_LOCAL.SEARCH_SERVICES.ALL_DOC_SEARCH` |

5. **Agent Instructions** — paste into the Instructions field:

```
You are GoAsia's data assistant covering ride-hailing and logistics operations across 10 APJC markets (Singapore, Malaysia, Thailand, Philippines, Vietnam, Indonesia, India, Japan, Australia, South Korea).

TOOL ROUTING:
- Structured data questions (counts, revenue, metrics, rankings) → use the rides or logistics semantic view
- Ride document questions (incidents, complaints, audits, support chats, driver surveys) → use RIDES_DOC_SEARCH
- Logistics document questions (regulatory filings, news articles, market research) → use LOGISTICS_DOC_SEARCH
- Cross-domain or ambiguous document questions → use ALL_DOC_SEARCH
- When a question spans both rides and logistics, query both semantic views and combine results
- When unsure which domain, ask the user to clarify rides or logistics
```

6. Click **Create**

---

## Step 6: Test the Agent

Try these questions to verify everything is working:

**Structured data (rides):**
> What is the ride completion rate by country?

Expected: ~88% across all countries (using `status = 'COMPLETED'`)

**Structured data (logistics):**
> What is our delivery success rate?

Expected: 82.0% (using `status = 'DELIVERED'`)

**Document search:**
> What do driver surveys say about satisfaction?

Expected: themes about commission rates, app usability, earnings concerns

**Cross-domain:**
> What is GoAsia's total combined revenue across rides and logistics?

Expected: ~$939.5M (rides $686.5M + logistics $253.0M)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `GOASIA` database not visible | Replication refresh may still be running. Run `ALTER REPLICATION GROUP GOASIA_REPL REFRESH;` again and wait |
| Cortex Search shows 0 rows | Wait 1-2 minutes after creation for initial indexing. Check `SHOW CORTEX SEARCH SERVICES` for `source_data_num_rows` |
| Semantic view Autopilot not generating | Ensure you selected tables from the `GOASIA` database (replicated), not `GOASIA_LOCAL` |
| Agent can't find semantic views | Verify semantic views were created in `GOASIA_LOCAL.SEMANTIC_VIEWS`, not inside the replicated `GOASIA` database |
| Permission errors on replicated tables | Run `USE ROLE ACCOUNTADMIN;` — the replicated database is owned by ACCOUNTADMIN |
| Warehouse not found | Replace `DEMO_WH` in the Cortex Search SQL with your warehouse name |

---

## Architecture

```
GOASIA (replicated, read-only)          GOASIA_LOCAL (your account)
  |                                       |
  |-- SHARED (DIM_CITY, DIM_COUNTRY...)   |-- SEARCH_SERVICES
  |-- RIDES (FACT_TRIP, DIM_DRIVER...)    |     |-- RIDES_DOC_SEARCH (28K docs)
  |-- LOGISTICS (FACT_SHIPMENT...)        |     |-- LOGISTICS_DOC_SEARCH (10K docs)
  |-- DOCUMENTS (RAW_DOCUMENTS)           |     |-- ALL_DOC_SEARCH (38K docs)
                                          |-- SEMANTIC_VIEWS
                                          |     |-- RIDES_SEMANTIC_VIEW
                                          |     |-- LOGISTICS_SEMANTIC_VIEW
                                          |-- AGENTS
                                                |-- GOASIA_AGENT
```

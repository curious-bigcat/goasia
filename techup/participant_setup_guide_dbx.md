# GoAsia — Databricks Participant Setup Guide

> For TechUp26 APJC session: Cortex Agent vs Genie Agent Benchmark
>
> Time required: ~20 minutes

---

## What's Already Built (by the session host)

| Component | Details |
|-----------|---------|
| **22 tables** | 250M+ rows in `apjtechup26.bsuresh-session` (rides, logistics, shared dimensions) |
| **8 document files** | Loaded into the Knowledge Assistant |
| **goasia-knowledge-base** | Knowledge Assistant with all 8 document types — shared across all participants |

## What You Will Build

| Component | Details |
|-----------|---------|
| **Your own schema** | `apjtechup26.<your-name>-session` for metric views |
| **2 Metric Views** | rides_metric_view, logistics_metric_view — created via AI assistant |
| **2 Genie Agents** | GoAsia Rides Agent, GoAsia Logistics Agent — each with their metric view + source tables |
| **1 Supervisor Agent** | GoAsia APJC Agent with 3 tools (2 Genie Agents + shared Knowledge Assistant) |

---

## Prerequisites

- Access to Databricks workspace with the `apjtechup26` catalog
- A SQL Warehouse (any size)
- Access to `goasia-knowledge-base` Knowledge Assistant (already created)

---

## Step 1: Create Your Schema

All GoAsia tables are already loaded in the shared schema. Create your own schema to hold your metric views and agent objects.

1. In Databricks, open a **SQL Editor** or **Notebook**
2. Run:

```sql
CREATE SCHEMA IF NOT EXISTS `apjtechup26`.`<your-name>-session`;
USE CATALOG `apjtechup26`;
USE SCHEMA `<your-name>-session`;
```

> Replace `<your-name>` with your name (e.g., `jroland-session`, `vyadav-session`)

---

## Step 2: Verify Source Data

The source tables are in `apjtechup26.bsuresh-session`. Verify you can access them:

```sql
-- Should return 50,000,000
SELECT COUNT(*) FROM `apjtechup26`.`bsuresh-session`.fact_trip;

-- Should return 50,000,000
SELECT COUNT(*) FROM `apjtechup26`.`bsuresh-session`.fact_shipment;

-- Check all tables
SHOW TABLES IN `apjtechup26`.`bsuresh-session`;
```

You should see 22 tables across rides, logistics, and shared dimensions.

---

## Step 3: Create Metric Views

Use the Databricks AI assistant to generate metric views in **your** schema. These reference the source tables in `bsuresh-session`.

### 3A. Rides Metric View

In the SQL Editor, use the AI assistant with this prompt:

```
Create a metric view called rides_metric_view in my current schema using these tables
from `apjtechup26`.`bsuresh-session`:
fact_trip, dim_driver, dim_rider, dim_vehicle, dim_zone, dim_city, dim_country.
Include necessary relationships.
```

### 3B. Logistics Metric View

```
Create a metric view called logistics_metric_view in my current schema using these tables
from `apjtechup26`.`bsuresh-session`:
fact_shipment, dim_shipper, dim_courier, dim_parcel_type, dim_warehouse, dim_city, dim_country.
Include necessary relationships.
```

---

## Step 4: Create Rides Genie Agent

1. Navigate to **New** → **Genie Space**
2. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `GoAsia Rides Agent - <your-name>` |
| **Description** | `GoAsia ride-hailing operations across APJC` |
| **Warehouse** | Select your SQL Warehouse |

3. **Add Tables** (from `apjtechup26.bsuresh-session` + your metric view):

| # | Table |
|---|-------|
| 1 | `<your-schema>.rides_metric_view` |
| 2 | `bsuresh-session.fact_trip` |
| 3 | `bsuresh-session.dim_driver` |
| 4 | `bsuresh-session.dim_rider` |
| 5 | `bsuresh-session.dim_vehicle` |
| 6 | `bsuresh-session.fact_trip_event` |
| 7 | `bsuresh-session.fact_surge_pricing` |
| 8 | `bsuresh-session.fact_driver_earning` |
| 9 | `bsuresh-session.fact_rider_payment` |
| 10 | `bsuresh-session.fact_promo_usage` |
| 11 | `bsuresh-session.dim_city` |
| 12 | `bsuresh-session.dim_country` |
| 13 | `bsuresh-session.dim_zone` |

4. **Instructions** — use Genie code to generate:

```
Generate instructions for this Genie space based on all the tables added.
```

5. Accept all other OOTB defaults (no custom synonyms, no SQL examples)
6. Click **Create**

---

## Step 5: Create Logistics Genie Agent

1. Navigate to **New** → **Genie Space**
2. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `GoAsia Logistics Agent - <your-name>` |
| **Description** | `GoAsia logistics and delivery operations across APJC` |
| **Warehouse** | Select your SQL Warehouse |

3. **Add Tables**:

| # | Table |
|---|-------|
| 1 | `<your-schema>.logistics_metric_view` |
| 2 | `bsuresh-session.fact_shipment` |
| 3 | `bsuresh-session.dim_shipper` |
| 4 | `bsuresh-session.dim_courier` |
| 5 | `bsuresh-session.dim_warehouse` |
| 6 | `bsuresh-session.dim_parcel_type` |
| 7 | `bsuresh-session.fact_parcel_event` |
| 8 | `bsuresh-session.fact_route_leg` |
| 9 | `bsuresh-session.fact_sla_breach` |
| 10 | `bsuresh-session.fact_courier_earning` |
| 11 | `bsuresh-session.fact_shipper_invoice` |
| 12 | `bsuresh-session.dim_city` |
| 13 | `bsuresh-session.dim_country` |

4. **Instructions** — use Genie code to generate:

```
Generate instructions for this Genie space based on all the tables added.
```

5. Accept all other OOTB defaults
6. Click **Create**

---

## Step 6: Create Supervisor Agent

1. Navigate to **New** → **Agent**
2. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `GoAsia APJC Agent - <your-name>` |
| **Description** | `GoAsia super-app agent covering ride-hailing and logistics operations across APJC markets` |

3. **Add Tools** — add only these 3:
   - Your `GoAsia Rides Agent - <your-name>` (Genie Agent)
   - Your `GoAsia Logistics Agent - <your-name>` (Genie Agent)
   - **`goasia-knowledge-base`** (Knowledge Assistant — **already created and shared across all participants, do NOT recreate**)

> **IMPORTANT**: The `goasia-knowledge-base` Knowledge Assistant is pre-configured with all 8 document types. Search for it by name when adding tools. Do not create a new one.

4. **Remove** any other default tools (including Python code environment)

5. **Instructions** — paste:

```
You are GoAsia's data assistant covering ride-hailing and logistics operations across 10 APJC markets (Singapore, Malaysia, Thailand, Philippines, Vietnam, Indonesia, India, Japan, Australia, South Korea).

TOOL ROUTING:
- Rides questions (trips, fares, drivers, riders, surge pricing, payments, promos) → use GoAsia Rides Agent
- Logistics questions (shipments, shippers, couriers, warehouses, SLA, invoices, routes) → use GoAsia Logistics Agent
- Document questions (incidents, complaints, audits, surveys, regulations, news) → use goasia-knowledge-base
- Cross-domain questions → call both Rides and Logistics agents and combine results
- When unsure which domain, ask the user to clarify rides or logistics
```

6. Click **Create**

---

## Step 7: Test the Agent

Try these questions to verify everything is working:

**Structured data (rides):**
> What is the ride completion rate by country?

**Structured data (logistics):**
> What is our delivery success rate?

**Document search:**
> What do driver surveys say about satisfaction?

**Cross-domain:**
> What is GoAsia's total combined revenue across rides and logistics?

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Cannot access `bsuresh-session` tables | Check you have `USE CATALOG` and `SELECT` privileges on `apjtechup26` |
| Metric view creation fails | Ensure you're creating in your own schema, not `bsuresh-session` |
| Knowledge Assistant not found | Search for `goasia-knowledge-base` — it's shared across the workspace |
| Genie Agent can't find tables | Verify table paths use `bsuresh-session` (source data) and your schema (metric views) |
| Supervisor Agent has extra tools | Remove Python code environment and any other default tools — keep only the 3 listed above |

---

## Architecture

```
GoAsia APJC Agent (Supervisor) — your agent
  |
  |-- GoAsia Rides Agent (Genie) — your agent
  |     |-- rides_metric_view (your schema)
  |     |-- 9 rides tables + 3 shared dims (from bsuresh-session)
  |
  |-- GoAsia Logistics Agent (Genie) — your agent
  |     |-- logistics_metric_view (your schema)
  |     |-- 10 logistics tables + 2 shared dims (from bsuresh-session)
  |
  |-- goasia-knowledge-base (Knowledge Assistant) — shared
        |-- 8 document types (incidents, complaints, surveys, etc.)
```

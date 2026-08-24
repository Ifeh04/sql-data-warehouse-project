# 🏗️ Sales & Customer Data Warehouse
### End-to-End Medallion Architecture (Bronze → Silver → Gold) on PostgreSQL

A complete data engineering pipeline that ingests raw **CRM & ERP** data into a PostgreSQL 17 data warehouse, cleans and standardizes it through a **Medallion (Bronze → Silver → Gold)** architecture, and delivers a business-ready **star schema** for analytics and reporting.

> 📌 Built as part of a data engineering course originally taught on **SQL Server** — fully re-implemented on **PostgreSQL 17** to build open-source RDBMS expertise.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#%EF%B8%8F-architecture)
- [Tech Stack](#%EF%B8%8F-tech-stack)
- [Repository Structure](#-repository-structure)
- [How to Run the Pipeline](#-how-to-run-the-pipeline)
- [Data Quality Issues & Business Rules](#-data-quality-issues--business-rules)
- [The Gold Star Schema](#-the-gold-star-schema)
- [Testing](#-testing)
- [SQL Server → PostgreSQL Conversion](#-sql-server--postgresql-conversion)
- [Sample Analytics](#-sample-analytics)
- [Future Work](#-future-work)
- [Author](#-author)

---

## 🎯 Project Overview

Two source systems (**CRM** and **ERP**) provide six CSV extracts containing customers, products, sales transactions, demographics, locations, and product categories. The raw data is riddled with real-world quality issues: duplicates, coded values, impossible dates, negative prices, and cross-system conflicts.

This project transforms that chaos into a trusted, analytics-ready star schema using:

- **Bronze** — raw landing zone (data as-is, issues documented)
- **Silver** — cleaned, deduplicated, standardized per-source data
- **Gold** — reconciled dimensional model (2 dimensions + 1 fact)
- **Stored procedures** for repeatable, idempotent reloads
- **A data quality log** as a full audit trail
- **40+ automated quality checks** in the `tests/` folder

---

## 🏛️ Architecture

```
  CRM CSVs ──┐                        PostgreSQL 17 — DataWareHouse
             │    ┌─────────┐  clean   ┌─────────┐  join/reconcile  ┌─────────┐
             ├───▶│ BRONZE  │─dedup───▶│ SILVER  │─────────────────▶│  GOLD   │
  ERP CSVs ──┘    │  (raw)  │standard. │ (clean) │                  │ (star)  │
       COPY       │ 6 tables│          │ 6 tables│                  │ 3 views │
                  └─────────┘          └────┬────┘                  └─────────┘
                                            ▼
                                     data_quality_log
                                      (audit trail)
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **PostgreSQL 17** | Data warehouse engine |
| **pgAdmin 4** | Database administration & query tool |
| **VS Code + SQLTools** | SQL development & database connection |
| **SQL (PL/pgSQL)** | DDL, DML, stored procedures, window functions |
| **Power BI** *(planned)* | Dashboarding on the Gold layer |

---

## 📁 Repository Structure

```
.
├── docs/
│   └── data_catalog.md              # Column-level documentation for ALL layers
├── sql/
│   ├── ddl/
│   │   ├── ddl_bronze.sql           # Bronze schema + tables (raw landing zone)
│   │   ├── ddl_silver.sql           # Silver schema + tables (cleaned layer)
│   │   └── ddl_gold.sql             # Gold star schema (dimensional views)
│   ├── dml/
│   │   └── load_bronze_data.sql     # COPY commands: CSV → Bronze
│   └── procedures/
│       ├── bronze_truncate_tables.sql    # Bronze reload procedure
│       └── silver_load_procedures.sql    # 6 Silver ETL procedures + master loader
├── tests/
│   └── quality_checks.sql           # 40+ data quality checks (Bronze/Silver/Gold)
└── README.md
```

---

## 🔄 How to Run the Pipeline

### 1. Stage the source files
Copy the six CSV files into the PostgreSQL data folder:
```
C:/Program Files/PostgreSQL/17/data/
```

### 2. Execute in order (pgAdmin Query Tool or VS Code)

| Step | Script | Purpose |
|------|--------|---------|
| 1 | `sql/ddl/ddl_bronze.sql` | Create Bronze tables |
| 2 | `sql/dml/load_bronze_data.sql` | Load raw CSV data (`COPY`) |
| 3 | `sql/ddl/ddl_silver.sql` | Create Silver tables + quality log |
| 4 | `sql/procedures/*.sql` | Create stored procedures |
| 5 | `CALL silver.load_silver_layer();` | **Run the full Silver ETL** |
| 6 | `sql/ddl/ddl_gold.sql` | Create Gold star schema views |
| 7 | `tests/quality_checks.sql` | Validate every layer |

### 3. Reload anytime
```sql
CALL bronze.truncate_bronze_tables();   -- clear raw layer
-- re-run load_bronze_data.sql
CALL silver.load_silver_layer();        -- rebuild cleaned layer
```

---

## 🧹 Data Quality Issues & Business Rules

### Issues discovered in Bronze and resolved in Silver

| Table | Issue | Resolution |
|-------|-------|------------|
| `crm_cust_info` | Duplicate customer versions | Kept latest record per `cst_id` (`ROW_NUMBER()` by `cst_create_date DESC`) |
| `crm_cust_info` | Coded values (`S`/`M`, `M`/`F`), untrimmed names | Standardized to Single/Married/…, Male/Female; `TRIM()` |
| `crm_prd_info` | `prd_start_dt` **after** `prd_end_dt` | End date re-derived: `LEAD(start) − 1 day`; `NULL` = active |
| `crm_prd_info` | Category embedded in `prd_key`; NULL costs | Split key → `cat_id` + short `prd_key`; `COALESCE(cost, 0)` |
| `crm_sales_details` | Dates stored as `INT` with 0/negative/bad lengths | Validated & converted to `DATE`; invalid → `NULL` |
| `crm_sales_details` | Negative/NULL sales & prices; `sales ≠ qty × price` | Business rule enforced: derive missing side |
| `erp_cust_az12` | `NAS` prefix on keys; future birth dates | Prefix stripped; future dates → `NULL` |
| `erp_loc_a101` | Hyphens in keys; codes `DE`/`US`/`USA`/empty | Hyphens removed; standardized to full country names |

### Cross-system reconciliation (Gold)

| Rule | Decision |
|------|----------|
| Gender conflict between CRM & ERP | **CRM = master**, ERP = fallback when CRM = 'N/A' |
| Product versions | Only **active** products exposed (`prd_end_dt IS NULL`) |
| Audit | Every conflict & fix logged in `silver.data_quality_log` |

---

## ⭐ The Gold Star Schema

```
                 ┌───────────────────┐
                 │  gold.fact_sales  │
                 └────────┬──────────┘
                          │ surrogate keys
           ┌──────────────┴──────────────┐
           ▼                             ▼
┌─────────────────────┐       ┌─────────────────────┐
│ gold.dim_customers  │       │  gold.dim_products  │
│ (CRM + ERP reconc.) │       │ (active + categories)│
└─────────────────────┘       └─────────────────────┘
```

Full column-level documentation → [`docs/data_catalog.md`](docs/data_catalog.md)

---

## 🧪 Testing

`tests/quality_checks.sql` contains **40+ checks** organized by table and layer:

- **Bronze (diagnostic):** duplicates, spaces, coded-value profiling, invalid dates, referential integrity, business-rule violations
- **Silver (validation):** "expectation: 0 rows" tests proving every cleaning rule worked
- **Gold (model):** orphan-key connectivity, surrogate key uniqueness, fact consistency

---

## 🔁 SQL Server → PostgreSQL Conversion

The course material targets SQL Server; this repo demonstrates the equivalent PostgreSQL implementations:

| SQL Server | PostgreSQL |
|------------|------------|
| `BULK INSERT` | `COPY ... WITH (FORMAT csv, HEADER true)` |
| `ISNULL(col, 0)` | `COALESCE(col, 0)` |
| `GETDATE()` | `CURRENT_TIMESTAMP` |
| `DATETIME2` | `TIMESTAMP` |
| `LEN(col)` | `LENGTH(col)` |
| `CREATE OR ALTER PROCEDURE` | `CREATE OR REPLACE PROCEDURE` |
| `EXEC proc` | `CALL proc()` |
| `IF OBJECT_ID(...) DROP TABLE` | `DROP TABLE IF EXISTS ... CASCADE` |

---

## 📊 Sample Analytics

```sql
-- Revenue by country
SELECT c.country, SUM(f.sales) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;

-- Top product categories by quantity sold
SELECT p.category, SUM(f.quantity) AS units_sold
FROM gold.fact_sales f
JOIN gold.dim_products p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY units_sold DESC;
```

---

## 🚀 Future Work

- [ ] Power BI dashboard connected to the Gold layer
- [ ] Additional Gold aggregations (revenue by product line / year)
- [ ] Scheduled reloads (pgAgent / Windows Task Scheduler)
- [ ] Incremental loading strategy

---

## 👤 Author

**Ifeh** — Data Engineer in training

Built with ❤️ using PostgreSQL, VS Code, and a lot of `COALESCE`.

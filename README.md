# BI Developer Internship Portfolio — Srikanth

This repository consolidates the work completed during a Business Intelligence developer internship: SQL fundamentals, data warehouse design, SSIS ETL pipelines, SSRS reporting, and Power BI dashboards, built around a real-world **Australian property market analysis** (house values, rental values, crime, schools, and public transport across NSW, VIC, and SA).

Each numbered folder below is a self-contained project with its own README, source files, and (where applicable) documentation write-ups and screenshots produced at the time.

## Projects

| # | Project | What it covers |
|---|---------|-----------------|
| 01 | [SQL Query Fundamentals](01-sql-query-fundamentals) | Core T-SQL query exercise |
| 02 | [Power BI Report Basics](02-power-bi-report-basics) | First Power BI report, built from scratch |
| 03 | [AU Property — Data Collection & Consolidation](03-au-property-data-collection) | Sourcing and consolidating raw property, crime, school, rental, and transport datasets for NSW/VIC/SA |
| 04 | [Data Warehouse Design & SSIS Package](04-datawarehouse-design-ssis) | Star-schema dimensional model design + SSIS packages to load staging and warehouse tables |
| 05 | [SSRS Reporting](05-ssrs-reporting) | Paginated SSRS reports (crime, house value, rental value, schools, transport) on top of the warehouse |
| 06 | [Power BI — Existing Data Warehouse](06-powerbi-existing-datawarehouse) | Power BI dashboard built against a pre-existing data warehouse |
| 07 | [Power BI — Designed Data Warehouse](07-powerbi-designed-datawarehouse) | Power BI dashboard built against the custom-designed warehouse from project 04 |
| 08 | [BI Competition — Data Warehouse Modeling & Creation](08-competition-datawarehouse-modeling) | Dimensional modeling competition entry (bus matrix, schema design, SSIS ETL) |
| 09 | [BI Competition — Power BI Dashboard](09-competition-powerbi-dashboard) | Competition Power BI dashboard + SSRS report, plus bonus SQL/DAX practice exercises |

## Tech stack

SQL Server (T-SQL) · SSIS (SQL Server Integration Services) · SSRS (SQL Server Reporting Services) · Power BI (Power Query, DAX) · dimensional modeling (star schema, bus matrix)

## Shared data

Raw source datasets used across multiple projects are kept in one place to avoid duplication:

- [`shared-data/AUS_Property_RawDataSet`](shared-data/AUS_Property_RawDataSet) — suburb, crime, house value, rental value, school, and transport data for NSW/VIC/SA (used by projects 03–07)
- [`shared-data/Competition_RawDataSet`](shared-data/Competition_RawDataSet) — suburb/district/state, property median value, and NSW public schools data (used by projects 08–09)

## Notes

- Visual Studio project build artifacts (`.vs/`, `bin/`, `obj/`) and SSRS cached preview data (`.rdl.data`) are excluded via `.gitignore` — they're local build output, not source.
- SSIS/SSRS project files reference a local SQL Server instance (`SIRILENOVO\IC`) used for development; no credentials are stored in any file (all connections use Windows Integrated Security).

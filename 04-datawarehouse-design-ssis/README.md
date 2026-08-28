# Task 6 — Data Warehouse Design & SSIS Package

Designed a star-schema dimensional model for the AU property data and built SSIS packages to load it from staging into the warehouse.

**Contents:**
- `BI Advanced - Design Datawarehouse & build SSIS package.docx` — task brief
- `AUProperty_StarSchema_DesignDocument.docx` — dimensional model design (facts, dimensions, grain)
- `star_schema_diagram.png` — schema diagram
- `AUProperty_StarSchema_DDL_ETL.sql`, `SQL Scripts.sql` — DDL and ETL SQL
- `AUProperty_DataWarehouse_ImplementationSummary.docx` — implementation summary
- `Screenshot Documentation.docx` — build/result screenshots
- `AUProperty_ETL/` — SSIS project: staging load (`AUProperty_StagingLoad.dtsx`) and star-schema load (`AUProperty_StarSchemaLoad.dtsx`)

**Raw data:** see [`../shared-data/AUS_Property_RawDataSet`](../shared-data/AUS_Property_RawDataSet).

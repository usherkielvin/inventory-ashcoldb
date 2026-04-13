# Data warehouse layer (`dw` schema)

- Run `star_schema_ddl.sql` after operational DDL is stable.
- Populate dimensions and facts with an **ETL** script or SSIS package (assignment artifact): copy keys from `dbo.Products`, `dbo.Customers`, etc., and map dates to `dw.dim_date.DateKey` (`YYYYMMDD`).
- `olap_reporting_samples.sql` runs **OLAP-style** aggregates directly on `dbo` tables so you can demo **ROLLUP** before the fact table is loaded.

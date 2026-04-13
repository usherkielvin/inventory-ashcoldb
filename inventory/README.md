# `inventory/` — SQL blueprint execution order

Run these scripts **top to bottom** on a test instance. All objects use database **`AshcolInventory`** unless you change `00_create_database.sql`.

## DDL (schema)

| Order | File | Description |
|------:|------|--------------|
| 1 | `ddl/00_create_database.sql` | Creates database |
| 2 | `ddl/01_users_roles.sql` | Users, roles, user–role assignment |
| 3 | `ddl/02_catalog_suppliers.sql` | Categories, products, suppliers |
| 4 | `ddl/03_locations.sql` | Warehouse / store locations |
| 5 | `ddl/04_inventory_stock.sql` | Stock levels + movement ledger |
| 6 | `ddl/05_customers_sales.sql` | Customers, orders, lines, invoices |
| 7 | `ddl/06_purchasing.sql` | Purchase orders + lines |
| 8 | `ddl/07_indexes.sql` | Nonclustered indexes (clustered = PKs) |

## After DDL (run in this order)

| Step | Folder | Notes |
|------|--------|--------|
| 1 | `views/` | Before seeds if views are referenced by ETL (optional here) |
| 2 | `triggers/` | **Required before `seeds/`** — seed uses `StockMovements` → trigger fills `StockLevels` |
| 3 | `seeds/` | Reference data + sample rows |
| 4 | `transactions/` | Demos: `BEGIN TRAN`, isolation, deadlock write-up |
| 5 | `warehouse/` | Star schema + OLAP samples (optional second milestone) |

## Subfolders (empty placeholders)

- `modules/` — optional: one `.sql` or `.md` per *functional module* for your documentation bundle  
- `tests/` — ad hoc `SELECT` checks you used during grading (paste results into `docs/05-testing-procedures.md`)

## Soft delete

Core business tables include `IsDeleted` + `DeletedAt` + `DeletedBy`. Prefer **soft delete** in application code; triggers block physical `DELETE` where implemented.

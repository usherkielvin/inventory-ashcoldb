# 5. Testing procedures and results

If the database is not built yet or scripts failed, follow **[`07-ssms-database-setup-from-scratch.md`](07-ssms-database-setup-from-scratch.md)** first, then return here.

Record **your** run results (screenshots or pasted row counts) in this document for submission.

All build steps, verification queries, and demos below are performed in **SQL Server Management Studio (SSMS)** unless your instructor approves another tool. Use **Query** windows (`.sql` opened from this repo), **F5** to execute, and paste or attach **Messages** / **Results** as evidence.

## 5.1 Environment

| Item | Value |
|------|--------|
| SQL Server version | |
| Edition (Express/Developer/…) | |
| Tool | **SSMS** (required for this project) — version: |

## 5.2 Build verification

1. Execute `inventory/ddl/00_create_database.sql` through `07_indexes.sql` in order.
2. Execute all scripts in `inventory/views/`.
3. Execute all scripts in `inventory/triggers/`.
4. Execute `inventory/seeds/01_seed_reference_data.sql`.

**Expected checks**

```sql
SELECT COUNT(*) AS RoleCount FROM dbo.Roles;          -- 3
SELECT COUNT(*) AS UserCount FROM dbo.Users;          -- >= 1
SELECT COUNT(*) AS ProductCount FROM dbo.Products;    -- >= 1
SELECT COUNT(*) AS StockLevelRows FROM dbo.StockLevels; -- matches products at seeded location
```

## 5.3 Soft delete (Products)

```sql
DELETE FROM dbo.Products WHERE Sku = N'SKU-CAP-45';
SELECT * FROM dbo.vw_DeletedProducts WHERE Sku = N'SKU-CAP-45';
-- Restore:
UPDATE dbo.Products SET IsDeleted = 0, DeletedAt = NULL WHERE Sku = N'SKU-CAP-45';
```

## 5.4 Trigger / stock non-negative

Attempt a movement that exceeds on-hand quantity (adjust seed or insert a large negative `QuantityDelta`). **Expected:** error; no negative `StockLevels.QuantityOnHand`.

## 5.5 Views

```sql
SELECT TOP 10 * FROM dbo.vw_ActiveProductCatalog;
SELECT TOP 10 * FROM dbo.vw_SalesOrderSummary;
```

## 5.6 Transaction demo

Run `inventory/transactions/01_transaction_demo.sql`; capture **before/after** `ListPrice` for the SKU under test.

## 5.7 Deadlock lab

Follow `inventory/transactions/02_deadlock_lab.md`; attach **1205** error screenshot or Extended Events graph.

## 5.8 OLAP sample

Run `inventory/warehouse/olap_reporting_samples.sql` after inserting at least one confirmed sales order and lines.

## 5.9 Star schema

After `inventory/warehouse/star_schema_ddl.sql`, verify:

```sql
SELECT SCHEMA_NAME(schema_id), name FROM sys.tables WHERE schema_id = SCHEMA_ID('dw');
```

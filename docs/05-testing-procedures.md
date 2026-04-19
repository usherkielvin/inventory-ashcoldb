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

## 5.10 Demo transaction seed verification

Run `inventory/seeds/03_seed_demo_transactions.sql` in SSMS.  
The script ends with a verification `SELECT`; expected minimum row counts:

| Entity | Expected rows |
|--------|--------------|
| Customers | 5 |
| SalesOrders | 5 |
| SalesOrderLines | ≥ 10 |
| Invoices | 3 |
| PurchaseOrders | 3 |
| PurchaseOrderLines | 6 |
| StockMovements | ≥ 20 |

_Paste your actual results grid here._

## 5.11 Low-stock alert view

After executing `inventory/views/vw_LowStockAlert.sql`:

```sql
SELECT * FROM dbo.vw_LowStockAlert ORDER BY ShortfallQty DESC;
```

**Expected:** Products whose current `TotalOnHand` (summed across locations) is below `ReorderLevel` appear — typically refrigerant and coil SKUs after demo sales are applied.

_Paste Results grid here._

## 5.12 Purchase order summary view

After executing `inventory/views/vw_PurchaseOrderSummary.sql`:

```sql
SELECT * FROM dbo.vw_PurchaseOrderSummary ORDER BY OrderDate;
```

**Expected:** 3 rows — PO-2026-001 (RECEIVED, 100 %), PO-2026-002 (OPEN, 0 %), PO-2026-003 (PARTIAL, ~75 %).

_Paste Results grid here._

## 5.13 Invoice summary view

After executing `inventory/views/vw_InvoiceSummary.sql`:

```sql
SELECT * FROM dbo.vw_InvoiceSummary ORDER BY InvoiceDate;
```

**Expected:** 3 rows — INV-2026-001 (PAID), INV-2026-002 (PAID), INV-2026-003 (UNPAID).

Then mark INV-2026-003 as PAID and verify:

```sql
UPDATE dbo.Invoices SET PaymentStatus = N'PAID' WHERE InvoiceNumber = N'INV-2026-003';
SELECT InvoiceNumber, PaymentStatus FROM dbo.vw_InvoiceSummary;
```

_Paste before/after Results grids here._

## 5.14 Stock movement log view

After executing `inventory/views/vw_StockMovementLog.sql`:

```sql
SELECT TOP 20 * FROM dbo.vw_StockMovementLog ORDER BY MovementId DESC;
```

**Expected:** Recent movements show readable product names, location names, and the current `QuantityOnHand` snapshot.

_Paste Results grid here._

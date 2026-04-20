# 5. Testing procedures and results

> **Setup:** Database built with `inventory/tests/build_complete.sql`, seeded with `01_seed_reference_data.sql` and `03_seed_demo_transactions.sql`. All tests run via **`inventory/tests/run_all_tests.sql`** in SSMS 22.5.0.

---

## 5.1 Environment

| Item | Value |
|------|--------|
| SQL Server version | Microsoft SQL Server 2022 (RTM-GDR) (KB5084815) — 16.0.1175.1 (X64) |
| Edition | Express Edition (64-bit) |
| SSMS version | 22.5.0 (build 163.11709.299) |
| Database | `AshcolInventory` |
| Windows Auth | `SQL_USE_WINDOWS_AUTH=true` |
| Operating System | Windows 10.0.26200 |

---

## 5.2 Build verification

Scripts executed in order: `ddl/00` → `07`, all views, both triggers, `01_seed_reference_data.sql`, `03_seed_demo_transactions.sql`.

```sql
SELECT COUNT(*) AS RoleCount    FROM dbo.Roles;
SELECT COUNT(*) AS UserCount    FROM dbo.Users;
SELECT COUNT(*) AS ProductCount FROM dbo.Products WHERE IsDeleted = 0;
SELECT COUNT(*) AS StockLevelRows FROM dbo.StockLevels;
```

**Results:**

| Metric | Expected | Actual |
|--------|----------|--------|
| RoleCount | 3 | 3 |
| UserCount | ≥ 1 | 3 |
| ProductCount | ≥ 1 | 8 |
| StockLevelRows | ≥ 1 | 11 |

> **Object Explorer check:** `AshcolInventory` → Tables shows all expected tables (Products, Roles, SalesOrders, Invoices, PurchaseOrders, StockLevels, StockMovements, etc.). Views folder shows all 7 `dbo.vw_*` views. Triggers folder shows both triggers on their respective tables.

---

## 5.3 Soft delete (Products)

```sql
-- Before:
SELECT ProductId, Sku, IsDeleted, DeletedAt FROM dbo.Products WHERE Sku = N'SKU-CAP-45';

-- Soft-delete (INSTEAD OF trigger fires — converts DELETE to UPDATE):
DELETE FROM dbo.Products WHERE Sku = N'SKU-CAP-45';

-- Verify row is soft-deleted:
SELECT ProductId, Sku, DeletedAt FROM dbo.vw_DeletedProducts WHERE Sku = N'SKU-CAP-45';

-- Restore:
UPDATE dbo.Products SET IsDeleted = 0, DeletedAt = NULL WHERE Sku = N'SKU-CAP-45';

-- Confirm restoration:
SELECT ProductId, Sku, IsDeleted, DeletedAt FROM dbo.Products WHERE Sku = N'SKU-CAP-45';
```

**Before soft-delete:**

| ProductId | Sku | IsDeleted | DeletedAt |
|-----------|-----|-----------|-----------|
| 1 | SKU-CAP-45 | 0 | NULL |

**After DELETE — row appears in `vw_DeletedProducts` (trigger converted DELETE → UPDATE):**

| ProductId | Sku | DeletedAt |
|-----------|-----|-----------|
| 1 | SKU-CAP-45 | 2026-04-20 … |

**After RESTORE:**

| ProductId | Sku | IsDeleted | DeletedAt |
|-----------|-----|-----------|-----------|
| 1 | SKU-CAP-45 | 0 | NULL |

> **Trigger behaviour:** `dbo.trg_Products_BlockDelete` (INSTEAD OF DELETE) intercepted the physical DELETE and converted it to `UPDATE IsDeleted = 1, DeletedAt = SYSDATETIME()`. No FK constraint violation occurs because no row is physically deleted.

---

## 5.4 Trigger / stock non-negative

The test selects a product with positive stock, then tries to insert a `StockMovements` row whose `QuantityDelta` would make `StockLevels.QuantityOnHand` negative.

**Trigger:** `dbo.trg_StockMovements_AfterInsert_UpdateLevel` — fires AFTER INSERT on `StockMovements`; calls `RAISERROR` and rolls back if any `StockLevels.QuantityOnHand` goes below zero.

**SSMS Messages output:**
```
PASS: Trigger raised error 50001 — Stock level would go negative; transaction rolled back.
```

**Stock level — unchanged (before = after):**

| ProductId | LocationId | QtyBefore | QtyAfter |
|-----------|------------|-----------|----------|
| _(any product with stock)_ | _(MWH-01)_ | _(positive)_ | _(unchanged)_ |

---

## 5.5 Views

### `vw_ActiveProductCatalog` (TOP 10)

```sql
SELECT TOP 10 * FROM dbo.vw_ActiveProductCatalog ORDER BY Sku;
```

| ProductId | Sku | Name | UOM | UnitCost | ListPrice | ReorderLevel | CategoryName | SupplierName |
|-----------|-----|------|-----|----------|-----------|--------------|--------------|--------------|
| — | SKU-CAP-45 | Run Capacitor 45uF | PCS | 85.00 | 150.00 | 15 | HVAC Parts | Ashcol Preferred Vendor |
| — | SKU-COIL-E24 | Evaporator Coil 2-Ton | PCS | 3500.00 | 4800.00 | 5 | HVAC Parts | Ashcol Preferred Vendor |
| — | SKU-COILCLEAN | Coil Cleaner Spray 1L | CAN | 180.00 | 280.00 | 20 | Consumables | Cold Chain Supply Co. |
| — | SKU-FAN-12DC | DC Fan Motor 12V | PCS | 450.00 | 680.00 | 10 | HVAC Parts | Ashcol Preferred Vendor |
| — | SKU-FILTER-001 | AC Filter 1.5HP | PCS | 120.00 | 199.00 | 20 | HVAC Parts | Ashcol Preferred Vendor |
| — | SKU-R410A-5 | R-410A Refrigerant 5kg | KG | 2500.00 | 3200.00 | 5 | Refrigerants | Ashcol Preferred Vendor |
| — | SKU-TAPE-INS | Insulation Tape Roll | ROLL | 35.00 | 65.00 | 50 | Consumables | Cold Chain Supply Co. |
| — | SKU-THERMO-01 | Digital Thermostat Module | PCS | 220.00 | 380.00 | 15 | HVAC Parts | Ashcol Preferred Vendor |

*8 rows returned — all 8 non-deleted active products.*

### `vw_SalesOrderSummary` (TOP 10)

```sql
SELECT TOP 10 * FROM dbo.vw_SalesOrderSummary ORDER BY OrderDate DESC;
```

| SalesOrderId | OrderNumber | OrderDate | OrderStatus | CustomerName | FulfillmentLocation | LinesTotal |
|---|---|---|---|---|---|---|
| — | SO-2026-005 | 2026-04-18 | DRAFT | Reyes HVAC Services | Main Warehouse | 6,400.00 |
| — | SO-2026-004 | 2026-04-10 | SHIPPED | Tan HVAC Contractors | Main Warehouse | 13,840.00 |
| — | SO-2026-003 | 2026-04-08 | COMPLETED | Dela Paz Appliances | Cebu Branch Store | 4,952.00 |
| — | SO-2026-002 | 2026-04-05 | COMPLETED | Cruz Cold Solutions | Main Warehouse | 10,900.00 |
| — | SO-2026-001 | 2026-04-01 | CONFIRMED | Reyes HVAC Services | Main Warehouse | 2,740.00 |

---

## 5.6 Transaction demo

```sql
BEGIN TRAN;
    UPDATE dbo.Products SET ListPrice = ListPrice + 100 WHERE Sku = N'SKU-CAP-45';
ROLLBACK;
```

**Before UPDATE (PriceBefore):**

| Sku | PriceBefore |
|-----|-------------|
| SKU-CAP-45 | 150.0000 |

**Inside transaction — after UPDATE, before ROLLBACK (PriceInTran):**

| Sku | PriceInTran |
|-----|-------------|
| SKU-CAP-45 | 250.0000 |

**After ROLLBACK — price restored:**

| Sku | PriceAfterRollback |
|-----|--------------------|
| SKU-CAP-45 | 150.0000 |

**Messages panel:**
```
Transaction rolled back — price restored.
```

> The ROLLBACK fully undid the `UPDATE`; `ListPrice` returned to its original value of 150.00, confirming ACID atomicity.

---

## 5.7 Deadlock lab

*(Requires two separate SSMS query windows — follow `inventory/transactions/02_deadlock_lab.md`.)*

**Observation:** One session was chosen as the deadlock victim and received error 1205.

**Victim session — Messages panel:**
```
Msg 1205, Level 13, State 51, Line …
Transaction (Process ID XX) was deadlocked on lock resources with another process
and has been chosen as the deadlock victim. Rerun the transaction.
```

> SQL Server's deadlock monitor detected the circular wait between the two sessions and automatically terminated one to break the cycle. The surviving session completed successfully.

---

## 5.8 OLAP sample

```sql
-- Revenue by Category (CONFIRMED / SHIPPED / COMPLETED orders)
SELECT pc.Name AS Category, SUM(sol.Quantity * sol.UnitPrice) AS TotalRevenue, COUNT(DISTINCT so.SalesOrderId) AS OrderCount ...
```

### Revenue by Category

| Category | TotalRevenue | OrderCount |
|----------|-------------|------------|
| HVAC Parts | 18,172.00 | 4 |
| Refrigerants | 9,600.00 | 1 |
| Consumables | 4,660.00 | 2 |

> *(SO-2026-005 is DRAFT — excluded. Only CONFIRMED, SHIPPED, COMPLETED orders counted.)*

### Monthly Sales Trend

| YearMonth | Orders | Revenue |
|-----------|--------|---------|
| 2026-04 | 4 | 32,432.00 |

---

## 5.9 Star schema

```sql
SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS TableName
FROM sys.tables WHERE schema_id = SCHEMA_ID('dw') ORDER BY name;
```

**`dw` schema tables (5 rows):**

| SchemaName | TableName |
|------------|-----------|
| dw | dim_customer |
| dw | dim_date |
| dw | dim_location |
| dw | dim_product |
| dw | fact_sales_line |

---

## 5.10 Demo transaction seed verification

```sql
SELECT (SELECT COUNT(*) FROM dbo.Customers) AS Customers, ...
```

| Entity | Expected | Actual |
|--------|----------|--------|
| Customers | ≥ 5 | 5 |
| SalesOrders | ≥ 5 | 5 |
| SalesOrderLines | ≥ 10 | 10 |
| Invoices | ≥ 3 | 3 |
| PurchaseOrders | ≥ 3 | 3 |
| PurchaseOrderLines | ≥ 6 | 6 |
| StockMovements | ≥ 20 | 21 |

> All counts meet or exceed the expected minimums. Seed executed successfully after `build_complete.sql` installed the triggers that maintain `StockLevels`.

---

## 5.11 Low-stock alert view

```sql
SELECT * FROM dbo.vw_LowStockAlert ORDER BY ShortfallQty DESC;
```

**Expected:** Products whose total `QuantityOnHand` (summed across all locations) is below `ReorderLevel`.

| ProductId | Sku | ProductName | Category | Supplier | ReorderLevel | TotalOnHand | ShortfallQty |
|-----------|-----|-------------|----------|----------|-------------|------------|-------------|
| — | SKU-R410A-5 | R-410A Refrigerant 5kg | Refrigerants | Ashcol Preferred Vendor | 5 | 0 | 5 |

> R-410A stock was depleted by sales (SO-2026-002) and PO-2026-002 is still OPEN (not yet received). Reorder recommended.

---

## 5.12 Purchase order summary view

```sql
SELECT * FROM dbo.vw_PurchaseOrderSummary ORDER BY OrderDate;
```

| PoNumber | OrderDate | Status | Supplier | ShipToLocation | LineCount | TotalQtyOrdered | TotalQtyReceived | TotalOrderedValue | TotalReceivedValue | FulfilmentPct |
|---|---|---|---|---|---|---|---|---|---|---|
| PO-2026-001 | 2026-04-02 | RECEIVED | Ashcol Preferred Vendor | Main Warehouse | 2 | 80 | 80 | 8,650.00 | 8,650.00 | 100.00 |
| PO-2026-003 | 2026-04-12 | PARTIAL | Cold Chain Supply Co. | Main Warehouse | 2 | 280 | 200 | 21,400.00 | 18,600.00 | 71.43 |
| PO-2026-002 | 2026-04-15 | OPEN | Ashcol Preferred Vendor | Main Warehouse | 2 | 15 | 0 | 42,500.00 | 0.00 | 0.00 |

> PO-2026-001 fully received (100%). PO-2026-003 partially fulfilled (~71% by quantity). PO-2026-002 open, no goods received yet.

---

## 5.13 Invoice summary view

```sql
SELECT InvoiceNumber, PaymentStatus, TotalAmount, InvoiceDate
FROM dbo.vw_InvoiceSummary ORDER BY InvoiceDate;
```

**BEFORE marking INV-2026-003 as PAID:**

| InvoiceNumber | InvoiceDate | PaymentStatus | OrderNumber | CustomerName | SubTotal | TaxAmount | TotalAmount |
|---|---|---|---|---|---|---|---|
| INV-2026-001 | 2026-04-06 | PAID | SO-2026-002 | Cruz Cold Solutions | 10,900.00 | 1,308.00 | 12,208.00 |
| INV-2026-002 | 2026-04-09 | PAID | SO-2026-003 | Dela Paz Appliances | 4,952.00 | 594.24 | 5,546.24 |
| INV-2026-003 | 2026-04-11 | UNPAID | SO-2026-004 | Tan HVAC Contractors | 13,840.00 | 1,660.80 | 15,500.80 |

```sql
UPDATE dbo.Invoices SET PaymentStatus = N'PAID' WHERE InvoiceNumber = N'INV-2026-003';
```

**AFTER marking INV-2026-003 as PAID:**

| InvoiceNumber | InvoiceDate | PaymentStatus | OrderNumber | CustomerName | SubTotal | TaxAmount | TotalAmount |
|---|---|---|---|---|---|---|---|
| INV-2026-001 | 2026-04-06 | PAID | SO-2026-002 | Cruz Cold Solutions | 10,900.00 | 1,308.00 | 12,208.00 |
| INV-2026-002 | 2026-04-09 | PAID | SO-2026-003 | Dela Paz Appliances | 4,952.00 | 594.24 | 5,546.24 |
| INV-2026-003 | 2026-04-11 | PAID | SO-2026-004 | Tan HVAC Contractors | 13,840.00 | 1,660.80 | 15,500.80 |

> VAT rate: 12% of SubTotal (Philippine VAT). All 3 invoices now show PAID. Total billed revenue: **₱33,255.04**.

---

## 5.14 Stock movement log view

```sql
SELECT TOP 20 * FROM dbo.vw_StockMovementLog ORDER BY MovementId DESC;
```

**Most recent 20 movements — showing readable product names, location names, and current on-hand snapshot:**

| MovementId | CreatedAt | Sku | ProductName | LocationCode | LocationName | QuantityDelta | MovementType | ReferenceType | Note | CurrentOnHand |
|---|---|---|---|---|---|---|---|---|---|---|
| — | 2026-04-20 | SKU-COILCLEAN | Coil Cleaner Spray 1L | MWH-01 | Main Warehouse | +80 | RECEIPT | PURCHASE_ORDER | PO-2026-003 partial recv cleaner | 180 |
| — | 2026-04-20 | SKU-TAPE-INS | Insulation Tape Roll | MWH-01 | Main Warehouse | +120 | RECEIPT | PURCHASE_ORDER | PO-2026-003 partial recv tape | 200 |
| — | 2026-04-20 | SKU-CAP-45 | Run Capacitor 45uF | MWH-01 | Main Warehouse | +30 | RECEIPT | PURCHASE_ORDER | PO-2026-001 received | 30 |
| — | 2026-04-20 | SKU-FILTER-001 | AC Filter 1.5HP | MWH-01 | Main Warehouse | +50 | RECEIPT | PURCHASE_ORDER | PO-2026-001 received | 50 |
| _(…earlier rows…)_ | | | | | | | | | | |

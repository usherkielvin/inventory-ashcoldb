# 4. Database schema design

## Normalization

- **1NF:** Atomic columns; repeating groups avoided (line items in `SalesOrderLines` / `PurchaseOrderLines`).
- **2NF:** Line tables depend on full key (`SalesOrderId`, `LineNumber` unique).
- **3NF:** Non-key attributes depend only on the key (e.g. `Customers.Name` not duplicated on every order beyond `CustomerId` FK).

## Tables (operational `dbo`)

| Table | Purpose |
|-------|---------|
| `Roles`, `Users`, `UserRoles` | Authentication + RBAC |
| `ProductCategories` | Category hierarchy |
| `Suppliers` | Vendor master |
| `Products` | SKU catalog |
| `Locations` | Warehouses / stores / vans |
| `StockLevels` | Current quantity per location-product |
| `StockMovements` | Ledger (receipts, sales, adjustments) |
| `Customers` | Buyer master |
| `SalesOrders`, `SalesOrderLines` | Sales transactions |
| `Invoices` | Billing header linked to order |
| `PurchaseOrders`, `PurchaseOrderLines` | Replenishment |

## Integrity mechanisms

- **PK / FK / UNIQUE** as defined in `inventory/ddl/*.sql`.
- **CHECK** constraints for enums (`OrderStatus`, `MovementType`, non-negative prices/quantities).
- **Soft delete:** `IsDeleted`, `DeletedAt` (and triggers blocking hard delete where implemented).

## Clustered vs nonclustered

- **Clustered:** each table’s **primary key** (default SQL Server behavior).
- **Nonclustered:** `inventory/ddl/07_indexes.sql` (filters, joins, reporting paths).

## Scripts reference

- DDL: [`inventory/ddl/`](../inventory/ddl/)
- Views: [`inventory/views/`](../inventory/views/)
- Triggers: [`inventory/triggers/`](../inventory/triggers/)
- Warehouse: [`inventory/warehouse/`](../inventory/warehouse/)

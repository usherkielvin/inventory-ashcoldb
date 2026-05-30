# AshcolInventory Database Showcase

This document provides a visual flowchart of the transaction systems and simple queries to showcase data moving from **User Roles** down to **Stock Levels** in the **AshcolInventory** SQL Server database.

---

## 1. Full Transaction Flowchart

The diagram below outlines the relationship lifecycle of transactions within the RDBMS. It shows how user identities (RBAC) control the setup of the catalog, which drives purchasing, sales, and service job workflows, ultimately ledgered in stock movements.

```mermaid
graph TD
    %% Roles & Users (RBAC)
    subgraph Identity & Access (RBAC)
        Roles[Roles Table]
        Users[Users Table]
        UserRoles[UserRoles Table]
        Roles -->|M:N mapping| UserRoles
        Users -->|M:N mapping| UserRoles
    end

    %% Inventory Master Data
    subgraph Master Catalog
        ProductCategories[ProductCategories Table]
        Suppliers[Suppliers Table]
        Products[Products Table]
        Locations[Locations Table]
        ProductCategories -->|Classifies| Products
        Suppliers -->|Supplies| Products
    end

    %% Stock & Movement Control
    subgraph Stock Ledger
        StockLevels[StockLevels Table]
        StockMovements[StockMovements Table]
        Products -->|FK| StockLevels
        Locations -->|FK| StockLevels
        Products -->|FK| StockMovements
        Locations -->|FK| StockMovements
        StockMovements -->|Trigger maintains| StockLevels
    end

    %% Purchasing Workflows
    subgraph Purchasing & Replenishment
        PurchaseOrders[PurchaseOrders Table]
        PurchaseOrderLines[PurchaseOrderLines Table]
        PurchaseOrders -->|Contains| PurchaseOrderLines
        Suppliers -->|Receives PO| PurchaseOrders
        Products -->|Ordered Item| PurchaseOrderLines
        PurchaseOrders -->|Trigger/API| StockMovements : "Receipt"
    end

    %% Sales & Billing Workflows
    subgraph Sales & Invoicing
        Customers[Customers Table]
        SalesOrders[SalesOrders Table]
        SalesOrderLines[SalesOrderLines Table]
        Invoices[Invoices Table]
        Customers -->|Places| SalesOrders
        SalesOrders -->|Contains| SalesOrderLines
        SalesOrders -->|Billed as| Invoices
        Products -->|Sold Item| SalesOrderLines
        SalesOrders -->|Trigger/API| StockMovements : "Sale"
    end

    %% Service Workflows
    subgraph Service Operations
        ServiceJobs[ServiceJobs Table]
        ServiceJobMaterials[ServiceJobMaterials Table]
        ServiceJobs -->|Contains| ServiceJobMaterials
        Customers -->|Request service| ServiceJobs
        Products -->|Required material| ServiceJobMaterials
        ServiceJobs -->|Trigger/API| StockMovements : "Service Deduction"
    end
```

---

## 2. Showcase Queries (User Roles to Stock Levels)

Use these SQL queries in SSMS to query the database tables from identity setups to stock balances.

### Step 2.1: Identity and Access Control (Users & Roles)
This query shows who the registered users are and what roles are assigned to them in the system.

```sql
SELECT 
    u.FullName, 
    u.Email, 
    r.RoleName,
    ur.AssignedAt
FROM dbo.Users u
INNER JOIN dbo.UserRoles ur ON u.UserId = ur.UserId
INNER JOIN dbo.Roles r ON ur.RoleId = r.RoleId
WHERE u.IsDeleted = 0 AND r.IsDeleted = 0;
```

### Step 2.2: Master Catalog (Products & Categories)
This query maps out the products available in the inventory catalog alongside their respective categories and default suppliers.

```sql
SELECT 
    p.Sku, 
    p.Name AS ProductName, 
    c.Name AS CategoryName, 
    s.Name AS SupplierName,
    p.UnitOfMeasure,
    p.ListPrice
FROM dbo.Products p
INNER JOIN dbo.ProductCategories c ON p.CategoryId = c.CategoryId
LEFT JOIN dbo.Suppliers s ON p.SupplierId = s.SupplierId
WHERE p.IsDeleted = 0;
```

### Step 2.3: Storage Locations
This query shows the storage locations available for keeping inventory.

```sql
SELECT 
    LocationId, 
    Code AS LocationCode, 
    Name AS LocationName, 
    LocationType 
FROM dbo.Locations
WHERE IsActive = 1 AND IsDeleted = 0;
```

### Step 2.4: Current Stock Levels (Inventory Quantities)
This query displays the current quantity on hand for each product at each specific warehouse or service location.

```sql
SELECT 
    l.Code AS LocationCode, 
    l.Name AS LocationName, 
    p.Sku AS ProductSKU, 
    p.Name AS ProductName, 
    sl.QuantityOnHand,
    sl.UpdatedAt
FROM dbo.StockLevels sl
INNER JOIN dbo.Locations l ON sl.LocationId = l.LocationId
INNER JOIN dbo.Products p ON sl.ProductId = p.ProductId;
```

### Step 2.5: Stock Movements Audit Log
This ledger audit query shows who performed a stock movement transaction, how much stock changed, and the reason (Sales, Receipts, Initial stock adjustments, etc.).

```sql
SELECT 
    sm.CreatedAt, 
    p.Sku AS ProductSKU, 
    l.Code AS LocationCode, 
    sm.QuantityDelta, 
    sm.MovementType, 
    u.FullName AS RecordedBy,
    sm.Note
FROM dbo.StockMovements sm
INNER JOIN dbo.Products p ON sm.ProductId = p.ProductId
INNER JOIN dbo.Locations l ON sm.LocationId = l.LocationId
LEFT JOIN dbo.Users u ON sm.CreatedByUserId = u.UserId
ORDER BY sm.CreatedAt DESC;
```

---

## 3. Related File References

* **Database DDL Scripts**:
  * [01_users_roles.sql](file:///c:/Users/usher/Capstone/inventory-ashcoldb/inventory/ddl/01_users_roles.sql) - Schema for roles and users.
  * [02_catalog_suppliers.sql](file:///c:/Users/usher/Capstone/inventory-ashcoldb/inventory/ddl/02_catalog_suppliers.sql) - Schema for products, categories, and suppliers.
  * [03_locations.sql](file:///c:/Users/usher/Capstone/inventory-ashcoldb/inventory/ddl/03_locations.sql) - Schema for warehouses and locations.
  * [04_inventory_stock.sql](file:///c:/Users/usher/Capstone/inventory-ashcoldb/inventory/ddl/04_inventory_stock.sql) - Schema for stock levels and movement ledgers.
* **Full Documentation**:
  * [08-transaction-flows-and-queries.md](file:///c:/Users/usher/Capstone/inventory-ashcoldb/docs/08-transaction-flows-and-queries.md) - Full table schemas (DDL) and complex diagnostic queries.

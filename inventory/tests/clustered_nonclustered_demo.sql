-- ============================================================
-- ASHCOL INVENTORY — CLUSTERED vs NON-CLUSTERED INDEX DEMO
-- Shows existing indexes, explains the difference, and
-- demonstrates query performance with each index type.
-- ============================================================
USE AshcolInventory;
GO
SET NOCOUNT ON;

-- ============================================================
-- PART 1: VIEW ALL EXISTING INDEXES ON EACH TABLE
-- ============================================================
PRINT N'=== EXISTING INDEXES ===';

SELECT
    t.name                          AS TableName,
    i.name                          AS IndexName,
    i.type_desc                     AS IndexType,       -- CLUSTERED or NONCLUSTERED
    i.is_primary_key                AS IsPrimaryKey,
    i.is_unique                     AS IsUnique,
    STRING_AGG(c.name, ', ')
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexColumns
FROM sys.indexes i
JOIN sys.tables t       ON t.object_id = i.object_id
JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns c      ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE t.schema_id = SCHEMA_ID('dbo')
  AND i.type > 0   -- exclude heaps
  AND ic.is_included_column = 0
GROUP BY t.name, i.name, i.type_desc, i.is_primary_key, i.is_unique
ORDER BY t.name, i.type_desc DESC, i.name;
GO

-- ============================================================
-- PART 2: CLUSTERED INDEX QUERIES
-- A clustered index physically orders the table rows.
-- Each table can have only ONE clustered index.
-- Primary keys are clustered by default.
-- ============================================================
PRINT N'=== CLUSTERED INDEX QUERIES ===';

-- 2a. Lookup by PK (clustered) — Products.ProductId
--     SQL Server does a Clustered Index Seek (fastest)
SELECT ProductId, Sku, Name, ListPrice
FROM dbo.Products
WHERE ProductId = 1;

-- 2b. Range scan on PK — returns rows in physical storage order
SELECT ProductId, Sku, Name, ListPrice
FROM dbo.Products
WHERE ProductId BETWEEN 1 AND 10
ORDER BY ProductId;

-- 2c. Clustered index seek on SalesOrders by SalesOrderId
SELECT SalesOrderId, OrderNumber, OrderStatus, OrderDate
FROM dbo.SalesOrders
WHERE SalesOrderId BETWEEN 1 AND 5;

-- 2d. Clustered seek on StockMovements by MovementId
SELECT MovementId, ProductId, LocationId, QuantityDelta, MovementType, CreatedAt
FROM dbo.StockMovements
WHERE MovementId BETWEEN 1 AND 20;

-- 2e. Clustered seek on Invoices by InvoiceId
SELECT InvoiceId, InvoiceNumber, TotalAmount, PaymentStatus
FROM dbo.Invoices
WHERE InvoiceId BETWEEN 1 AND 5;
GO

-- ============================================================
-- PART 3: NON-CLUSTERED INDEX QUERIES
-- Non-clustered indexes are separate structures with pointers
-- back to the clustered row. A table can have many of them.
-- ============================================================
PRINT N'=== NON-CLUSTERED INDEX QUERIES ===';

-- 3a. IX_Products_Category_NotDeleted
--     Covers: CategoryId, IsDeleted  |  Includes: Sku, Name, ListPrice
--     Query: filter by category — uses nonclustered index seek
SELECT Sku, Name, ListPrice
FROM dbo.Products
WHERE CategoryId = 1
  AND IsDeleted = 0
ORDER BY Sku;

-- 3b. IX_StockMovements_Product_Location_Date
--     Covers: ProductId, LocationId, CreatedAt DESC
--     Query: movement history for a specific product+location
SELECT MovementId, QuantityDelta, MovementType, CreatedAt
FROM dbo.StockMovements
WHERE ProductId  = 1
  AND LocationId = 1
ORDER BY CreatedAt DESC;

-- 3c. IX_SalesOrders_Customer_Date (filtered: IsDeleted = 0)
--     Covers: CustomerId, OrderDate DESC  |  Includes: IsDeleted
--     Query: all orders for a customer, newest first
SELECT SalesOrderId, OrderNumber, OrderStatus, OrderDate
FROM dbo.SalesOrders
WHERE CustomerId = 1
  AND IsDeleted  = 0
ORDER BY OrderDate DESC;

-- 3d. IX_SalesOrderLines_Product
--     Covers: ProductId  |  Includes: SalesOrderId, Quantity, UnitPrice
--     Query: all lines containing a specific product
SELECT SalesOrderId, Quantity, UnitPrice, LineTotal
FROM dbo.SalesOrderLines
WHERE ProductId = 1;

-- 3e. IX_PurchaseOrders_Supplier_Status (filtered: IsDeleted = 0)
--     Covers: SupplierId, Status  |  Includes: IsDeleted
--     Query: all open POs for a supplier
SELECT PurchaseOrderId, PoNumber, OrderDate, Status
FROM dbo.PurchaseOrders
WHERE SupplierId = 1
  AND Status     = N'OPEN'
  AND IsDeleted  = 0;

-- 3f. UQ_Users_Email — unique nonclustered index used for login lookup
SELECT UserId, FullName, IsActive
FROM dbo.Users
WHERE Email = N'admin@ashcol.local';

-- 3g. UQ_Products_Sku — unique nonclustered index used for SKU lookup
SELECT ProductId, Name, UnitCost, ListPrice
FROM dbo.Products
WHERE Sku = N'WT-001';
GO

-- ============================================================
-- PART 4: SIDE-BY-SIDE COMPARISON
-- Same data, different access paths
-- ============================================================
PRINT N'=== COMPARISON: Clustered vs Non-Clustered ===';

-- Clustered: seek by PK (ProductId) — direct row access
SELECT ProductId, Sku, Name, CategoryId, ListPrice
FROM dbo.Products
WHERE ProductId = 5;

-- Non-Clustered: seek by Sku (UQ index) — index seek + key lookup
SELECT ProductId, Sku, Name, CategoryId, ListPrice
FROM dbo.Products
WHERE Sku = N'ST-001';

-- Non-Clustered covering: CategoryId filter — no key lookup needed
-- (Sku, Name, ListPrice are in the INCLUDE columns)
SELECT Sku, Name, ListPrice
FROM dbo.Products
WHERE CategoryId = 2
  AND IsDeleted  = 0;
GO

-- ============================================================
-- PART 5: CREATE DEMO NON-CLUSTERED INDEXES (new ones)
-- Shows how to add indexes for common query patterns
-- ============================================================
PRINT N'=== CREATING DEMO NON-CLUSTERED INDEXES ===';

-- Index to speed up invoice lookups by payment status
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Invoices_PaymentStatus' AND object_id = OBJECT_ID('dbo.Invoices'))
    CREATE NONCLUSTERED INDEX IX_Invoices_PaymentStatus
        ON dbo.Invoices (PaymentStatus, IsDeleted)
        INCLUDE (InvoiceNumber, TotalAmount, InvoiceDate)
        WHERE IsDeleted = 0;
GO

-- Index to speed up service job lookups by status
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ServiceJobs_Status' AND object_id = OBJECT_ID('dbo.ServiceJobs'))
    CREATE NONCLUSTERED INDEX IX_ServiceJobs_Status
        ON dbo.ServiceJobs (JobStatus, IsDeleted)
        INCLUDE (JobNumber, ScheduledDate, AssigneeName, CustomerId)
        WHERE IsDeleted = 0;
GO

-- Index to speed up customer lookups by email
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Customers_Email' AND object_id = OBJECT_ID('dbo.Customers'))
    CREATE NONCLUSTERED INDEX IX_Customers_Email
        ON dbo.Customers (Email)
        INCLUDE (Name, Phone)
        WHERE IsDeleted = 0;
GO

PRINT N'Demo indexes created.';
GO

-- ============================================================
-- PART 6: QUERIES USING THE NEW NON-CLUSTERED INDEXES
-- ============================================================

-- Unpaid invoices — uses IX_Invoices_PaymentStatus
SELECT InvoiceNumber, TotalAmount, InvoiceDate
FROM dbo.Invoices
WHERE PaymentStatus = N'UNPAID'
  AND IsDeleted = 0
ORDER BY InvoiceDate DESC;

-- Pending service jobs — uses IX_ServiceJobs_Status
SELECT JobNumber, ScheduledDate, AssigneeName
FROM dbo.ServiceJobs
WHERE JobStatus = N'PENDING'
  AND IsDeleted = 0
ORDER BY ScheduledDate;

-- Customer by email — uses IX_Customers_Email
SELECT Name, Phone
FROM dbo.Customers
WHERE Email = N'info@reyeshvac.example'
  AND IsDeleted = 0;
GO

-- ============================================================
-- PART 7: VIEW FINAL INDEX LIST (including new ones)
-- ============================================================
PRINT N'=== FINAL INDEX SUMMARY ===';

SELECT
    t.name          AS TableName,
    i.name          AS IndexName,
    i.type_desc     AS IndexType,
    i.is_primary_key AS IsPK,
    i.is_unique     AS IsUnique,
    i.has_filter    AS IsFiltered,
    i.filter_definition AS FilterCondition
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
WHERE t.schema_id = SCHEMA_ID('dbo')
  AND i.type > 0
ORDER BY t.name, i.type_desc DESC, i.name;
GO

PRINT N'Done.';
GO

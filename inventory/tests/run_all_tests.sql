-- =============================================================
-- AshcolInventory — Combined Test Runner (FIXED)
-- Course: RDBMS / Database System Project
-- =============================================================

USE AshcolInventory;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.2  BUILD VERIFICATION
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.2 Build Verification ===';

SELECT COUNT(*) AS RoleCount    FROM dbo.Roles;
SELECT COUNT(*) AS UserCount    FROM dbo.Users;
SELECT COUNT(*) AS ProductCount FROM dbo.Products    WHERE IsDeleted = 0;
SELECT COUNT(*) AS StockLevelRows FROM dbo.StockLevels;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.3  SOFT DELETE (Products)
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.3 Soft Delete — before ===';

-- Show current state before soft-delete
SELECT ProductId, Sku, IsDeleted, DeletedAt
FROM dbo.Products
WHERE Sku = N'SKU-CAP-45';

-- Trigger the soft-delete
DELETE FROM dbo.Products WHERE Sku = N'SKU-CAP-45';

PRINT '=== §5.3 Soft Delete — verify in vw_DeletedProducts ===';
SELECT ProductId, Sku, DeletedAt -- Removed IsDeleted as it is not in the view
FROM dbo.vw_DeletedProducts
WHERE Sku = N'SKU-CAP-45';

-- Restore
UPDATE dbo.Products
SET IsDeleted = 0, DeletedAt = NULL
WHERE Sku = N'SKU-CAP-45';

PRINT '=== §5.3 Soft Delete — after restore ===';
SELECT ProductId, Sku, IsDeleted, DeletedAt
FROM dbo.Products
WHERE Sku = N'SKU-CAP-45';
GO

-- ─────────────────────────────────────────────────────────────
-- §5.4  TRIGGER: STOCK NON-NEGATIVE
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.4 Trigger — stock non-negative (should error) ===';

-- Capture the first product/location combo with stock
DECLARE @testProductId  INT,
        @testLocationId INT,
        @currentQty     INT;

SELECT TOP 1
    @testProductId  = sl.ProductId,
    @testLocationId = sl.LocationId,
    @currentQty     = sl.QuantityOnHand
FROM dbo.StockLevels sl
WHERE sl.QuantityOnHand > 0
ORDER BY sl.QuantityOnHand ASC;

IF @testProductId IS NULL
BEGIN
    PRINT 'CRITICAL: No stock found. Run 03_seed_demo_transactions.sql FIRST!';
END
ELSE
BEGIN
    PRINT CONCAT('Testing on ProductId=', @testProductId,
                 ', LocationId=', @testLocationId,
                 ', CurrentQty=', @currentQty);

    BEGIN TRY
        INSERT INTO dbo.StockMovements
            (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
        VALUES
            (@testProductId, @testLocationId, -(@currentQty + 999),
             N'ADJUSTMENT', N'TEST', N'§5.4 non-negative trigger test', NULL);
        PRINT 'ERROR: Trigger did NOT fire — check trg_StockMovements_UpdateLevel';
    END TRY
    BEGIN CATCH
        PRINT CONCAT('PASS: Trigger raised error ', ERROR_NUMBER(), ' — ', ERROR_MESSAGE());
    END CATCH;
END;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.5  VIEWS: Active Product Catalog & Sales Order Summary
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.5 vw_ActiveProductCatalog (TOP 10) ===';
SELECT TOP 10 * FROM dbo.vw_ActiveProductCatalog ORDER BY Sku;

PRINT '=== §5.5 vw_SalesOrderSummary (TOP 10) ===';
SELECT TOP 10 * FROM dbo.vw_SalesOrderSummary ORDER BY OrderDate DESC;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.6  TRANSACTION DEMO
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.6 Transaction Demo ===';

DECLARE @demoSku    NVARCHAR(64),
        @priceBefore DECIMAL(18,4),
        @bumpAmount  DECIMAL(18,4) = 100.00;

SELECT TOP 1 @demoSku = Sku, @priceBefore = ListPrice
FROM dbo.Products WHERE IsDeleted = 0 ORDER BY Sku;

PRINT CONCAT('SKU under test: ', @demoSku);

BEGIN TRAN;
    UPDATE dbo.Products
    SET ListPrice = ListPrice + @bumpAmount
    WHERE Sku = @demoSku;

    SELECT Sku, ListPrice AS PriceInTran FROM dbo.Products WHERE Sku = @demoSku;
ROLLBACK;

SELECT Sku, ListPrice AS PriceAfterRollback FROM dbo.Products WHERE Sku = @demoSku;
PRINT 'Transaction rolled back — price restored.';
GO

-- ─────────────────────────────────────────────────────────────
-- §5.8  OLAP — Revenue by Category
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.8 OLAP — Revenue by Category ===';

SELECT
    pc.Name                              AS Category,
    SUM(sol.Quantity * sol.UnitPrice)    AS TotalRevenue,
    COUNT(DISTINCT so.SalesOrderId)      AS OrderCount
FROM dbo.SalesOrderLines  sol
JOIN dbo.Products          p   ON p.ProductId  = sol.ProductId
JOIN dbo.ProductCategories pc  ON pc.CategoryId = p.CategoryId
JOIN dbo.SalesOrders       so  ON so.SalesOrderId = sol.SalesOrderId
WHERE so.OrderStatus IN (N'CONFIRMED', N'SHIPPED', N'COMPLETED')
GROUP BY pc.Name
ORDER BY TotalRevenue DESC;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.9  STAR SCHEMA (dw schema tables)
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.9 Star Schema — dw tables ===';

SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS TableName
FROM sys.tables
WHERE schema_id = SCHEMA_ID('dw')
ORDER BY name;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.10 DEMO SEED ROW COUNTS
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.10 Demo Seed Row Counts ===';

SELECT
    (SELECT COUNT(*) FROM dbo.Customers)            AS Customers,
    (SELECT COUNT(*) FROM dbo.SalesOrders)          AS SalesOrders,
    (SELECT COUNT(*) FROM dbo.SalesOrderLines)      AS SalesOrderLines,
    (SELECT COUNT(*) FROM dbo.Invoices)             AS Invoices,
    (SELECT COUNT(*) FROM dbo.PurchaseOrders)       AS PurchaseOrders,
    (SELECT COUNT(*) FROM dbo.PurchaseOrderLines)   AS PurchaseOrderLines,
    (SELECT COUNT(*) FROM dbo.StockMovements)       AS StockMovements;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.11 vw_LowStockAlert
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.11 vw_LowStockAlert ===';
SELECT * FROM dbo.vw_LowStockAlert ORDER BY ShortfallQty DESC;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.12 PURCHASE ORDER SUMMARY VIEW
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.12 vw_PurchaseOrderSummary ===';
SELECT * FROM dbo.vw_PurchaseOrderSummary ORDER BY OrderDate;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.13 INVOICE SUMMARY VIEW
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.13 vw_InvoiceSummary ===';
SELECT InvoiceNumber, PaymentStatus, TotalAmount, InvoiceDate
FROM dbo.vw_InvoiceSummary
ORDER BY InvoiceDate;
GO

-- ─────────────────────────────────────────────────────────────
-- §5.14 STOCK MOVEMENT LOG VIEW
-- ─────────────────────────────────────────────────────────────
PRINT '=== §5.14 vw_StockMovementLog (TOP 20) ===';
SELECT TOP 20 * FROM dbo.vw_StockMovementLog ORDER BY MovementId DESC;
GO

PRINT '=== ALL TESTS COMPLETE ===';
GO

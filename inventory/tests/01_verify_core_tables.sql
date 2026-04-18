-- Run in SSMS after connecting to your instance. Confirms AshcolInventory and core tables exist.
-- If any line returns 0, run the matching DDL script from inventory/ddl/ before 07_indexes.sql.

USE AshcolInventory;
GO

SELECT DB_NAME() AS CurrentDatabase;
GO

SELECT
    SUM(CASE WHEN OBJECT_ID(N'dbo.Roles', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS Roles,
    SUM(CASE WHEN OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS Users,
    SUM(CASE WHEN OBJECT_ID(N'dbo.Products', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS Products,
    SUM(CASE WHEN OBJECT_ID(N'dbo.StockMovements', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS StockMovements,
    SUM(CASE WHEN OBJECT_ID(N'dbo.SalesOrders', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS SalesOrders,
    SUM(CASE WHEN OBJECT_ID(N'dbo.SalesOrderLines', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS SalesOrderLines,
    SUM(CASE WHEN OBJECT_ID(N'dbo.PurchaseOrders', N'U') IS NOT NULL THEN 1 ELSE 0 END) AS PurchaseOrders;
GO

-- Expect 1 in each column above. If not, re-run 01–06 in order and read the Messages pane for errors.

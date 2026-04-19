-- View: Low-stock alert
-- Shows products whose current stock (summed across ALL locations) has fallen below ReorderLevel.
-- Use as a replenishment dashboard trigger.

USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_LowStockAlert
AS
SELECT
    p.ProductId,
    p.Sku,
    p.Name                              AS ProductName,
    pc.Name                             AS Category,
    s.Name                              AS Supplier,
    p.ReorderLevel,
    COALESCE(stock.TotalOnHand, 0)      AS TotalOnHand,
    p.ReorderLevel - COALESCE(stock.TotalOnHand, 0) AS ShortfallQty
FROM dbo.Products AS p
LEFT JOIN dbo.ProductCategories AS pc ON pc.CategoryId = p.CategoryId
LEFT JOIN dbo.Suppliers         AS s  ON s.SupplierId  = p.SupplierId
LEFT JOIN (
    SELECT ProductId, SUM(QuantityOnHand) AS TotalOnHand
    FROM dbo.StockLevels
    GROUP BY ProductId
) AS stock ON stock.ProductId = p.ProductId
WHERE p.IsDeleted = 0
  AND COALESCE(stock.TotalOnHand, 0) < p.ReorderLevel;
GO

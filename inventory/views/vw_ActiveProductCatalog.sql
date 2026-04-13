USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_ActiveProductCatalog
AS
SELECT
    p.ProductId,
    p.Sku,
    p.Name,
    p.UnitOfMeasure,
    p.UnitCost,
    p.ListPrice,
    p.ReorderLevel,
    c.Name AS CategoryName,
    s.Name AS SupplierName
FROM dbo.Products p
INNER JOIN dbo.ProductCategories c ON c.CategoryId = p.CategoryId AND c.IsDeleted = 0
LEFT JOIN dbo.Suppliers s ON s.SupplierId = p.SupplierId AND s.IsDeleted = 0
WHERE p.IsDeleted = 0;
GO

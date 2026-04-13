-- Soft-deleted products (audit / restore workflow)
USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_DeletedProducts
AS
SELECT
    ProductId,
    Sku,
    Name,
    CategoryId,
    DeletedAt
FROM dbo.Products
WHERE IsDeleted = 1;
GO

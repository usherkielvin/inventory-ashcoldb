-- Run in SSMS when Roles / Products / view counts are all zero after you thought you seeded.
USE AshcolInventory;
GO

SELECT DB_NAME() AS CurrentDatabase;
GO

SELECT
    (SELECT COUNT(*) FROM dbo.Roles) AS Roles,
    (SELECT COUNT(*) FROM dbo.Users) AS Users,
    (SELECT COUNT(*) FROM dbo.ProductCategories) AS Categories,
    (SELECT COUNT(*) FROM dbo.Suppliers) AS Suppliers,
    (SELECT COUNT(*) FROM dbo.Locations) AS Locations,
    (SELECT COUNT(*) FROM dbo.Products) AS Products,
    (SELECT COUNT(*) FROM dbo.StockMovements) AS StockMovements;
GO

-- If Roles = 0, the full seed file was not applied in THIS database, or it failed before the MERGE.
-- Next: run inventory/seeds/01_seed_reference_data.sql (whole file, F5) and read Messages for [seed] lines and errors.

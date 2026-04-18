-- Seed: roles, admin user, categories, suppliers, locations, sample products
-- Requires: all DDL scripts executed. PasswordHash below is PLACEHOLDER — replace with real hash in production.

USE AshcolInventory;
GO

SET NOCOUNT ON;

PRINT N'[seed] Database: ' + DB_NAME() + N' — inserting reference data...';
GO

MERGE dbo.Roles AS T
USING (VALUES
    (N'Administrator', N'Full system access'),
    (N'Staff', N'Inventory and sales operations'),
    (N'Standard User', N'Customer / self-service profile')
) AS S(RoleName, Description)
ON T.RoleName = S.RoleName
WHEN NOT MATCHED THEN INSERT (RoleName, Description) VALUES (S.RoleName, S.Description);
GO

-- PRINT cannot use a subquery inside CAST; use a variable (avoids Msg 1046).
DECLARE @SeedRoleCount INT;
SELECT @SeedRoleCount = COUNT(*) FROM dbo.Roles;
PRINT N'[seed] Roles row count: ' + CAST(@SeedRoleCount AS NVARCHAR(20)) + N' (expect 3).';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'admin@ashcol.local')
BEGIN
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'admin@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'System Administrator');
END;
GO

DECLARE @AdminId BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @RAdmin INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'Administrator');

IF @AdminId IS NOT NULL AND @RAdmin IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @AdminId AND RoleId = @RAdmin)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@AdminId, @RAdmin);
GO

MERGE dbo.ProductCategories AS T
USING (VALUES
    (N'HVAC Parts', NULL),
    (N'Refrigerants', NULL),
    (N'Consumables', NULL)
) AS S(Name, ParentCategoryId)
ON T.Name = S.Name
WHEN NOT MATCHED THEN INSERT (Name, ParentCategoryId) VALUES (S.Name, S.ParentCategoryId);
GO

MERGE dbo.Suppliers AS T
USING (VALUES
    (N'Ashcol Preferred Vendor', N'Procurement', N'parts@example.com', N'+63-2-0000-0000', N'Metro Manila'),
    (N'Cold Chain Supply Co.', N'Sales', N'sales@coldchain.example', NULL, NULL)
) AS S(Name, ContactName, Email, Phone, AddressLine)
ON T.Name = S.Name
WHEN NOT MATCHED THEN INSERT (Name, ContactName, Email, Phone, AddressLine)
VALUES (S.Name, S.ContactName, S.Email, S.Phone, S.AddressLine);
GO

MERGE dbo.Locations AS T
USING (VALUES
    (N'MWH-01', N'Main Warehouse', N'WAREHOUSE', N'Quezon City'),
    (N'BRN-CRB', N'Cebu Branch Store', N'STORE', N'Cebu City'),
    (N'VAN-MNL-1', N'Manila Service Van 1', N'BRANCH_VAN', NULL)
) AS S(Code, Name, LocationType, AddressLine)
ON T.Code = S.Code
WHEN NOT MATCHED THEN INSERT (Code, Name, LocationType, AddressLine)
VALUES (S.Code, S.Name, S.LocationType, S.AddressLine);
GO

DECLARE @CatParts INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'HVAC Parts');
DECLARE @CatRef INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Refrigerants');
DECLARE @Sup1 INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor');

IF @CatParts IS NOT NULL AND @Sup1 IS NOT NULL
BEGIN
    MERGE dbo.Products AS T
    USING (VALUES
        (N'SKU-FILTER-001', N'AC Filter 1.5HP', @CatParts, N'PCS', 120.0000, 199.0000, 20, @Sup1),
        (N'SKU-CAP-45', N'Run Capacitor 45uF', @CatParts, N'PCS', 85.0000, 150.0000, 15, @Sup1)
    ) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    ON T.Sku = S.Sku
    WHEN NOT MATCHED THEN INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId);
END;

IF @CatRef IS NOT NULL
BEGIN
    MERGE dbo.Products AS T
    USING (VALUES
        (N'SKU-R410A-5', N'R-410A Refrigerant 5kg', @CatRef, N'KG', 2500.0000, 3200.0000, 5, @Sup1)
    ) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    ON T.Sku = S.Sku
    WHEN NOT MATCHED THEN INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId);
END;
GO

DECLARE @Admin BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @Loc2 INT = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');

-- Opening balances via StockMovements only (trigger dbo.trg_StockMovements_AfterInsert_UpdateLevel maintains StockLevels)
INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
SELECT p.ProductId, @Loc2, 50, N'INITIAL', N'ADJUSTMENT', NULL, N'Seed opening balance', @Admin
FROM dbo.Products p
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.StockMovements m
    WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @Loc2
);
GO

PRINT N'Seed complete.';
GO

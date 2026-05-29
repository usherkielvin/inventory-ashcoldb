-- ============================================================
-- ASHCOL INVENTORY SYSTEM — COMPLETE SEED (ALL-IN-ONE)
-- Paste this entire file into SSMS and press F5.
-- Safe to re-run: all inserts are guarded by IF NOT EXISTS / MERGE.
-- Requires: DDL scripts (00–08) and triggers already applied.
-- ============================================================
USE AshcolInventory;
GO
SET NOCOUNT ON;
PRINT N'========================================';
PRINT N' ASHCOL INVENTORY — FULL SEED START';
PRINT N'========================================';
GO

-- ============================================================
-- PART 1: ROLES, ADMIN USER, BASE CATEGORIES, SUPPLIERS, LOCATIONS
-- ============================================================
PRINT N'[1/6] Roles, users, base reference data...';
GO

MERGE dbo.Roles AS T
USING (VALUES
    (N'Administrator', N'Full system access'),
    (N'Staff',         N'Inventory and sales operations'),
    (N'Standard User', N'Customer / self-service profile')
) AS S(RoleName, Description)
ON T.RoleName = S.RoleName
WHEN NOT MATCHED THEN INSERT (RoleName, Description) VALUES (S.RoleName, S.Description);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'admin@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'admin@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'System Administrator');
GO

DECLARE @AdminId BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @RAdmin  INT    = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'Administrator');
IF @AdminId IS NOT NULL AND @RAdmin IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @AdminId AND RoleId = @RAdmin)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@AdminId, @RAdmin);
GO

-- Staff users
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'juan.delacruz@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'juan.delacruz@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Juan dela Cruz');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'maria.santos@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'maria.santos@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Maria Santos');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'carlo.reyes@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Carlo Reyes');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'ana.garcia@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Ana Garcia');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'ben.torres@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'ben.torres@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Benjamin Torres');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'rose.mendoza@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'rose.mendoza@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Rosemarie Mendoza');
GO

DECLARE @StaffRole INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'Staff');
DECLARE @Juan  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'juan.delacruz@ashcol.local');
DECLARE @Maria BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'maria.santos@ashcol.local');
DECLARE @Carlo BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local');
DECLARE @Ana   BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local');
DECLARE @Ben   BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'ben.torres@ashcol.local');
DECLARE @Rose  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'rose.mendoza@ashcol.local');
IF @Juan  IS NOT NULL AND @StaffRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId=@Juan  AND RoleId=@StaffRole) INSERT INTO dbo.UserRoles VALUES (@Juan,  @StaffRole, SYSDATETIME());
IF @Maria IS NOT NULL AND @StaffRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId=@Maria AND RoleId=@StaffRole) INSERT INTO dbo.UserRoles VALUES (@Maria, @StaffRole, SYSDATETIME());
IF @Carlo IS NOT NULL AND @StaffRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId=@Carlo AND RoleId=@StaffRole) INSERT INTO dbo.UserRoles VALUES (@Carlo, @StaffRole, SYSDATETIME());
IF @Ana   IS NOT NULL AND @StaffRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId=@Ana   AND RoleId=@StaffRole) INSERT INTO dbo.UserRoles VALUES (@Ana,   @StaffRole, SYSDATETIME());
IF @Ben   IS NOT NULL AND @StaffRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId=@Ben   AND RoleId=@StaffRole) INSERT INTO dbo.UserRoles VALUES (@Ben,   @StaffRole, SYSDATETIME());
IF @Rose  IS NOT NULL AND @StaffRole IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId=@Rose  AND RoleId=@StaffRole) INSERT INTO dbo.UserRoles VALUES (@Rose,  @StaffRole, SYSDATETIME());
GO

-- Resync identity counters
DBCC CHECKIDENT ('dbo.ProductCategories', RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Suppliers',         RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Products',          RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Locations',         RESEED) WITH NO_INFOMSGS;
GO

-- Categories
IF NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'HVAC Parts')             INSERT INTO dbo.ProductCategories (Name, ParentCategoryId) VALUES (N'HVAC Parts', NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Consumables')             INSERT INTO dbo.ProductCategories (Name, ParentCategoryId) VALUES (N'Consumables', NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Air Conditioners')        INSERT INTO dbo.ProductCategories (Name, ParentCategoryId) VALUES (N'Air Conditioners', NULL);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Aircon Parts & Accessories') INSERT INTO dbo.ProductCategories (Name, ParentCategoryId) VALUES (N'Aircon Parts & Accessories', NULL);
GO
IF NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Window Type')
    INSERT INTO dbo.ProductCategories (Name, ParentCategoryId) VALUES (N'Window Ty
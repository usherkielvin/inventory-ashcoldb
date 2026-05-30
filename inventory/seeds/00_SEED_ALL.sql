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
-- PART 1: ROLES, USERS, BASE CATEGORIES, SUPPLIERS, LOCATIONS
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

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'juan.delacruz@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'juan.delacruz@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Juan dela Cruz');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'maria.santos@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'maria.santos@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Maria Santos');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'carlo.reyes@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Carlo Reyes');
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName) VALUES (N'ana.garcia@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Ana Garcia');

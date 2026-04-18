-- Run ONLY if dbo.Roles is empty but the table exists (DDL already applied).
-- Then run 01_seed_reference_data.sql again from the top (idempotent MERGE for the rest).

USE AshcolInventory;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM dbo.Roles)
BEGIN
    PRINT N'[repair] dbo.Roles already has rows — skip. Run 01_seed_reference_data.sql for the rest.';
    RETURN;
END;

INSERT INTO dbo.Roles (RoleName, Description)
VALUES
    (N'Administrator', N'Full system access'),
    (N'Staff', N'Inventory and sales operations'),
    (N'Standard User', N'Customer / self-service profile');

DECLARE @RepairRoleCount INT;
SELECT @RepairRoleCount = COUNT(*) FROM dbo.Roles;
PRINT N'[repair] Inserted 3 roles. Role count = ' + CAST(@RepairRoleCount AS NVARCHAR(20));
PRINT N'[repair] Now run inventory/seeds/01_seed_reference_data.sql from the beginning (F5 entire file).';
GO

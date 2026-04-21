-- ============================================================
-- Seed: Demo Service Jobs
-- Requires:
--   - 08_service_jobs DDL applied
--   - Customers, Locations, Products, Users seeded
-- ============================================================
USE AshcolInventory;
GO

SET NOCOUNT ON;
PRINT N'[seed] Inserting demo Service Jobs...';
GO

-- ── Pick reference IDs ────────────────────────────────────
DECLARE
    @Cust1  INT    = (SELECT TOP 1 CustomerId FROM dbo.Customers WHERE IsDeleted = 0 ORDER BY CustomerId),
    @Cust2  INT    = (SELECT TOP 1 CustomerId FROM dbo.Customers WHERE IsDeleted = 0 ORDER BY CustomerId DESC),
    @Loc1   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    -- Products
    @ST002  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),  -- LG Split 1HP
    @RF002  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),  -- R410A Refrigerant
    @IM001  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-001'),  -- Copper Tube
    @IM002  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-002'),  -- Insulation Foam
    @IM003  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-003'),  -- Drain Hose
    @IM004  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004'),  -- Circuit Breaker
    @WT001  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-001'),  -- LG Window 1HP
    @CP001  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-001');  -- Panasonic Compressor

-- ── Job 1: PENDING — Split AC installation ────────────────
IF @Cust1 IS NOT NULL AND @Loc1 IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-001')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-2026-001', @Cust1, @Loc1, @Admin, N'Juan dela Cruz',
         N'PENDING', '2026-04-25 09:00:00', N'New split-type AC installation at customer premises');

    DECLARE @Job1 BIGINT = SCOPE_IDENTITY();

    IF @ST002 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job1, 1, @ST002, 1);
    IF @RF002 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job1, 2, @RF002, 1);
    IF @IM001 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job1, 3, @IM001, 4);
    IF @IM002 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job1, 4, @IM002, 1);
    IF @IM003 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job1, 5, @IM003, 1);
    IF @IM004 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job1, 6, @IM004, 1);

    PRINT N'[seed] Job SJ-2026-001 (PENDING) inserted.';
END;
GO

-- ── Job 2: IN_PROGRESS — Window AC repair + compressor ───
DECLARE
    @Cust2  INT    = (SELECT TOP 1 CustomerId FROM dbo.Customers WHERE IsDeleted = 0 ORDER BY CustomerId DESC),
    @Loc1   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    @WT001  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-001'),
    @CP001  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-001'),
    @RF001  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-001');

IF @Cust2 IS NOT NULL AND @Loc1 IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-002')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-2026-002', @Cust2, @Loc1, @Admin, N'Maria Santos',
         N'IN_PROGRESS', '2026-04-21 08:00:00', N'Window type AC unit repair — compressor replacement');

    DECLARE @Job2 BIGINT = SCOPE_IDENTITY();

    IF @CP001 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job2, 1, @CP001, 1);
    IF @RF001 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@Job2, 2, @RF001, 1);

    PRINT N'[seed] Job SJ-2026-002 (IN_PROGRESS) inserted.';
END;
GO

PRINT N'[seed] Service Jobs seed complete.';
GO

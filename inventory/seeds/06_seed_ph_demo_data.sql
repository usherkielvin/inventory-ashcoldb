-- ============================================================
-- Seed: Philippines Demo Data (Presentation-Ready)
-- Adds more customers, users, sales orders, invoices,
-- purchase orders, and service jobs with PH context.
--
-- Run AFTER: 01 through 05 seeds are applied.
-- Safe to re-run: all inserts guarded by IF NOT EXISTS / MERGE.
-- ============================================================
USE AshcolInventory;
GO

SET NOCOUNT ON;
PRINT N'[seed-06] Inserting Philippines demo data...';
GO

-- ============================================================
-- 1. Additional Staff & Manager Users
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'carlo.reyes@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Carlo Reyes');

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'ana.garcia@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Ana Garcia');

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'ben.torres@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'ben.torres@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Benjamin Torres');

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'rose.mendoza@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'rose.mendoza@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Rosemarie Mendoza');
GO

DECLARE @StaffRole INT  = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'Staff');
DECLARE @Carlo  BIGINT  = (SELECT UserId FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local');
DECLARE @Ana    BIGINT  = (SELECT UserId FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local');
DECLARE @Ben    BIGINT  = (SELECT UserId FROM dbo.Users WHERE Email = N'ben.torres@ashcol.local');
DECLARE @Rose   BIGINT  = (SELECT UserId FROM dbo.Users WHERE Email = N'rose.mendoza@ashcol.local');

IF @Carlo IS NOT NULL AND @StaffRole IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @Carlo AND RoleId = @StaffRole)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@Carlo, @StaffRole);

IF @Ana IS NOT NULL AND @StaffRole IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @Ana AND RoleId = @StaffRole)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@Ana, @StaffRole);

IF @Ben IS NOT NULL AND @StaffRole IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @Ben AND RoleId = @StaffRole)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@Ben, @StaffRole);

IF @Rose IS NOT NULL AND @StaffRole IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @Rose AND RoleId = @StaffRole)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@Rose, @StaffRole);
GO

-- ============================================================
-- 2. More Philippine Customers (businesses & individuals)
-- ============================================================
MERGE dbo.Customers AS T
USING (VALUES
    (N'Villanueva Aircon Services',     N'villanueva.aircon@gmail.com',     N'+63-917-201-3344', N'Caloocan City, Metro Manila'),
    (N'Bautista Property Management',   N'bautista.prop@outlook.com',       N'+63-918-402-5566', N'Pasig City, Metro Manila'),
    (N'Gonzales Commercial Center',     N'gonzales.cc@yahoo.com',           N'+63-919-603-7788', N'Davao City, Davao del Sur'),
    (N'Aquino Refrigeration Works',     N'aquino.refrig@gmail.com',         N'+63-920-804-9900', N'Iloilo City, Iloilo'),
    (N'Soriano Hotel & Resorts',        N'procurement@sorianohotels.ph',    N'+63-921-005-1122', N'Boracay, Aklan'),
    (N'Navarro Construction Corp.',     N'navarro.const@gmail.com',         N'+63-922-206-3344', N'Cagayan de Oro, Misamis Oriental'),
    (N'Flores BPO Solutions Inc.',      N'admin@floresbpo.ph',              N'+63-923-407-5566', N'Eastwood, Quezon City'),
    (N'Castillo Supermart',             N'castillo.supermart@gmail.com',    N'+63-924-608-7788', N'Batangas City, Batangas'),
    (N'Ramos Medical Clinic',           N'ramos.clinic@gmail.com',          N'+63-925-809-9900', N'Angeles City, Pampanga'),
    (N'Dizon School of Technology',     N'dizon.school@edu.ph',             N'+63-926-010-1122', N'Lipa City, Batangas')
) AS S(Name, Email, Phone, AddressLine)
ON T.Email = S.Email
WHEN NOT MATCHED THEN
    INSERT (Name, Email, Phone, AddressLine)
    VALUES (S.Name, S.Email, S.Phone, S.AddressLine);
GO

PRINT N'[seed-06] Customers upserted.';
GO

-- ============================================================
-- 3. Additional Locations (branches across PH)
-- ============================================================
MERGE dbo.Locations AS T
USING (VALUES
    (N'BRN-DAV', N'Davao Branch Store',         N'STORE',      N'Davao City, Davao del Sur'),
    (N'BRN-ILO', N'Iloilo Branch Store',         N'STORE',      N'Iloilo City, Iloilo'),
    (N'VAN-CEB-1', N'Cebu Service Van 1',        N'BRANCH_VAN', NULL),
    (N'VAN-DAV-1', N'Davao Service Van 1',       N'BRANCH_VAN', NULL),
    (N'WH-CEB',  N'Cebu Sub-Warehouse',          N'WAREHOUSE',  N'Mandaue City, Cebu')
) AS S(Code, Name, LocationType, AddressLine)
ON T.Code = S.Code
WHEN NOT MATCHED THEN
    INSERT (Code, Name, LocationType, AddressLine)
    VALUES (S.Code, S.Name, S.LocationType, S.AddressLine);
GO

PRINT N'[seed-06] Locations upserted.';
GO

-- ============================================================
-- 4. Opening stock for new locations
-- ============================================================
DECLARE
    @Admin   BIGINT = (SELECT UserId    FROM dbo.Users     WHERE Email = N'admin@ashcol.local'),
    @LocDAV  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code  = N'BRN-DAV'),
    @LocILO  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code  = N'BRN-ILO'),
    @LocCEBW INT    = (SELECT LocationId FROM dbo.Locations WHERE Code  = N'WH-CEB');

-- Davao branch: 5 units of each AC type + consumables
INSERT INTO dbo.StockMovements
    (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
SELECT p.ProductId, @LocDAV, 5, N'INITIAL', N'ADJUSTMENT',
       N'Opening balance — Davao branch', @Admin
FROM dbo.Products p
WHERE p.Sku IN (N'WT-001',N'WT-002',N'ST-001',N'ST-002',N'ST-003',N'RF-002',N'IM-001',N'IM-002',N'IM-003',N'IM-004')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.StockMovements m
      WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @LocDAV
  );

-- Iloilo branch: 5 units of each AC type + consumables
INSERT INTO dbo.StockMovements
    (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
SELECT p.ProductId, @LocILO, 5, N'INITIAL', N'ADJUSTMENT',
       N'Opening balance — Iloilo branch', @Admin
FROM dbo.Products p
WHERE p.Sku IN (N'WT-001',N'WT-003',N'ST-001',N'ST-004',N'RF-001',N'RF-003',N'IM-001',N'IM-002',N'IM-003',N'IM-004')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.StockMovements m
      WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @LocILO
  );

-- Cebu sub-warehouse: 8 units of popular items
INSERT INTO dbo.StockMovements
    (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
SELECT p.ProductId, @LocCEBW, 8, N'INITIAL', N'ADJUSTMENT',
       N'Opening balance — Cebu sub-warehouse', @Admin
FROM dbo.Products p
WHERE p.Sku IN (N'ST-001',N'ST-002',N'ST-005',N'FM-001',N'RF-002',N'CP-001',N'CP-002',N'IM-001',N'IM-004')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.StockMovements m
      WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @LocCEBW
  );
GO

PRINT N'[seed-06] Branch opening stock inserted.';
GO

-- ============================================================
-- 5. Sales Orders (10 more across different statuses & locations)
-- ============================================================
DECLARE
    @LocWH   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @LocCEB  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB'),
    @LocDAV  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-DAV'),
    @LocILO  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-ILO'),
    @Carlo   BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local'),
    @Ana     BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local'),
    @Ben     BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'ben.torres@ashcol.local'),
    @Rose    BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'rose.mendoza@ashcol.local'),
    @Admin   BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    @CustVil INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'villanueva.aircon@gmail.com'),
    @CustBau INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'bautista.prop@outlook.com'),
    @CustGon INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'gonzales.cc@yahoo.com'),
    @CustAqu INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'aquino.refrig@gmail.com'),
    @CustSor INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'procurement@sorianohotels.ph'),
    @CustNav INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'navarro.const@gmail.com'),
    @CustFlo INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'admin@floresbpo.ph'),
    @CustCas INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'castillo.supermart@gmail.com'),
    @CustRam INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'ramos.clinic@gmail.com'),
    @CustDiz INT    = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'dizon.school@edu.ph');

-- SO-006: COMPLETED — Villanueva Aircon (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-006')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-006', @CustVil, N'COMPLETED', '2026-04-20 09:00:00', @LocWH, @Carlo);

-- SO-007: COMPLETED — Bautista Property (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-007')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-007', @CustBau, N'COMPLETED', '2026-04-22 10:00:00', @LocWH, @Ana);

-- SO-008: SHIPPED — Gonzales Commercial (Davao branch)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-008')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-008', @CustGon, N'SHIPPED', '2026-04-24 08:30:00', @LocDAV, @Ben);

-- SO-009: CONFIRMED — Aquino Refrigeration (Iloilo branch)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-009')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-009', @CustAqu, N'CONFIRMED', '2026-04-26 11:00:00', @LocILO, @Rose);

-- SO-010: COMPLETED — Soriano Hotel (Main WH — bulk floor mounted)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-010')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-010', @CustSor, N'COMPLETED', '2026-04-28 09:00:00', @LocWH, @Admin);

-- SO-011: COMPLETED — Navarro Construction (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-011')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-011', @CustNav, N'COMPLETED', '2026-05-02 08:00:00', @LocWH, @Carlo);

-- SO-012: SHIPPED — Flores BPO (Cebu branch)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-012')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-012', @CustFlo, N'SHIPPED', '2026-05-05 10:00:00', @LocCEB, @Ana);

-- SO-013: CONFIRMED — Castillo Supermart (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-013')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-013', @CustCas, N'CONFIRMED', '2026-05-08 13:00:00', @LocWH, @Ben);

-- SO-014: DRAFT — Ramos Medical Clinic (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-014')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-014', @CustRam, N'DRAFT', '2026-05-10 14:00:00', @LocWH, @Rose);

-- SO-015: DRAFT — Dizon School (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-015')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-015', @CustDiz, N'DRAFT', '2026-05-12 09:30:00', @LocWH, @Carlo);
GO

PRINT N'[seed-06] Sales Orders inserted.';
GO

-- ============================================================
-- 6. Sales Order Lines
-- ============================================================
DECLARE
    @SO6  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-006'),
    @SO7  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-007'),
    @SO8  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-008'),
    @SO9  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-009'),
    @SO10 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-010'),
    @SO11 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-011'),
    @SO12 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-012'),
    @SO13 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-013'),
    @SO14 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-014'),
    @SO15 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-015'),
    -- Products
    @PWT1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-001'),
    @PWT2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-002'),
    @PWT3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-003'),
    @PST1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-001'),
    @PST2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),
    @PST3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-003'),
    @PST4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-004'),
    @PST5 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-005'),
    @PFM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-001'),
    @PFM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-002'),
    @PPT1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'PT-001'),
    @PRF1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-001'),
    @PRF2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),
    @PRF3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-003'),
    @PIM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-001'),
    @PIM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-002'),
    @PIM3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-003'),
    @PIM4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004'),
    @PCP1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-001'),
    @PCP2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-002');

-- SO-006: Villanueva — 3x Split AC ST-001 + 6x IM-001 + 3x IM-004
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO6 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO6, 1, @PST1, 3, 32000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO6 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO6, 2, @PIM1, 6, 350.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO6 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO6, 3, @PIM4, 3, 900.0000);

-- SO-007: Bautista — 5x WT-002 + 2x RF-002 + 5x IM-002
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO7 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO7, 1, @PWT2, 5, 22000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO7 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO7, 2, @PRF2, 2, 6200.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO7 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO7, 3, @PIM2, 5, 120.0000);

-- SO-008: Gonzales — 2x ST-004 + 1x RF-001 + 4x IM-003
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO8 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO8, 1, @PST4, 2, 34000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO8 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO8, 2, @PRF1, 1, 5500.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO8 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO8, 3, @PIM3, 4, 150.0000);

-- SO-009: Aquino — 1x ST-005 + 2x RF-003 + 3x IM-001
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO9 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO9, 1, @PST5, 1, 42000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO9 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO9, 2, @PRF3, 2, 6800.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO9 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO9, 3, @PIM1, 3, 350.0000);

-- SO-010: Soriano Hotel — 4x FM-001 + 2x FM-002 + 6x RF-002 + 10x IM-001 + 6x IM-004
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO10 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO10, 1, @PFM1, 4, 85000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO10 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO10, 2, @PFM2, 2, 78000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO10 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO10, 3, @PRF2, 6, 6200.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO10 AND LineNumber = 4)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO10, 4, @PIM1, 10, 350.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO10 AND LineNumber = 5)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO10, 5, @PIM4, 6, 900.0000);

-- SO-011: Navarro — 3x ST-003 + 3x IM-001 + 3x IM-002 + 3x IM-004
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO11 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO11, 1, @PST3, 3, 36500.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO11 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO11, 2, @PIM1, 3, 350.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO11 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO11, 3, @PIM2, 3, 120.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO11 AND LineNumber = 4)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO11, 4, @PIM4, 3, 900.0000);

-- SO-012: Flores BPO — 4x ST-002 + 4x IM-001 + 4x IM-004
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO12 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO12, 1, @PST2, 4, 35000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO12 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO12, 2, @PIM1, 4, 350.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO12 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO12, 3, @PIM4, 4, 900.0000);

-- SO-013: Castillo Supermart — 6x WT-003 + 2x CP-001 + 3x RF-001
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO13 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO13, 1, @PWT3, 6, 20500.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO13 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO13, 2, @PCP1, 2, 6500.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO13 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO13, 3, @PRF1, 3, 5500.0000);

-- SO-014: Ramos Clinic (DRAFT) — 2x ST-001 + 2x IM-001
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO14 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO14, 1, @PST1, 2, 32000.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO14 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO14, 2, @PIM1, 2, 350.0000);

-- SO-015: Dizon School (DRAFT) — 8x WT-001 + 8x IM-002 + 8x IM-003
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO15 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO15, 1, @PWT1, 8, 18500.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO15 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO15, 2, @PIM2, 8, 120.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO15 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO15, 3, @PIM3, 8, 150.0000);
GO

PRINT N'[seed-06] Sales Order Lines inserted.';
GO

-- ============================================================
-- 7. Stock Movements for SALE (completed/shipped orders only)
-- ============================================================
DECLARE
    @Admin   BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    @LocWH   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @LocCEB  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB'),
    @LocDAV  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-DAV'),
    @LocILO  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-ILO'),
    @SO6  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-006'),
    @SO7  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-007'),
    @SO8  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-008'),
    @SO10 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-010'),
    @SO11 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-011'),
    @SO12 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-012'),
    @PST1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-001'),
    @PST3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-003'),
    @PST4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-004'),
    @PST2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),
    @PWT2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-002'),
    @PFM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-001'),
    @PFM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-002'),
    @PRF1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-001'),
    @PRF2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),
    @PIM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-001'),
    @PIM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-002'),
    @PIM3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-003'),
    @PIM4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004');

-- SO-006 outbound (COMPLETED — Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO6 AND ProductId=@PST1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST1, @LocWH, -3, N'SALE', N'SALES_ORDER', @SO6, N'SO-2026-006 dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO6 AND ProductId=@PIM1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM1, @LocWH, -6, N'SALE', N'SALES_ORDER', @SO6, N'SO-2026-006 dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO6 AND ProductId=@PIM4)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM4, @LocWH, -3, N'SALE', N'SALES_ORDER', @SO6, N'SO-2026-006 dispatch', @Admin);

-- SO-007 outbound (COMPLETED — Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO7 AND ProductId=@PWT2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PWT2, @LocWH, -5, N'SALE', N'SALES_ORDER', @SO7, N'SO-2026-007 dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO7 AND ProductId=@PRF2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PRF2, @LocWH, -2, N'SALE', N'SALES_ORDER', @SO7, N'SO-2026-007 dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO7 AND ProductId=@PIM2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM2, @LocWH, -5, N'SALE', N'SALES_ORDER', @SO7, N'SO-2026-007 dispatch', @Admin);

-- SO-008 outbound (SHIPPED — Davao branch)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO8 AND ProductId=@PST4)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST4, @LocDAV, -2, N'SALE', N'SALES_ORDER', @SO8, N'SO-2026-008 Davao dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO8 AND ProductId=@PRF1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PRF1, @LocDAV, -1, N'SALE', N'SALES_ORDER', @SO8, N'SO-2026-008 Davao dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO8 AND ProductId=@PIM3)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM3, @LocDAV, -4, N'SALE', N'SALES_ORDER', @SO8, N'SO-2026-008 Davao dispatch', @Admin);

-- SO-010 outbound (COMPLETED — Main WH, hotel bulk)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO10 AND ProductId=@PFM1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFM1, @LocWH, -4, N'SALE', N'SALES_ORDER', @SO10, N'SO-2026-010 Soriano Hotel dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO10 AND ProductId=@PFM2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFM2, @LocWH, -2, N'SALE', N'SALES_ORDER', @SO10, N'SO-2026-010 Soriano Hotel dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO10 AND ProductId=@PRF2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PRF2, @LocWH, -6, N'SALE', N'SALES_ORDER', @SO10, N'SO-2026-010 Soriano Hotel dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO10 AND ProductId=@PIM1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM1, @LocWH, -10, N'SALE', N'SALES_ORDER', @SO10, N'SO-2026-010 Soriano Hotel dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO10 AND ProductId=@PIM4)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM4, @LocWH, -6, N'SALE', N'SALES_ORDER', @SO10, N'SO-2026-010 Soriano Hotel dispatch', @Admin);

-- SO-011 outbound (COMPLETED — Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO11 AND ProductId=@PST3)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST3, @LocWH, -3, N'SALE', N'SALES_ORDER', @SO11, N'SO-2026-011 Navarro dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO11 AND ProductId=@PIM1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM1, @LocWH, -3, N'SALE', N'SALES_ORDER', @SO11, N'SO-2026-011 Navarro dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO11 AND ProductId=@PIM4)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM4, @LocWH, -3, N'SALE', N'SALES_ORDER', @SO11, N'SO-2026-011 Navarro dispatch', @Admin);

-- SO-012 outbound (SHIPPED — Cebu branch)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO12 AND ProductId=@PST2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST2, @LocCEB, -4, N'SALE', N'SALES_ORDER', @SO12, N'SO-2026-012 Flores BPO Cebu dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO12 AND ProductId=@PIM1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM1, @LocCEB, -4, N'SALE', N'SALES_ORDER', @SO12, N'SO-2026-012 Flores BPO Cebu dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO12 AND ProductId=@PIM4)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM4, @LocCEB, -4, N'SALE', N'SALES_ORDER', @SO12, N'SO-2026-012 Flores BPO Cebu dispatch', @Admin);
GO

PRINT N'[seed-06] Stock movements for sales inserted.';
GO

-- ============================================================
-- 8. Invoices for completed/shipped orders
-- ============================================================
DECLARE
    @SO6  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-006'),
    @SO7  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-007'),
    @SO8  BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-008'),
    @SO10 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-010'),
    @SO11 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-011'),
    @SO12 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-012');

-- INV-2026-004: SO-006 — SubTotal=(3*32000)+(6*350)+(3*900)=96000+2100+2700=100800 Tax12%=12096 Total=112896
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-004')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-004', @SO6, '2026-04-21 09:00:00', 100800.0000, 12096.0000, 112896.0000, N'PAID');

-- INV-2026-005: SO-007 — SubTotal=(5*22000)+(2*6200)+(5*120)=110000+12400+600=123000 Tax12%=14760 Total=137760
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-005')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-005', @SO7, '2026-04-23 10:00:00', 123000.0000, 14760.0000, 137760.0000, N'PAID');

-- INV-2026-006: SO-008 — SubTotal=(2*34000)+(1*5500)+(4*150)=68000+5500+600=74100 Tax12%=8892 Total=82992
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-006')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-006', @SO8, '2026-04-25 08:30:00', 74100.0000, 8892.0000, 82992.0000, N'UNPAID');

-- INV-2026-007: SO-010 — SubTotal=(4*85000)+(2*78000)+(6*6200)+(10*350)+(6*900)=340000+156000+37200+3500+5400=542100 Tax12%=65052 Total=607152
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-007')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-007', @SO10, '2026-04-29 09:00:00', 542100.0000, 65052.0000, 607152.0000, N'PARTIAL');

-- INV-2026-008: SO-011 — SubTotal=(3*36500)+(3*350)+(3*120)+(3*900)=109500+1050+360+2700=113610 Tax12%=13633.20 Total=127243.20
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-008')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-008', @SO11, '2026-05-03 08:00:00', 113610.0000, 13633.2000, 127243.2000, N'PAID');

-- INV-2026-009: SO-012 — SubTotal=(4*35000)+(4*350)+(4*900)=140000+1400+3600=145000 Tax12%=17400 Total=162400
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-009')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-009', @SO12, '2026-05-06 10:00:00', 145000.0000, 17400.0000, 162400.0000, N'UNPAID');
GO

PRINT N'[seed-06] Invoices inserted.';
GO

-- ============================================================
-- 9. Purchase Orders (restocking from PH suppliers)
-- ============================================================
DECLARE
    @SupLG  INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'LG Electronics Philippines'),
    @SupDA  INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Daikin Philippines'),
    @SupPA  INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Panasonic Philippines Corp.'),
    @SupCA  INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Carrier Philippines'),
    @SupAS  INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor'),
    @LocWH  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @LocCEB INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB'),
    @LocDAV INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-DAV'),
    @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');

-- PO-004: RECEIVED — LG restock (split & window ACs)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-004')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-004', @SupLG, @LocWH, '2026-04-25 08:00:00', N'RECEIVED', @Admin);

-- PO-005: RECEIVED — Daikin restock (floor mounted + split)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-005')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-005', @SupDA, @LocWH, '2026-04-28 09:00:00', N'RECEIVED', @Admin);

-- PO-006: OPEN — Panasonic restock (compressors + split ACs)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-006')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-006', @SupPA, @LocWH, '2026-05-05 08:00:00', N'OPEN', @Admin);

-- PO-007: PARTIAL — Carrier restock for Cebu branch
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-007')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-007', @SupCA, @LocCEB, '2026-05-08 10:00:00', N'PARTIAL', @Admin);

-- PO-008: OPEN — Ashcol Vendor for installation materials (Davao)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-008')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-008', @SupAS, @LocDAV, '2026-05-10 08:00:00', N'OPEN', @Admin);

-- PO-009: RECEIVED — Ashcol Vendor refrigerants restock (Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-009')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-009', @SupAS, @LocWH, '2026-05-01 08:00:00', N'RECEIVED', @Admin);
GO

PRINT N'[seed-06] Purchase Orders inserted.';
GO

-- ============================================================
-- 10. Purchase Order Lines
-- ============================================================
DECLARE
    @PO4 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-004'),
    @PO5 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-005'),
    @PO6 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-006'),
    @PO7 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-007'),
    @PO8 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-008'),
    @PO9 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-009'),
    @PWT1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-001'),
    @PST2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),
    @PST1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-001'),
    @PFM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-001'),
    @PFM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-002'),
    @PST5 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-005'),
    @PCP1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-001'),
    @PST3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-003'),
    @PRF1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-001'),
    @PRF2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),
    @PRF3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-003'),
    @PIM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-001'),
    @PIM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-002'),
    @PIM3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-003'),
    @PIM4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004');

-- PO-004 lines (LG — fully received)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO4 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO4, 1, @PWT1, 10, 13875.0000, 10);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO4 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO4, 2, @PST2, 8, 26250.0000, 8);

-- PO-005 lines (Daikin — fully received)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO5 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO5, 1, @PFM1, 6, 63750.0000, 6);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO5 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO5, 2, @PFM2, 4, 58500.0000, 4);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO5 AND LineNumber = 3)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO5, 3, @PST1, 5, 24000.0000, 5);

-- PO-006 lines (Panasonic — open, nothing received)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO6 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO6, 1, @PCP1, 10, 4875.0000, 0);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO6 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO6, 2, @PST3, 6, 27375.0000, 0);

-- PO-007 lines (Carrier Cebu — partial)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO7 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO7, 1, @PST5, 5, 31500.0000, 3);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO7 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO7, 2, @PIM4, 20, 675.0000, 20);

-- PO-008 lines (Ashcol Vendor Davao — open)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO8 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO8, 1, @PIM1, 50, 262.5000, 0);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO8 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO8, 2, @PIM2, 30, 90.0000, 0);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO8 AND LineNumber = 3)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO8, 3, @PIM3, 30, 112.5000, 0);

-- PO-009 lines (Ashcol Vendor refrigerants — received)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO9 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO9, 1, @PRF1, 15, 4125.0000, 15);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO9 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO9, 2, @PRF2, 15, 4650.0000, 15);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO9 AND LineNumber = 3)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO9, 3, @PRF3, 10, 5100.0000, 10);
GO

PRINT N'[seed-06] Purchase Order Lines inserted.';
GO

-- ============================================================
-- 11. Stock receipt movements for RECEIVED purchase orders
-- ============================================================
DECLARE
    @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    @LocWH  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @LocCEB INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB'),
    @PO4 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-004'),
    @PO5 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-005'),
    @PO7 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-007'),
    @PO9 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-009'),
    @PWT1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-001'),
    @PST2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),
    @PST1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-001'),
    @PFM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-001'),
    @PFM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-002'),
    @PST5 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-005'),
    @PIM4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004'),
    @PRF1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-001'),
    @PRF2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),
    @PRF3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-003');

-- PO-004 receipts (LG — Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO4 AND ProductId=@PWT1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PWT1, @LocWH, 10, N'RECEIPT', N'PURCHASE_ORDER', @PO4, N'PO-2026-004 LG received', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO4 AND ProductId=@PST2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST2, @LocWH, 8, N'RECEIPT', N'PURCHASE_ORDER', @PO4, N'PO-2026-004 LG received', @Admin);

-- PO-005 receipts (Daikin — Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO5 AND ProductId=@PFM1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFM1, @LocWH, 6, N'RECEIPT', N'PURCHASE_ORDER', @PO5, N'PO-2026-005 Daikin received', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO5 AND ProductId=@PFM2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFM2, @LocWH, 4, N'RECEIPT', N'PURCHASE_ORDER', @PO5, N'PO-2026-005 Daikin received', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO5 AND ProductId=@PST1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST1, @LocWH, 5, N'RECEIPT', N'PURCHASE_ORDER', @PO5, N'PO-2026-005 Daikin received', @Admin);

-- PO-007 partial receipts (Carrier — Cebu)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO7 AND ProductId=@PST5)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PST5, @LocCEB, 3, N'RECEIPT', N'PURCHASE_ORDER', @PO7, N'PO-2026-007 Carrier partial recv', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO7 AND ProductId=@PIM4)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PIM4, @LocCEB, 20, N'RECEIPT', N'PURCHASE_ORDER', @PO7, N'PO-2026-007 Carrier partial recv', @Admin);

-- PO-009 receipts (refrigerants — Main WH)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO9 AND ProductId=@PRF1)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PRF1, @LocWH, 15, N'RECEIPT', N'PURCHASE_ORDER', @PO9, N'PO-2026-009 refrigerants received', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO9 AND ProductId=@PRF2)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PRF2, @LocWH, 15, N'RECEIPT', N'PURCHASE_ORDER', @PO9, N'PO-2026-009 refrigerants received', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO9 AND ProductId=@PRF3)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PRF3, @LocWH, 10, N'RECEIPT', N'PURCHASE_ORDER', @PO9, N'PO-2026-009 refrigerants received', @Admin);
GO

PRINT N'[seed-06] Receipt stock movements inserted.';
GO

-- ============================================================
-- 12. Additional Service Jobs (8 more across PH)
-- ============================================================
DECLARE
    @Loc1   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @LocCEB INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB'),
    @LocDAV INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-DAV'),
    @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    @Carlo  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'carlo.reyes@ashcol.local'),
    @Ana    BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local'),
    @CustVil INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'villanueva.aircon@gmail.com'),
    @CustBau INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'bautista.prop@outlook.com'),
    @CustGon INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'gonzales.cc@yahoo.com'),
    @CustSor INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'procurement@sorianohotels.ph'),
    @CustNav INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'navarro.const@gmail.com'),
    @CustFlo INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'admin@floresbpo.ph'),
    @CustRam INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'ramos.clinic@gmail.com'),
    @CustDiz INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'dizon.school@edu.ph'),
    -- Products
    @PST1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-001'),
    @PST2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),
    @PST3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-003'),
    @PFM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-001'),
    @PWT1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'WT-001'),
    @PCP1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-001'),
    @PCP2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-002'),
    @PRF1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-001'),
    @PRF2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),
    @PRF3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-003'),
    @PIM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-001'),
    @PIM2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-002'),
    @PIM3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-003'),
    @PIM4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004');

-- SJ-2026-003: COMPLETED — Bautista Property, window AC preventive maintenance
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-003')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, CompletedDate, Notes)
    VALUES
        (N'SJ-2026-003', @CustBau, @Loc1, @Admin, N'Carlo Reyes',
         N'COMPLETED', '2026-04-15 08:00:00', '2026-04-15 12:00:00',
         N'Preventive maintenance — 5 window type AC units at Pasig office');
    DECLARE @J3 BIGINT = SCOPE_IDENTITY();
    IF @PRF1 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired, QuantityUsed) VALUES (@J3, 1, @PRF1, 1, 1);
    IF @PIM2 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired, QuantityUsed) VALUES (@J3, 2, @PIM2, 5, 5);
    PRINT N'[seed-06] Job SJ-2026-003 (COMPLETED) inserted.';
END;
GO

DECLARE
    @Loc1   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01'),
    @LocCEB INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB'),
    @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local'),
    @Ana    BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'ana.garcia@ashcol.local'),
    @CustSor INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'procurement@sorianohotels.ph'),
    @CustFlo INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'admin@floresbpo.ph'),
    @CustRam INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'ramos.clinic@gmail.com'),
    @CustDiz INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'dizon.school@edu.ph'),
    @CustNav INT   = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'navarro.const@gmail.com'),
    @PFM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'FM-001'),
    @PST2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-002'),
    @PST3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'ST-003'),
    @PCP2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'CP-002'),
    @PRF2 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-002'),
    @PRF3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'RF-003'),
    @PIM1 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-001'),
    @PIM3 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-003'),
    @PIM4 INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'IM-004');

-- SJ-2026-004: COMPLETED — Soriano Hotel, floor mounted AC installation
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-004')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, CompletedDate, Notes)
    VALUES
        (N'SJ-2026-004', @CustSor, @Loc1, @Admin, N'Benjamin Torres',
         N'COMPLETED', '2026-04-30 07:00:00', '2026-04-30 17:00:00',
         N'Installation of 4 floor-mounted AC units at Boracay resort lobby');
    DECLARE @J4 BIGINT = SCOPE_IDENTITY();
    IF @PFM1 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired, QuantityUsed) VALUES (@J4, 1, @PFM1, 4, 4);
    IF @PRF2 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired, QuantityUsed) VALUES (@J4, 2, @PRF2, 4, 4);
    IF @PIM1 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired, QuantityUsed) VALUES (@J4, 3, @PIM1, 16, 16);
    IF @PIM4 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired, QuantityUsed) VALUES (@J4, 4, @PIM4, 4, 4);
    PRINT N'[seed-06] Job SJ-2026-004 (COMPLETED) inserted.';
END;

-- SJ-2026-005: IN_PROGRESS — Flores BPO, split AC installation (Cebu)
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-005')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-2026-005', @CustFlo, @LocCEB, @Ana, N'Rosemarie Mendoza',
         N'IN_PROGRESS', '2026-05-06 08:00:00',
         N'Installation of 4 split-type AC units at Eastwood BPO office — Cebu team');
    DECLARE @J5 BIGINT = SCOPE_IDENTITY();
    IF @PST2 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J5, 1, @PST2, 4);
    IF @PRF2 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J5, 2, @PRF2, 2);
    IF @PIM1 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J5, 3, @PIM1, 8);
    IF @PIM4 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J5, 4, @PIM4, 4);
    PRINT N'[seed-06] Job SJ-2026-005 (IN_PROGRESS) inserted.';
END;

-- SJ-2026-006: PENDING — Ramos Medical Clinic, split AC installation
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-006')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-2026-006', @CustRam, @Loc1, @Admin, N'Carlo Reyes',
         N'PENDING', '2026-05-15 09:00:00',
         N'New split-type AC installation at clinic consultation rooms — Angeles City');
    DECLARE @J6 BIGINT = SCOPE_IDENTITY();
    IF @PST3 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J6, 1, @PST3, 2);
    IF @PRF3 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J6, 2, @PRF3, 2);
    IF @PIM1 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J6, 3, @PIM1, 4);
    IF @PIM3 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J6, 4, @PIM3, 2);
    IF @PIM4 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J6, 5, @PIM4, 2);
    PRINT N'[seed-06] Job SJ-2026-006 (PENDING) inserted.';
END;

-- SJ-2026-007: PENDING — Dizon School, window AC installation (8 classrooms)
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-007')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-2026-007', @CustDiz, @Loc1, @Admin, N'Ana Garcia',
         N'PENDING', '2026-05-20 07:00:00',
         N'Window type AC installation for 8 classrooms — Lipa City campus');
    DECLARE @J7 BIGINT = SCOPE_IDENTITY();
    IF @PIM1 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J7, 1, @PIM1, 8);
    IF @PIM3 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J7, 2, @PIM3, 8);
    IF @PIM4 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J7, 3, @PIM4, 8);
    PRINT N'[seed-06] Job SJ-2026-007 (PENDING) inserted.';
END;

-- SJ-2026-008: CANCELLED — Navarro Construction (job cancelled by client)
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-008')
BEGIN
    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-2026-008', @CustNav, @Loc1, @Admin, N'Benjamin Torres',
         N'CANCELLED', '2026-05-03 08:00:00',
         N'Compressor replacement job — cancelled by client, rescheduled to next quarter');
    DECLARE @J8 BIGINT = SCOPE_IDENTITY();
    IF @PCP2 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J8, 1, @PCP2, 2);
    IF @PRF2 IS NOT NULL INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired) VALUES (@J8, 2, @PRF2, 2);
    PRINT N'[seed-06] Job SJ-2026-008 (CANCELLED) inserted.';
END;
GO

PRINT N'[seed-06] Service Jobs inserted.';
GO

-- ============================================================
-- 13. Verification summary
-- ============================================================
SELECT 'Users'               AS Entity, COUNT(*) AS [RowCount] FROM dbo.Users
UNION ALL SELECT 'Customers',           COUNT(*) FROM dbo.Customers
UNION ALL SELECT 'Locations',           COUNT(*) FROM dbo.Locations
UNION ALL SELECT 'Products',            COUNT(*) FROM dbo.Products
UNION ALL SELECT 'SalesOrders',         COUNT(*) FROM dbo.SalesOrders
UNION ALL SELECT 'SalesOrderLines',     COUNT(*) FROM dbo.SalesOrderLines
UNION ALL SELECT 'Invoices',            COUNT(*) FROM dbo.Invoices
UNION ALL SELECT 'PurchaseOrders',      COUNT(*) FROM dbo.PurchaseOrders
UNION ALL SELECT 'PurchaseOrderLines',  COUNT(*) FROM dbo.PurchaseOrderLines
UNION ALL SELECT 'StockMovements',      COUNT(*) FROM dbo.StockMovements
UNION ALL SELECT 'StockLevels',         COUNT(*) FROM dbo.StockLevels
UNION ALL SELECT 'ServiceJobs',         COUNT(*) FROM dbo.ServiceJobs
UNION ALL SELECT 'ServiceJobMaterials', COUNT(*) FROM dbo.ServiceJobMaterials;
GO

PRINT N'[seed-06] ✅ Philippines demo data seed complete.';
GO

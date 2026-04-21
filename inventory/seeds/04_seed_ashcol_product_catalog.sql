-- ============================================================
-- Seed: Ashcol Airconditioning Full Product Catalog
-- Covers:
--   1. Window Type Air Conditioners (WT-001 ~ WT-005)
--   2. Split Type Air Conditioners  (ST-001 ~ ST-005)
--   3. Floor Mounted / Standing     (FM-001 ~ FM-003)
--   4. Portable Air Conditioners    (PT-001 ~ PT-003)
--   5. Compressors                  (CP-001 ~ CP-002)
--   6. Refrigerants                 (RF-001 ~ RF-003)
--   7. Installation Materials       (IM-001 ~ IM-004)
--
-- Requires:
--   - DDL scripts 00–07 applied
--   - Triggers applied (trg_StockMovements_AfterInsert_UpdateLevel)
--   - 01_seed_reference_data.sql applied (Locations, Admin user exist)
-- ============================================================

USE AshcolInventory;
GO

SET NOCOUNT ON;
PRINT N'[seed] Starting Ashcol Aircon Product Catalog seed...';
GO

-- ============================================================
-- STEP 1: Product Categories
-- ============================================================
MERGE dbo.ProductCategories AS T
USING (VALUES
    -- Top-level categories
    (N'Air Conditioners',          NULL),
    (N'Aircon Parts & Accessories', NULL),
    -- Sub-categories under Air Conditioners
    (N'Window Type',               N'Air Conditioners'),
    (N'Split Type',                N'Air Conditioners'),
    (N'Floor Mounted',             N'Air Conditioners'),
    (N'Portable',                  N'Air Conditioners'),
    -- Sub-categories under Parts & Accessories
    (N'Compressors',               N'Aircon Parts & Accessories'),
    (N'Refrigerants',              N'Aircon Parts & Accessories'),
    (N'Installation Materials',    N'Aircon Parts & Accessories')
) AS S(Name, ParentName)
ON T.Name = S.Name
WHEN NOT MATCHED THEN
    INSERT (Name, ParentCategoryId)
    VALUES (
        S.Name,
        (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = S.ParentName)
    );
GO

PRINT N'[seed] Categories upserted.';
GO

-- ============================================================
-- STEP 2: Suppliers (Brand suppliers)
-- ============================================================
MERGE dbo.Suppliers AS T
USING (VALUES
    (N'LG Electronics Philippines',      N'Sales Team',   N'sales@lg.ph',           N'+63-2-8902-5480',  N'Makati City, Metro Manila'),
    (N'Carrier Philippines',             N'Sales Team',   N'sales@carrier.ph',       N'+63-2-8888-0000',  N'Pasig City, Metro Manila'),
    (N'Kolin Philippines International', N'Sales Team',   N'info@kolin.ph',          N'+63-2-8888-5665',  N'Mandaluyong City, Metro Manila'),
    (N'Panasonic Philippines Corp.',     N'Sales Team',   N'support@panasonic.ph',   N'+63-2-8888-7272',  N'Makati City, Metro Manila'),
    (N'Samsung Electronics Philippines', N'Sales Team',   N'info@samsung.ph',        N'+63-2-8845-0000',  N'BGC, Taguig City'),
    (N'Daikin Philippines',              N'Sales Team',   N'sales@daikin.ph',        N'+63-2-8706-6600',  N'Parañaque City, Metro Manila'),
    (N'Mitsubishi Electric Philippines', N'Sales Team',   N'info@mitsubishielec.ph', N'+63-2-8551-4190',  N'Mandaluyong City, Metro Manila'),
    (N'TCL Philippines',                 N'Sales Team',   N'support@tcl.ph',         NULL,                N'Metro Manila'),
    (N'Ashcol Preferred Vendor',         N'Procurement',  N'parts@example.com',      N'+63-2-0000-0000',  N'Metro Manila')
) AS S(Name, ContactName, Email, Phone, AddressLine)
ON T.Name = S.Name
WHEN NOT MATCHED THEN
    INSERT (Name, ContactName, Email, Phone, AddressLine)
    VALUES (S.Name, S.ContactName, S.Email, S.Phone, S.AddressLine);
GO

PRINT N'[seed] Suppliers upserted.';
GO

-- ============================================================
-- STEP 3: Products
-- All ListPrice values are taken directly from the catalog (₱).
-- UnitCost is estimated at ~75% of ListPrice (standard trade margin).
-- ReorderLevel defaults: AC units = 3, Parts = 5.
-- Description includes: Brand | Model | HP | Type | Cooling Capacity
-- ============================================================

-- Category & Supplier ID lookups (used across blocks)
DECLARE
    @CatWT  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Window Type'),
    @CatST  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Split Type'),
    @CatFM  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Floor Mounted'),
    @CatPT  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Portable'),
    @CatCP  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Compressors'),
    @CatRF  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Refrigerants'),
    @CatIM  INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Installation Materials'),
    @SupLG  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'LG Electronics Philippines'),
    @SupCA  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Carrier Philippines'),
    @SupKO  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Kolin Philippines International'),
    @SupPA  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Panasonic Philippines Corp.'),
    @SupSA  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Samsung Electronics Philippines'),
    @SupDA  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Daikin Philippines'),
    @SupMI  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Mitsubishi Electric Philippines'),
    @SupTC  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'TCL Philippines'),
    @SupAS  INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor');

-- ❄️ 1. Window Type Air Conditioners
MERGE dbo.Products AS T
USING (VALUES
    (N'WT-001', N'LG Window AC 1.0HP Non-Inverter (LA100GC)',         @CatWT, N'PCS', 13875.0000, 18500.0000, 3, @SupLG,  N'Brand: LG | Model: LA100GC | 1.0 HP | Non-Inverter | 9,000 BTU'),
    (N'WT-002', N'Carrier Window AC 1.0HP Inverter (WCARH010EE)',      @CatWT, N'PCS', 16500.0000, 22000.0000, 3, @SupCA,  N'Brand: Carrier | Model: WCARH010EE | 1.0 HP | Inverter | 10,000 BTU'),
    (N'WT-003', N'Kolin Window AC 1.0HP Inverter (KAG-100WCINV)',      @CatWT, N'PCS', 15375.0000, 20500.0000, 3, @SupKO,  N'Brand: Kolin | Model: KAG-100WCINV | 1.0 HP | Inverter | 9,500 BTU'),
    (N'WT-004', N'Panasonic Window AC 1.0HP Non-Inverter (CW-XC95JPH)',@CatWT, N'PCS', 14400.0000, 19200.0000, 3, @SupPA,  N'Brand: Panasonic | Model: CW-XC95JPH | 1.0 HP | Non-Inverter | 9,000 BTU'),
    (N'WT-005', N'Samsung Window AC 1.0HP Inverter (AW09AYHGAWKNTC)', @CatWT, N'PCS', 16125.0000, 21500.0000, 3, @SupSA,  N'Brand: Samsung | Model: AW09AYHGAWKNTC | 1.0 HP | Inverter | 9,800 BTU')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);

-- 🌬️ 2. Split Type Air Conditioners
MERGE dbo.Products AS T
USING (VALUES
    (N'ST-001', N'Daikin Split AC 1.0HP Inverter (FTKF25TV)',          @CatST, N'PCS', 24000.0000, 32000.0000, 3, @SupDA,  N'Brand: Daikin | Model: FTKF25TV | 1.0 HP | Inverter | 9,000 BTU'),
    (N'ST-002', N'LG Split AC 1.0HP Dual Inverter (HS09ISY)',          @CatST, N'PCS', 26250.0000, 35000.0000, 3, @SupLG,  N'Brand: LG | Model: HS09ISY | 1.0 HP | Dual Inverter | 9,500 BTU'),
    (N'ST-003', N'Panasonic Split AC 1.0HP Inverter (CS-XU9XKQ)',      @CatST, N'PCS', 27375.0000, 36500.0000, 3, @SupPA,  N'Brand: Panasonic | Model: CS-XU9XKQ | 1.0 HP | Inverter | 10,200 BTU'),
    (N'ST-004', N'Mitsubishi Split AC 1.0HP Inverter (MSY-GN10VF)',    @CatST, N'PCS', 25500.0000, 34000.0000, 3, @SupMI,  N'Brand: Mitsubishi | Model: MSY-GN10VF | 1.0 HP | Inverter | 9,800 BTU'),
    (N'ST-005', N'Carrier Split AC 1.5HP Inverter (FP53CEP009308)',    @CatST, N'PCS', 31500.0000, 42000.0000, 3, @SupCA,  N'Brand: Carrier | Model: FP53CEP009308 | 1.5 HP | Inverter | 12,000 BTU')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);

-- 🧊 3. Floor Mounted / Standing Air Conditioners
MERGE dbo.Products AS T
USING (VALUES
    (N'FM-001', N'Carrier Floor Mounted 3.0HP Inverter (42KCE036)',    @CatFM, N'PCS', 63750.0000, 85000.0000, 2, @SupCA,  N'Brand: Carrier | Model: 42KCE036 | 3.0 HP | Inverter | 27,000 BTU'),
    (N'FM-002', N'Daikin Floor Mounted 3.0HP Non-Inverter (FVRN71AXV1)',@CatFM, N'PCS', 58500.0000, 78000.0000, 2, @SupDA,  N'Brand: Daikin | Model: FVRN71AXV1 | 3.0 HP | Non-Inverter | 28,000 BTU'),
    (N'FM-003', N'LG Floor Mounted 3.0HP Inverter (APNQ30GS1A0)',      @CatFM, N'PCS', 67500.0000, 90000.0000, 2, @SupLG,  N'Brand: LG | Model: APNQ30GS1A0 | 3.0 HP | Inverter | 30,000 BTU')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);

-- 🌡️ 4. Portable Air Conditioners
MERGE dbo.Products AS T
USING (VALUES
    (N'PT-001', N'TCL Portable AC 1.0HP (TAC-09CPA)',                  @CatPT, N'PCS', 13500.0000, 18000.0000, 3, @SupTC,  N'Brand: TCL | Model: TAC-09CPA | 1.0 HP | Portable | 9,000 BTU'),
    (N'PT-002', N'Carrier Portable AC 1.0HP (PC09RFP)',                @CatPT, N'PCS', 15750.0000, 21000.0000, 3, @SupCA,  N'Brand: Carrier | Model: PC09RFP | 1.0 HP | Portable | 10,000 BTU'),
    (N'PT-003', N'LG Portable AC 1.0HP (LP1015WNR)',                  @CatPT, N'PCS', 17625.0000, 23500.0000, 3, @SupLG,  N'Brand: LG | Model: LP1015WNR | 1.0 HP | Portable | 10,200 BTU')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);

-- 🔧 5. Compressors
MERGE dbo.Products AS T
USING (VALUES
    (N'CP-001', N'Panasonic Rotary Compressor',                        @CatCP, N'PCS', 4875.0000,  6500.0000,  5, @SupPA,  N'Brand: Panasonic | Rotary Compressor'),
    (N'CP-002', N'LG Inverter Compressor',                             @CatCP, N'PCS', 6375.0000,  8500.0000,  5, @SupLG,  N'Brand: LG | Inverter Compressor')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);

-- 🧊 6. Refrigerants
MERGE dbo.Products AS T
USING (VALUES
    (N'RF-001', N'R22 Refrigerant 13.6 kg',                           @CatRF, N'CAN', 4125.0000,  5500.0000,  5, @SupAS,  N'Type: R22 | Size: 13.6 kg per can'),
    (N'RF-002', N'R410A Refrigerant 11.3 kg',                         @CatRF, N'CAN', 4650.0000,  6200.0000,  5, @SupAS,  N'Type: R410A | Size: 11.3 kg per can'),
    (N'RF-003', N'R32 Refrigerant 9 kg',                              @CatRF, N'CAN', 5100.0000,  6800.0000,  5, @SupAS,  N'Type: R32 | Size: 9 kg per can')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);

-- 🔌 7. Installation Materials
MERGE dbo.Products AS T
USING (VALUES
    (N'IM-001', N'Copper Tube (per meter)',                            @CatIM, N'MTR', 262.5000,   350.0000,  20, @SupAS,  N'Copper tubing for refrigerant lines, sold per meter'),
    (N'IM-002', N'Insulation Foam',                                    @CatIM, N'PCS', 90.0000,    120.0000,  20, @SupAS,  N'Pipe insulation foam sleeve'),
    (N'IM-003', N'Drain Hose',                                         @CatIM, N'PCS', 112.5000,   150.0000,  15, @SupAS,  N'Flexible drain hose for AC condensate'),
    (N'IM-004', N'Circuit Breaker',                                    @CatIM, N'PCS', 675.0000,   900.0000,  10, @SupAS,  N'Dedicated circuit breaker for AC installation')
) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
ON T.Sku = S.Sku
WHEN NOT MATCHED THEN
    INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId, Description)
    VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId, S.Description);
GO

PRINT N'[seed] Products upserted.';
GO

-- ============================================================
-- STEP 4: Opening Stock Balances (via StockMovements → Trigger updates StockLevels)
-- Target location: MWH-01 (Main Warehouse)
-- Default opening qty:
--   AC Units (WT, ST, FM, PT) = 10 each
--   Compressors               = 15 each
--   Refrigerants              = 20 each
--   Installation Materials    = 50 each
-- ============================================================
DECLARE
    @Admin  BIGINT = (SELECT UserId    FROM dbo.Users     WHERE Email = N'admin@ashcol.local'),
    @Loc    INT    = (SELECT LocationId FROM dbo.Locations WHERE Code  = N'MWH-01');

IF @Admin IS NOT NULL AND @Loc IS NOT NULL
BEGIN
    -- AC Units: 10 each
    INSERT INTO dbo.StockMovements
        (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
    SELECT p.ProductId, @Loc, 10, N'INITIAL', N'ADJUSTMENT',
           N'Opening balance — Ashcol catalog seed', @Admin
    FROM dbo.Products p
    WHERE p.Sku IN (
        N'WT-001', N'WT-002', N'WT-003', N'WT-004', N'WT-005',
        N'ST-001', N'ST-002', N'ST-003', N'ST-004', N'ST-005',
        N'FM-001', N'FM-002', N'FM-003',
        N'PT-001', N'PT-002', N'PT-003'
    )
    AND NOT EXISTS (
        SELECT 1 FROM dbo.StockMovements m
        WHERE m.MovementType = N'INITIAL'
          AND m.ProductId    = p.ProductId
          AND m.LocationId   = @Loc
    );

    -- Compressors: 15 each
    INSERT INTO dbo.StockMovements
        (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
    SELECT p.ProductId, @Loc, 15, N'INITIAL', N'ADJUSTMENT',
           N'Opening balance — Ashcol catalog seed', @Admin
    FROM dbo.Products p
    WHERE p.Sku IN (N'CP-001', N'CP-002')
    AND NOT EXISTS (
        SELECT 1 FROM dbo.StockMovements m
        WHERE m.MovementType = N'INITIAL'
          AND m.ProductId    = p.ProductId
          AND m.LocationId   = @Loc
    );

    -- Refrigerants: 20 each
    INSERT INTO dbo.StockMovements
        (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
    SELECT p.ProductId, @Loc, 20, N'INITIAL', N'ADJUSTMENT',
           N'Opening balance — Ashcol catalog seed', @Admin
    FROM dbo.Products p
    WHERE p.Sku IN (N'RF-001', N'RF-002', N'RF-003')
    AND NOT EXISTS (
        SELECT 1 FROM dbo.StockMovements m
        WHERE m.MovementType = N'INITIAL'
          AND m.ProductId    = p.ProductId
          AND m.LocationId   = @Loc
    );

    -- Installation Materials: 50 each
    INSERT INTO dbo.StockMovements
        (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
    SELECT p.ProductId, @Loc, 50, N'INITIAL', N'ADJUSTMENT',
           N'Opening balance — Ashcol catalog seed', @Admin
    FROM dbo.Products p
    WHERE p.Sku IN (N'IM-001', N'IM-002', N'IM-003', N'IM-004')
    AND NOT EXISTS (
        SELECT 1 FROM dbo.StockMovements m
        WHERE m.MovementType = N'INITIAL'
          AND m.ProductId    = p.ProductId
          AND m.LocationId   = @Loc
    );
END
ELSE
    PRINT N'[seed] WARNING: Admin user or MWH-01 location not found. Opening balances skipped.';
GO

PRINT N'[seed] Opening stock balances inserted (trigger will update StockLevels).';
PRINT N'[seed] ✅ Ashcol Aircon Product Catalog seed complete. 30 products total.';
GO

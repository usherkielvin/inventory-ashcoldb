-- Seed: demo transactions (customers, sales orders, invoices, purchase orders)
-- Run AFTER: 01_seed_reference_data.sql (needs Roles, Users, Products, Locations, StockLevels)
-- Safe to re-run: each block guards with IF NOT EXISTS / MERGE ON unique key.

USE AshcolInventory;
GO

SET NOCOUNT ON;
PRINT N'[seed-03] Inserting demo transaction data...';
GO

-- ============================================================
-- 1. Additional Staff Users
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'juan.delacruz@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'juan.delacruz@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Juan dela Cruz');

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'maria.santos@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'maria.santos@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'Maria Santos');
GO

DECLARE @StaffRole INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'Staff');
DECLARE @Juan BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'juan.delacruz@ashcol.local');
DECLARE @Maria BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'maria.santos@ashcol.local');

IF @Juan IS NOT NULL AND @StaffRole IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @Juan AND RoleId = @StaffRole)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@Juan, @StaffRole);

IF @Maria IS NOT NULL AND @StaffRole IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @Maria AND RoleId = @StaffRole)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@Maria, @StaffRole);
GO

-- ============================================================
-- 2. Customers
-- ============================================================
MERGE dbo.Customers AS T
USING (VALUES
    (N'Reyes HVAC Services',    N'info@reyeshvac.example',      N'+63-917-111-2222', N'Makati City'),
    (N'Cruz Cold Solutions',    N'orders@cruzcold.example',     N'+63-918-333-4444', N'Quezon City'),
    (N'Dela Paz Appliances',    N'sales@delapaz.example',       N'+63-919-555-6666', N'Cebu City'),
    (N'Tan HVAC Contractors',   N'tan.hvac@example.com',        N'+63-920-777-8888', N'Makati City'),
    (N'Lim Refrigeration Corp', N'lim.refrig@example.com',      N'+63-921-999-0000', N'Manila')
) AS S(Name, Email, Phone, AddressLine)
ON T.Email = S.Email
WHEN NOT MATCHED THEN
    INSERT (Name, Email, Phone, AddressLine)
    VALUES (S.Name, S.Email, S.Phone, S.AddressLine);
GO

-- ============================================================
-- 3. Additional Products (to round out the catalog)
-- ============================================================
DECLARE @CatParts   INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'HVAC Parts');
DECLARE @CatConsumables INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Consumables');
DECLARE @Sup1       INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor');
DECLARE @Sup2       INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Cold Chain Supply Co.');

IF @CatParts IS NOT NULL AND @Sup1 IS NOT NULL
BEGIN
    MERGE dbo.Products AS T
    USING (VALUES
        (N'SKU-COIL-E24',  N'Evaporator Coil 2-Ton',    @CatParts, N'PCS', 3500.0000, 4800.0000, 5, @Sup1),
        (N'SKU-FAN-12DC',  N'DC Fan Motor 12V',          @CatParts, N'PCS',  450.0000,  680.0000, 10, @Sup1),
        (N'SKU-THERMO-01', N'Digital Thermostat Module', @CatParts, N'PCS',  220.0000,  380.0000, 15, @Sup1)
    ) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    ON T.Sku = S.Sku
    WHEN NOT MATCHED THEN
        INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
        VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId);
END;

IF @CatConsumables IS NOT NULL AND @Sup2 IS NOT NULL
BEGIN
    MERGE dbo.Products AS T
    USING (VALUES
        (N'SKU-TAPE-INS',  N'Insulation Tape Roll',  @CatConsumables, N'ROLL',  35.0000,  65.0000, 50, @Sup2),
        (N'SKU-COILCLEAN', N'Coil Cleaner Spray 1L', @CatConsumables, N'CAN',  180.0000, 280.0000, 20, @Sup2)
    ) AS S(Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    ON T.Sku = S.Sku
    WHEN NOT MATCHED THEN
        INSERT (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
        VALUES (S.Sku, S.Name, S.CategoryId, S.UnitOfMeasure, S.UnitCost, S.ListPrice, S.ReorderLevel, S.SupplierId);
END;
GO

-- ============================================================
-- 4. Opening stock balances for new products (all locations)
-- ============================================================
DECLARE @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @LocWH  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
DECLARE @LocCEB INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB');

-- Main warehouse: 30 units each of new products
INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
SELECT p.ProductId, @LocWH, 30, N'INITIAL', N'ADJUSTMENT', NULL, N'Opening balance demo seed', @Admin
FROM dbo.Products p
WHERE p.Sku IN (N'SKU-COIL-E24', N'SKU-FAN-12DC', N'SKU-THERMO-01')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.StockMovements m
      WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @LocWH
  );

-- Consumables at both warehouse and Cebu branch
INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
SELECT p.ProductId, @LocWH, 100, N'INITIAL', N'ADJUSTMENT', NULL, N'Opening consumables balance', @Admin
FROM dbo.Products p
WHERE p.Sku IN (N'SKU-TAPE-INS', N'SKU-COILCLEAN')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.StockMovements m
      WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @LocWH
  );

INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
SELECT p.ProductId, @LocCEB, 40, N'INITIAL', N'ADJUSTMENT', NULL, N'Opening Cebu branch balance', @Admin
FROM dbo.Products p
WHERE p.Sku IN (N'SKU-FILTER-001', N'SKU-CAP-45', N'SKU-TAPE-INS')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.StockMovements m
      WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @LocCEB
  );
GO

-- ============================================================
-- 5. Sales Orders (3 confirmed, 1 draft, 1 shipped)
-- ============================================================
DECLARE @CustReyes BIGINT = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'info@reyeshvac.example');
DECLARE @CustCruz  BIGINT = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'orders@cruzcold.example');
DECLARE @CustDelapaz BIGINT = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'sales@delapaz.example');
DECLARE @CustTan   BIGINT = (SELECT CustomerId FROM dbo.Customers WHERE Email = N'tan.hvac@example.com');
DECLARE @LocWH     INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
DECLARE @LocCEB    INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB');
DECLARE @Juan      BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'juan.delacruiz@ashcol.local');
DECLARE @Juan2     BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'juan.delacruz@ashcol.local');
DECLARE @Maria     BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'maria.santos@ashcol.local');
DECLARE @Admin     BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');

-- SO-001 : Confirmed (Reyes HVAC)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-001')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-001', @CustReyes, N'CONFIRMED',
            '2026-04-01 09:00:00', @LocWH, @Juan2);

-- SO-002 : Completed (Cruz Cold)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-002')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-002', @CustCruz, N'COMPLETED',
            '2026-04-05 10:30:00', @LocWH, @Maria);

-- SO-003 : Completed (Dela Paz — Cebu branch)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-003')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-003', @CustDelapaz, N'COMPLETED',
            '2026-04-08 14:00:00', @LocCEB, @Maria);

-- SO-004 : Shipped (Tan HVAC)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-004')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-004', @CustTan, N'SHIPPED',
            '2026-04-10 08:00:00', @LocWH, @Juan2);

-- SO-005 : Draft (Reyes HVAC)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-005')
    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-2026-005', @CustReyes, N'DRAFT',
            '2026-04-18 11:00:00', @LocWH, @Juan2);
GO

-- ============================================================
-- 6. Sales Order Lines
-- ============================================================
DECLARE @SO1 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-001');
DECLARE @SO2 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-002');
DECLARE @SO3 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-003');
DECLARE @SO4 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-004');
DECLARE @SO5 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-005');

DECLARE @PFilter INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-FILTER-001');
DECLARE @PCap45  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-CAP-45');
DECLARE @PR410A  INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-R410A-5');
DECLARE @PCoil   INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-COIL-E24');
DECLARE @PFan    INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-FAN-12DC');
DECLARE @PThermo INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-THERMO-01');
DECLARE @PTape   INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-TAPE-INS');
DECLARE @PCoilCl INT    = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-COILCLEAN');

-- Lines for SO-001
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO1 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO1, 1, @PFilter, 10, 199.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO1 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO1, 2, @PCap45, 5, 150.0000);

-- Lines for SO-002
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO2 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO2, 1, @PR410A, 3, 3200.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO2 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO2, 2, @PTape, 20, 65.0000);

-- Lines for SO-003
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO3 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO3, 1, @PFilter, 8, 199.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO3 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO3, 2, @PCoilCl, 12, 280.0000);

-- Lines for SO-004
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO4 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO4, 1, @PCoil, 2, 4800.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO4 AND LineNumber = 2)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO4, 2, @PFan, 4, 680.0000);
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO4 AND LineNumber = 3)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO4, 3, @PThermo, 4, 380.0000);

-- Lines for SO-005 (draft)
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrderLines WHERE SalesOrderId = @SO5 AND LineNumber = 1)
    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (@SO5, 1, @PR410A, 2, 3200.0000);
GO

-- ============================================================
-- 7. Stock movements for SALE on confirmed/completed orders
-- ============================================================
DECLARE @Admin   BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @LocWH   INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
DECLARE @LocCEB  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'BRN-CRB');

DECLARE @SO1 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-001');
DECLARE @SO2 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-002');
DECLARE @SO3 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-003');
DECLARE @SO4 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-004');

DECLARE @PFilter INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-FILTER-001');
DECLARE @PCap45  INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-CAP-45');
DECLARE @PR410A  INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-R410A-5');
DECLARE @PCoil   INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-COIL-E24');
DECLARE @PFan    INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-FAN-12DC');
DECLARE @PThermo INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-THERMO-01');
DECLARE @PTape   INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-TAPE-INS');
DECLARE @PCoilCl INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-COILCLEAN');

-- SO-001 outbound (confirmed — stock reserved)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO1 AND ProductId=@PFilter)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFilter, @LocWH, -10, N'SALE', N'SALES_ORDER', @SO1, N'SO-2026-001 confirmed dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO1 AND ProductId=@PCap45)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PCap45, @LocWH, -5, N'SALE', N'SALES_ORDER', @SO1, N'SO-2026-001 confirmed dispatch', @Admin);

-- SO-002 outbound (completed)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO2 AND ProductId=@PR410A)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PR410A, @LocWH, -3, N'SALE', N'SALES_ORDER', @SO2, N'SO-2026-002 shipped', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO2 AND ProductId=@PTape)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PTape, @LocWH, -20, N'SALE', N'SALES_ORDER', @SO2, N'SO-2026-002 shipped', @Admin);

-- SO-003 outbound (completed — Cebu)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO3 AND ProductId=@PFilter)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFilter, @LocCEB, -8, N'SALE', N'SALES_ORDER', @SO3, N'SO-2026-003 Cebu dispatch', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO3 AND ProductId=@PCoilCl)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PCoilCl, @LocCEB, -12, N'SALE', N'SALES_ORDER', @SO3, N'SO-2026-003 Cebu dispatch', @Admin);

-- SO-004 outbound (shipped)
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO4 AND ProductId=@PCoil)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PCoil, @LocWH, -2, N'SALE', N'SALES_ORDER', @SO4, N'SO-2026-004 shipped', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO4 AND ProductId=@PFan)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFan, @LocWH, -4, N'SALE', N'SALES_ORDER', @SO4, N'SO-2026-004 shipped', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'SALE' AND ReferenceType=N'SALES_ORDER' AND ReferenceId=@SO4 AND ProductId=@PThermo)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PThermo, @LocWH, -4, N'SALE', N'SALES_ORDER', @SO4, N'SO-2026-004 shipped', @Admin);
GO

-- ============================================================
-- 8. Invoices (for completed/shipped orders)
-- ============================================================
DECLARE @SO2 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-002');
DECLARE @SO3 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-003');
DECLARE @SO4 BIGINT = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-004');

-- Invoice for SO-002  SubTotal = (3*3200)+(20*65) = 9600+1300 = 10900  Tax 12% = 1308  Total = 12208
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-001')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-001', @SO2, '2026-04-06 09:00:00', 10900.0000, 1308.0000, 12208.0000, N'PAID');

-- Invoice for SO-003  SubTotal = (8*199)+(12*280) = 1592+3360 = 4952  Tax 12% = 594.24  Total = 5546.24
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-002')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-002', @SO3, '2026-04-09 14:00:00', 4952.0000, 594.2400, 5546.2400, N'PAID');

-- Invoice for SO-004  SubTotal = (2*4800)+(4*680)+(4*380) = 9600+2720+1520 = 13840  Tax 12% = 1660.80  Total = 15500.80
IF NOT EXISTS (SELECT 1 FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-003')
    INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
    VALUES (N'INV-2026-003', @SO4, '2026-04-11 10:00:00', 13840.0000, 1660.8000, 15500.8000, N'UNPAID');
GO

-- ============================================================
-- 9. Purchase Orders
-- ============================================================
DECLARE @Sup1   INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor');
DECLARE @Sup2   INT    = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Cold Chain Supply Co.');
DECLARE @LocWH  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
DECLARE @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');

-- PO-001 : Received (to restock filters and capacitors)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-001')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-001', @Sup1, @LocWH, '2026-04-02 08:00:00', N'RECEIVED', @Admin);

-- PO-002 : Open (pending R-410A + coil restock)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-002')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-002', @Sup1, @LocWH, '2026-04-15 08:00:00', N'OPEN', @Admin);

-- PO-003 : Partial (consumables from Cold Chain)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-003')
    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-2026-003', @Sup2, @LocWH, '2026-04-12 09:00:00', N'PARTIAL', @Admin);
GO

-- ============================================================
-- 10. Purchase Order Lines
-- ============================================================
DECLARE @PO1 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-001');
DECLARE @PO2 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-002');
DECLARE @PO3 BIGINT = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-003');

DECLARE @PFilter INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-FILTER-001');
DECLARE @PCap45  INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-CAP-45');
DECLARE @PR410A  INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-R410A-5');
DECLARE @PCoil   INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-COIL-E24');
DECLARE @PTape   INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-TAPE-INS');
DECLARE @PCoilCl INT = (SELECT ProductId FROM dbo.Products WHERE Sku = N'SKU-COILCLEAN');

-- PO-001 lines (fully received)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO1 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO1, 1, @PFilter, 50, 120.0000, 50);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO1 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO1, 2, @PCap45, 30, 85.0000, 30);

-- PO-002 lines (open — nothing received)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO2 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO2, 1, @PR410A, 10, 2500.0000, 0);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO2 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO2, 2, @PCoil, 5, 3500.0000, 0);

-- PO-003 lines (partial)
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO3 AND LineNumber = 1)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO3, 1, @PTape, 200, 35.0000, 120);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrderLines WHERE PurchaseOrderId = @PO3 AND LineNumber = 2)
    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (@PO3, 2, @PCoilCl, 80, 180.0000, 80);

-- Stock receipt movement for PO-001 (received goods)
DECLARE @Admin  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @LocWH  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');

IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO1 AND ProductId=@PFilter)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PFilter, @LocWH, 50, N'RECEIPT', N'PURCHASE_ORDER', @PO1, N'PO-2026-001 received', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO1 AND ProductId=@PCap45)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PCap45, @LocWH, 30, N'RECEIPT', N'PURCHASE_ORDER', @PO1, N'PO-2026-001 received', @Admin);

-- Partial receipt for PO-003
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO3 AND ProductId=@PTape)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PTape, @LocWH, 120, N'RECEIPT', N'PURCHASE_ORDER', @PO3, N'PO-2026-003 partial recv tape', @Admin);
IF NOT EXISTS (SELECT 1 FROM dbo.StockMovements WHERE MovementType=N'RECEIPT' AND ReferenceType=N'PURCHASE_ORDER' AND ReferenceId=@PO3 AND ProductId=@PCoilCl)
    INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note, CreatedByUserId)
    VALUES (@PCoilCl, @LocWH, 80, N'RECEIPT', N'PURCHASE_ORDER', @PO3, N'PO-2026-003 partial recv cleaner', @Admin);
GO

-- ============================================================
-- 11. Verification queries
-- ============================================================
SELECT 'Customers'       AS Entity, COUNT(*) AS RowCount FROM dbo.Customers
UNION ALL
SELECT 'SalesOrders',    COUNT(*) FROM dbo.SalesOrders
UNION ALL
SELECT 'SalesOrderLines',COUNT(*) FROM dbo.SalesOrderLines
UNION ALL
SELECT 'Invoices',       COUNT(*) FROM dbo.Invoices
UNION ALL
SELECT 'PurchaseOrders', COUNT(*) FROM dbo.PurchaseOrders
UNION ALL
SELECT 'PurchaseOrderLines', COUNT(*) FROM dbo.PurchaseOrderLines
UNION ALL
SELECT 'StockMovements', COUNT(*) FROM dbo.StockMovements;
GO

PRINT N'[seed-03] Demo transaction seed complete.';
GO

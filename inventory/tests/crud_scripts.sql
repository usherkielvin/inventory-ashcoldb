-- ============================================================
-- ASHCOL INVENTORY — CRUD SCRIPTS
-- Run individual sections as needed in SSMS.
-- ============================================================
USE AshcolInventory;
GO
SET NOCOUNT ON;

-- ============================================================
-- ROLES
-- ============================================================

-- READ
SELECT * FROM dbo.Roles;

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Technician')
    INSERT INTO dbo.Roles (RoleName, Description)
    VALUES (N'Technician', N'Field service technician');

-- UPDATE
UPDATE dbo.Roles SET Description = N'Updated description' WHERE RoleName = N'Technician';

-- DELETE (soft via IsDeleted)
UPDATE dbo.Roles SET IsDeleted = 1, DeletedAt = SYSDATETIME() WHERE RoleName = N'Technician';

-- ============================================================
-- USERS
-- ============================================================

-- READ
SELECT UserId, Email, FullName, IsActive, IsDeleted, CreatedAt FROM dbo.Users;

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'test.user@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'test.user@ashcol.local', N'PLACEHOLDER_HASH', N'Test User');

-- UPDATE
UPDATE dbo.Users SET FullName = N'Test User Updated', IsActive = 1
WHERE Email = N'test.user@ashcol.local';

-- DELETE (soft)
UPDATE dbo.Users SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE Email = N'test.user@ashcol.local';

-- ============================================================
-- PRODUCT CATEGORIES
-- ============================================================

-- READ
SELECT * FROM dbo.ProductCategories WHERE IsDeleted = 0 ORDER BY Name;

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Test Category')
    INSERT INTO dbo.ProductCategories (Name, ParentCategoryId)
    VALUES (N'Test Category', NULL);

-- UPDATE
IF EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Test Category')
   AND NOT EXISTS (SELECT 1 FROM dbo.ProductCategories WHERE Name = N'Test Category Updated')
    UPDATE dbo.ProductCategories SET Name = N'Test Category Updated'
    WHERE Name = N'Test Category';

-- DELETE (soft)
UPDATE dbo.ProductCategories SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE Name IN (N'Test Category', N'Test Category Updated') AND IsDeleted = 0;

-- ============================================================
-- SUPPLIERS
-- ============================================================

    -- READ
    SELECT * FROM dbo.Suppliers WHERE IsDeleted = 0 ORDER BY Name;

    -- CREATE
    IF NOT EXISTS (SELECT 1 FROM dbo.Suppliers WHERE Name = N'Test Supplier')
        INSERT INTO dbo.Suppliers (Name, ContactName, Email, Phone, AddressLine)
        VALUES (N'Test Supplier', N'John Doe', N'john@test.com', N'+63-900-000-0000', N'Manila');

    -- UPDATE
    UPDATE dbo.Suppliers SET Phone = N'+63-900-111-1111', ContactName = N'Jane Doe'
    WHERE Name = N'Test Supplier';

    -- DELETE (soft)
    UPDATE dbo.Suppliers SET IsDeleted = 1, DeletedAt = SYSDATETIME()
    WHERE Name = N'Test Supplier';

-- ============================================================
-- PRODUCTS
-- ============================================================

-- READ all active
SELECT p.ProductId, p.Sku, p.Name, p.UnitOfMeasure, p.UnitCost, p.ListPrice,
       p.ReorderLevel, c.Name AS Category, s.Name AS Supplier
FROM dbo.Products p
JOIN dbo.ProductCategories c ON c.CategoryId = p.CategoryId
LEFT JOIN dbo.Suppliers s ON s.SupplierId = p.SupplierId
WHERE p.IsDeleted = 0
ORDER BY p.Sku;

-- READ single
SELECT * FROM dbo.Products WHERE Sku = N'SD-1471';

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE Sku = N'TEST-001')
    INSERT INTO dbo.Products (Sku, Name, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
    VALUES (
        N'TEST-001', N'Test Product',
        (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Installation Materials'),
        N'PCS', 100.0000, 150.0000, 5,
        (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor')
    );

-- UPDATE
UPDATE dbo.Products SET ListPrice = 175.0000, ReorderLevel = 10
WHERE Sku = N'TEST-001';

-- DELETE (soft — trigger enforces this)
DELETE FROM dbo.Products WHERE Sku = N'TEST-001';
-- verify it's soft-deleted:
SELECT Sku, Name, IsDeleted, DeletedAt FROM dbo.Products WHERE Sku = N'TEST-001';

-- ============================================================
-- LOCATIONS
-- ============================================================

-- READ
SELECT * FROM dbo.Locations WHERE IsDeleted = 0 ORDER BY Code;

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.Locations WHERE Code = N'TEST-LOC')
    INSERT INTO dbo.Locations (Code, Name, LocationType, AddressLine)
    VALUES (N'TEST-LOC', N'Test Location', N'STORE', N'Test Address');

-- UPDATE
UPDATE dbo.Locations SET AddressLine = N'Updated Address', IsActive = 1
WHERE Code = N'TEST-LOC';

-- DELETE (soft)
UPDATE dbo.Locations SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE Code = N'TEST-LOC';

-- ============================================================
-- STOCK LEVELS
-- ============================================================

-- READ all stock
SELECT l.Code, l.Name AS Location, p.Sku, p.Name AS Product,
       sl.QuantityOnHand, p.ReorderLevel,
       CASE WHEN sl.QuantityOnHand < p.ReorderLevel THEN 'LOW' ELSE 'OK' END AS StockStatus
FROM dbo.StockLevels sl
JOIN dbo.Locations l ON l.LocationId = sl.LocationId
JOIN dbo.Products p ON p.ProductId = sl.ProductId
WHERE p.IsDeleted = 0
ORDER BY l.Code, p.Sku;

-- READ low stock only
SELECT * FROM dbo.vw_LowStockAlert ORDER BY ShortfallQty DESC;

-- CREATE / UPDATE stock (via StockMovements — trigger updates StockLevels)
DECLARE @AdjProductId  INT = (SELECT TOP 1 ProductId FROM dbo.Products WHERE IsDeleted = 0 ORDER BY ProductId);
DECLARE @AdjLocationId INT = (SELECT TOP 1 LocationId FROM dbo.Locations WHERE IsDeleted = 0 ORDER BY LocationId);

IF @AdjProductId IS NOT NULL AND @AdjLocationId IS NOT NULL
    INSERT INTO dbo.StockMovements
        (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
    VALUES (@AdjProductId, @AdjLocationId, 10, N'ADJUSTMENT', N'ADJUSTMENT', N'Manual stock adjustment', NULL);
ELSE
    PRINT N'[skip] No products or locations found for stock adjustment test.';

-- ============================================================
-- CUSTOMERS
-- ============================================================

-- READ
SELECT * FROM dbo.Customers WHERE IsDeleted = 0 ORDER BY Name;

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.Customers WHERE Email = N'test.customer@example.com')
    INSERT INTO dbo.Customers (Name, Email, Phone, AddressLine)
    VALUES (N'Test Customer', N'test.customer@example.com', N'+63-900-123-4567', N'Quezon City');

-- UPDATE
UPDATE dbo.Customers SET Phone = N'+63-900-999-8888', AddressLine = N'Makati City'
WHERE Email = N'test.customer@example.com';

-- DELETE (soft)
UPDATE dbo.Customers SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE Email = N'test.customer@example.com';

-- ============================================================
-- SALES ORDERS
-- ============================================================

-- READ all (via view)
SELECT * FROM dbo.vw_SalesOrderSummary ORDER BY OrderDate DESC;

-- READ single with lines
SELECT so.*, c.Name AS CustomerName
FROM dbo.SalesOrders so
JOIN dbo.Customers c ON c.CustomerId = so.CustomerId
WHERE so.OrderNumber = N'SO-2026-001';

SELECT sol.*, p.Sku, p.Name AS ProductName
FROM dbo.SalesOrderLines sol
JOIN dbo.Products p ON p.ProductId = sol.ProductId
WHERE sol.SalesOrderId = (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-001');

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.SalesOrders WHERE OrderNumber = N'SO-TEST-001')
BEGIN
    DECLARE @CustId INT = (SELECT TOP 1 CustomerId FROM dbo.Customers WHERE IsDeleted = 0);
    DECLARE @LocId  INT = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
    DECLARE @UserId BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');

    INSERT INTO dbo.SalesOrders (OrderNumber, CustomerId, OrderStatus, OrderDate, LocationId, CreatedByUserId)
    VALUES (N'SO-TEST-001', @CustId, N'DRAFT', SYSDATETIME(), @LocId, @UserId);

    INSERT INTO dbo.SalesOrderLines (SalesOrderId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (
        (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-TEST-001'),
        1,
        (SELECT TOP 1 ProductId FROM dbo.Products WHERE IsDeleted = 0 ORDER BY ProductId),
        5, 1699.0000
    );
END;

-- UPDATE status
UPDATE dbo.SalesOrders SET OrderStatus = N'CONFIRMED'
WHERE OrderNumber = N'SO-TEST-001';

-- DELETE (soft)
UPDATE dbo.SalesOrders SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE OrderNumber = N'SO-TEST-001';

-- ============================================================
-- INVOICES
-- ============================================================

-- READ all (via view)
SELECT * FROM dbo.vw_InvoiceSummary ORDER BY InvoiceDate DESC;

-- READ single
SELECT * FROM dbo.Invoices WHERE InvoiceNumber = N'INV-2026-001';

-- CREATE
INSERT INTO dbo.Invoices (InvoiceNumber, SalesOrderId, InvoiceDate, SubTotal, TaxAmount, TotalAmount, PaymentStatus)
VALUES (
    N'INV-TEST-001',
    (SELECT SalesOrderId FROM dbo.SalesOrders WHERE OrderNumber = N'SO-2026-001'),
    SYSDATETIME(), 8495.0000, 1019.4000, 9514.4000, N'UNPAID'
);

-- UPDATE payment status
UPDATE dbo.Invoices SET PaymentStatus = N'PAID'
WHERE InvoiceNumber = N'INV-TEST-001';

-- DELETE (soft)
UPDATE dbo.Invoices SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE InvoiceNumber = N'INV-TEST-001';

-- ============================================================
-- PURCHASE ORDERS
-- ============================================================

-- READ all (via view)
SELECT * FROM dbo.vw_PurchaseOrderSummary ORDER BY OrderDate DESC;

-- READ single with lines
SELECT po.*, s.Name AS SupplierName
FROM dbo.PurchaseOrders po
JOIN dbo.Suppliers s ON s.SupplierId = po.SupplierId
WHERE po.PoNumber = N'PO-2026-001';

SELECT pol.*, p.Sku, p.Name AS ProductName
FROM dbo.PurchaseOrderLines pol
JOIN dbo.Products p ON p.ProductId = pol.ProductId
WHERE pol.PurchaseOrderId = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-2026-001');

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-TEST-001')
BEGIN
    DECLARE @SupId  INT    = (SELECT TOP 1 SupplierId FROM dbo.Suppliers WHERE IsDeleted = 0);
    DECLARE @LocId2 INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
    DECLARE @UsrId  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');

    INSERT INTO dbo.PurchaseOrders (PoNumber, SupplierId, LocationId, OrderDate, Status, CreatedByUserId)
    VALUES (N'PO-TEST-001', @SupId, @LocId2, SYSDATETIME(), N'OPEN', @UsrId);

    INSERT INTO dbo.PurchaseOrderLines (PurchaseOrderId, LineNumber, ProductId, QuantityOrdered, UnitCost, QuantityReceived)
    VALUES (
        (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-TEST-001'),
        1,
        (SELECT TOP 1 ProductId FROM dbo.Products WHERE IsDeleted = 0 ORDER BY ProductId),
        20, 1274.0000, 0
    );
END;

-- UPDATE status + received qty
UPDATE dbo.PurchaseOrders SET Status = N'RECEIVED'
WHERE PoNumber = N'PO-TEST-001';

UPDATE dbo.PurchaseOrderLines SET QuantityReceived = 20
WHERE PurchaseOrderId = (SELECT PurchaseOrderId FROM dbo.PurchaseOrders WHERE PoNumber = N'PO-TEST-001');

-- DELETE (soft)
UPDATE dbo.PurchaseOrders SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE PoNumber = N'PO-TEST-001';

-- ============================================================
-- SERVICE JOBS
-- ============================================================

-- READ all
SELECT sj.JobId, sj.JobNumber, sj.JobStatus, sj.ScheduledDate, sj.CompletedDate,
       sj.AssigneeName, sj.Notes,
       c.Name AS Customer, l.Name AS Location
FROM dbo.ServiceJobs sj
JOIN dbo.Customers c ON c.CustomerId = sj.CustomerId
JOIN dbo.Locations l ON l.LocationId = sj.LocationId
WHERE sj.IsDeleted = 0
ORDER BY sj.CreatedAt DESC;

-- READ single with materials
SELECT * FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-001';

SELECT sjm.*, p.Sku, p.Name AS ProductName
FROM dbo.ServiceJobMaterials sjm
JOIN dbo.Products p ON p.ProductId = sjm.ProductId
WHERE sjm.JobId = (SELECT JobId FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-2026-001');

-- CREATE
IF NOT EXISTS (SELECT 1 FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-TEST-001')
BEGIN
    DECLARE @CId  INT    = (SELECT TOP 1 CustomerId FROM dbo.Customers WHERE IsDeleted = 0);
    DECLARE @LId  INT    = (SELECT TOP 1 LocationId FROM dbo.Locations WHERE IsDeleted = 0 ORDER BY LocationId);
    DECLARE @UId  BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');

    INSERT INTO dbo.ServiceJobs
        (JobNumber, CustomerId, LocationId, ManagedByUserId, AssigneeName, JobStatus, ScheduledDate, Notes)
    VALUES
        (N'SJ-TEST-001', @CId, @LId, @UId, N'Test Technician', N'PENDING', '2026-06-01 09:00:00', N'Test job');

    INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired)
    VALUES (
        (SELECT JobId FROM dbo.ServiceJobs WHERE JobNumber = N'SJ-TEST-001'),
        1,
        (SELECT TOP 1 ProductId FROM dbo.Products WHERE IsDeleted = 0 ORDER BY ProductId),
        2
    );
END;

-- UPDATE status
UPDATE dbo.ServiceJobs SET JobStatus = N'IN_PROGRESS'
WHERE JobNumber = N'SJ-TEST-001';

UPDATE dbo.ServiceJobs
SET JobStatus = N'COMPLETED', CompletedDate = SYSDATETIME()
WHERE JobNumber = N'SJ-TEST-001';

-- DELETE (soft)
UPDATE dbo.ServiceJobs SET IsDeleted = 1, DeletedAt = SYSDATETIME()
WHERE JobNumber = N'SJ-TEST-001';

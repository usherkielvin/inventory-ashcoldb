-- ============================================================
-- FULL SETUP SCRIPT — run this ONE file in SSMS to set up
-- the entire AshcolInventory database from scratch.
-- Order: DDL → Triggers → Views → Seeds
-- ============================================================

-- ============================================================
-- 00: Create Database
-- ============================================================
USE master;
GO

IF DB_ID(N'AshcolInventory') IS NULL
BEGIN
    CREATE DATABASE AshcolInventory
        COLLATE SQL_Latin1_General_CP1_CI_AS;
END;
GO

USE AshcolInventory;
GO

-- ============================================================
-- 01: Users & Roles
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Roles' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Roles (
        RoleId          INT IDENTITY(1,1) NOT NULL,
        RoleName        NVARCHAR(64)  NOT NULL,
        Description     NVARCHAR(256) NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Roles_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED (RoleId),
        CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName),
        CONSTRAINT CK_Roles_RoleName CHECK (LEN(TRIM(RoleName)) > 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Users' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Users (
        UserId          BIGINT IDENTITY(1,1) NOT NULL,
        Email           NVARCHAR(256) NOT NULL,
        PasswordHash    NVARCHAR(512) NOT NULL,
        FullName        NVARCHAR(200) NOT NULL,
        IsActive        BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Users_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        DeletedBy       BIGINT NULL,
        CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
        CONSTRAINT UQ_Users_Email UNIQUE (Email),
        CONSTRAINT CK_Users_Email CHECK (Email LIKE '%@%.%')
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'UserRoles' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.UserRoles (
        UserId  BIGINT NOT NULL,
        RoleId  INT NOT NULL,
        AssignedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserRoles_AssignedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_UserRoles PRIMARY KEY CLUSTERED (UserId, RoleId),
        CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_DeletedBy')
    ALTER TABLE dbo.Users
        ADD CONSTRAINT FK_Users_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserId);
GO

-- ============================================================
-- 02: Product Catalog & Suppliers
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ProductCategories' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.ProductCategories (
        CategoryId      INT IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(120) NOT NULL,
        ParentCategoryId INT NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_ProductCategories_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_ProductCategories PRIMARY KEY CLUSTERED (CategoryId),
        CONSTRAINT FK_ProductCategories_Parent FOREIGN KEY (ParentCategoryId)
            REFERENCES dbo.ProductCategories (CategoryId),
        CONSTRAINT UQ_ProductCategories_Name UNIQUE (Name)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Suppliers' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Suppliers (
        SupplierId      INT IDENTITY(1,1) NOT NULL,
        Name            NVARCHAR(200) NOT NULL,
        ContactName     NVARCHAR(120) NULL,
        Email           NVARCHAR(256) NULL,
        Phone           NVARCHAR(40) NULL,
        AddressLine     NVARCHAR(300) NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Suppliers_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_Suppliers PRIMARY KEY CLUSTERED (SupplierId),
        CONSTRAINT UQ_Suppliers_Name UNIQUE (Name)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Products' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Products (
        ProductId       INT IDENTITY(1,1) NOT NULL,
        Sku             NVARCHAR(64) NOT NULL,
        Name            NVARCHAR(200) NOT NULL,
        Description     NVARCHAR(MAX) NULL,
        CategoryId      INT NOT NULL,
        UnitOfMeasure   NVARCHAR(20) NOT NULL CONSTRAINT DF_Products_Uom DEFAULT (N'PCS'),
        UnitCost        DECIMAL(18,4) NOT NULL CONSTRAINT DF_Products_UnitCost DEFAULT (0),
        ListPrice       DECIMAL(18,4) NOT NULL CONSTRAINT DF_Products_ListPrice DEFAULT (0),
        ReorderLevel    INT NOT NULL CONSTRAINT DF_Products_ReorderLevel DEFAULT (0),
        SupplierId      INT NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Products_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (ProductId),
        CONSTRAINT UQ_Products_Sku UNIQUE (Sku),
        CONSTRAINT FK_Products_Category FOREIGN KEY (CategoryId) REFERENCES dbo.ProductCategories (CategoryId),
        CONSTRAINT FK_Products_Supplier FOREIGN KEY (SupplierId) REFERENCES dbo.Suppliers (SupplierId),
        CONSTRAINT CK_Products_UnitCost CHECK (UnitCost >= 0),
        CONSTRAINT CK_Products_ListPrice CHECK (ListPrice >= 0),
        CONSTRAINT CK_Products_ReorderLevel CHECK (ReorderLevel >= 0)
    );
END;
GO

-- ============================================================
-- 03: Locations
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Locations' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Locations (
        LocationId      INT IDENTITY(1,1) NOT NULL,
        Code            NVARCHAR(32) NOT NULL,
        Name            NVARCHAR(200) NOT NULL,
        LocationType    NVARCHAR(32) NOT NULL,
        AddressLine     NVARCHAR(300) NULL,
        IsActive        BIT NOT NULL CONSTRAINT DF_Locations_IsActive DEFAULT (1),
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Locations_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_Locations PRIMARY KEY CLUSTERED (LocationId),
        CONSTRAINT UQ_Locations_Code UNIQUE (Code),
        CONSTRAINT CK_Locations_Type CHECK (LocationType IN (N'WAREHOUSE', N'STORE', N'BRANCH_VAN'))
    );
END;
GO


-- ============================================================
-- 04: Inventory Stock
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'StockLevels' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.StockLevels (
        LocationId      INT NOT NULL,
        ProductId       INT NOT NULL,
        QuantityOnHand  INT NOT NULL,
        UpdatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_StockLevels_UpdatedAt DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_StockLevels PRIMARY KEY CLUSTERED (LocationId, ProductId),
        CONSTRAINT FK_StockLevels_Location FOREIGN KEY (LocationId) REFERENCES dbo.Locations (LocationId),
        CONSTRAINT FK_StockLevels_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
        CONSTRAINT CK_StockLevels_Qty CHECK (QuantityOnHand >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'StockMovements' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.StockMovements (
        MovementId      BIGINT IDENTITY(1,1) NOT NULL,
        ProductId       INT NOT NULL,
        LocationId      INT NOT NULL,
        QuantityDelta   INT NOT NULL,
        MovementType    NVARCHAR(32) NOT NULL,
        ReferenceType   NVARCHAR(32) NULL,
        ReferenceId     BIGINT NULL,
        Note            NVARCHAR(500) NULL,
        CreatedAt       DATETIME2(0) NOT NULL CONSTRAINT DF_StockMovements_CreatedAt DEFAULT (SYSDATETIME()),
        CreatedByUserId BIGINT NULL,
        CONSTRAINT PK_StockMovements PRIMARY KEY CLUSTERED (MovementId),
        CONSTRAINT FK_StockMovements_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
        CONSTRAINT FK_StockMovements_Location FOREIGN KEY (LocationId) REFERENCES dbo.Locations (LocationId),
        CONSTRAINT FK_StockMovements_User FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT CK_StockMovements_Type CHECK (MovementType IN (
            N'RECEIPT', N'SALE', N'ADJUSTMENT', N'TRANSFER_IN', N'TRANSFER_OUT', N'INITIAL'
        )),
        CONSTRAINT CK_StockMovements_Delta CHECK (QuantityDelta <> 0)
    );
END;
GO

-- ============================================================
-- 05: Customers & Sales
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Customers' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Customers (
        CustomerId      INT IDENTITY(1,1) NOT NULL,
        LinkedUserId    BIGINT NULL,
        Name            NVARCHAR(200) NOT NULL,
        Email           NVARCHAR(256) NULL,
        Phone           NVARCHAR(40) NULL,
        AddressLine     NVARCHAR(300) NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Customers_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerId),
        CONSTRAINT FK_Customers_Users FOREIGN KEY (LinkedUserId) REFERENCES dbo.Users (UserId)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SalesOrders' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.SalesOrders (
        SalesOrderId    BIGINT IDENTITY(1,1) NOT NULL,
        OrderNumber     NVARCHAR(32) NOT NULL,
        CustomerId      INT NOT NULL,
        OrderStatus     NVARCHAR(32) NOT NULL CONSTRAINT DF_SalesOrders_Status DEFAULT (N'DRAFT'),
        OrderDate       DATETIME2(0) NOT NULL CONSTRAINT DF_SalesOrders_OrderDate DEFAULT (SYSDATETIME()),
        LocationId      INT NOT NULL,
        CreatedByUserId BIGINT NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_SalesOrders_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_SalesOrders PRIMARY KEY CLUSTERED (SalesOrderId),
        CONSTRAINT UQ_SalesOrders_OrderNumber UNIQUE (OrderNumber),
        CONSTRAINT FK_SalesOrders_Customer FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (CustomerId),
        CONSTRAINT FK_SalesOrders_Location FOREIGN KEY (LocationId) REFERENCES dbo.Locations (LocationId),
        CONSTRAINT FK_SalesOrders_CreatedBy FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT CK_SalesOrders_Status CHECK (OrderStatus IN (N'DRAFT', N'CONFIRMED', N'SHIPPED', N'COMPLETED', N'CANCELLED'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SalesOrderLines' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.SalesOrderLines (
        SalesOrderLineId BIGINT IDENTITY(1,1) NOT NULL,
        SalesOrderId    BIGINT NOT NULL,
        LineNumber      INT NOT NULL,
        ProductId       INT NOT NULL,
        Quantity        INT NOT NULL,
        UnitPrice       DECIMAL(18,4) NOT NULL,
        LineTotal       AS (CAST(Quantity * UnitPrice AS DECIMAL(18,4))) PERSISTED,
        CONSTRAINT PK_SalesOrderLines PRIMARY KEY CLUSTERED (SalesOrderLineId),
        CONSTRAINT UQ_SalesOrderLines_OrderLine UNIQUE (SalesOrderId, LineNumber),
        CONSTRAINT FK_SalesOrderLines_Order FOREIGN KEY (SalesOrderId) REFERENCES dbo.SalesOrders (SalesOrderId),
        CONSTRAINT FK_SalesOrderLines_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
        CONSTRAINT CK_SalesOrderLines_Qty CHECK (Quantity > 0),
        CONSTRAINT CK_SalesOrderLines_Price CHECK (UnitPrice >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Invoices' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.Invoices (
        InvoiceId       BIGINT IDENTITY(1,1) NOT NULL,
        InvoiceNumber   NVARCHAR(32) NOT NULL,
        SalesOrderId    BIGINT NOT NULL,
        InvoiceDate     DATETIME2(0) NOT NULL CONSTRAINT DF_Invoices_InvoiceDate DEFAULT (SYSDATETIME()),
        SubTotal        DECIMAL(18,4) NOT NULL,
        TaxAmount       DECIMAL(18,4) NOT NULL CONSTRAINT DF_Invoices_Tax DEFAULT (0),
        TotalAmount     DECIMAL(18,4) NOT NULL,
        PaymentStatus   NVARCHAR(32) NOT NULL CONSTRAINT DF_Invoices_PayStatus DEFAULT (N'UNPAID'),
        IsDeleted       BIT NOT NULL CONSTRAINT DF_Invoices_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_Invoices PRIMARY KEY CLUSTERED (InvoiceId),
        CONSTRAINT UQ_Invoices_Number UNIQUE (InvoiceNumber),
        CONSTRAINT FK_Invoices_SalesOrder FOREIGN KEY (SalesOrderId) REFERENCES dbo.SalesOrders (SalesOrderId),
        CONSTRAINT CK_Invoices_SubTotal CHECK (SubTotal >= 0),
        CONSTRAINT CK_Invoices_Tax CHECK (TaxAmount >= 0),
        CONSTRAINT CK_Invoices_Total CHECK (TotalAmount >= 0),
        CONSTRAINT CK_Invoices_Payment CHECK (PaymentStatus IN (N'UNPAID', N'PARTIAL', N'PAID'))
    );
END;
GO

-- ============================================================
-- 06: Purchasing
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PurchaseOrders' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PurchaseOrders (
        PurchaseOrderId BIGINT IDENTITY(1,1) NOT NULL,
        PoNumber        NVARCHAR(32) NOT NULL,
        SupplierId      INT NOT NULL,
        LocationId      INT NOT NULL,
        OrderDate       DATETIME2(0) NOT NULL CONSTRAINT DF_PurchaseOrders_OrderDate DEFAULT (SYSDATETIME()),
        Status          NVARCHAR(32) NOT NULL CONSTRAINT DF_PurchaseOrders_Status DEFAULT (N'OPEN'),
        CreatedByUserId BIGINT NULL,
        IsDeleted       BIT NOT NULL CONSTRAINT DF_PurchaseOrders_IsDeleted DEFAULT (0),
        DeletedAt       DATETIME2(0) NULL,
        CONSTRAINT PK_PurchaseOrders PRIMARY KEY CLUSTERED (PurchaseOrderId),
        CONSTRAINT UQ_PurchaseOrders_PoNumber UNIQUE (PoNumber),
        CONSTRAINT FK_PurchaseOrders_Supplier FOREIGN KEY (SupplierId) REFERENCES dbo.Suppliers (SupplierId),
        CONSTRAINT FK_PurchaseOrders_Location FOREIGN KEY (LocationId) REFERENCES dbo.Locations (LocationId),
        CONSTRAINT FK_PurchaseOrders_User FOREIGN KEY (CreatedByUserId) REFERENCES dbo.Users (UserId),
        CONSTRAINT CK_PurchaseOrders_Status CHECK (Status IN (N'OPEN', N'PARTIAL', N'RECEIVED', N'CANCELLED'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PurchaseOrderLines' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.PurchaseOrderLines (
        PurchaseOrderLineId BIGINT IDENTITY(1,1) NOT NULL,
        PurchaseOrderId BIGINT NOT NULL,
        LineNumber      INT NOT NULL,
        ProductId       INT NOT NULL,
        QuantityOrdered INT NOT NULL,
        UnitCost        DECIMAL(18,4) NOT NULL,
        QuantityReceived INT NOT NULL CONSTRAINT DF_POLines_QtyRec DEFAULT (0),
        CONSTRAINT PK_PurchaseOrderLines PRIMARY KEY CLUSTERED (PurchaseOrderLineId),
        CONSTRAINT UQ_PurchaseOrderLines_OrderLine UNIQUE (PurchaseOrderId, LineNumber),
        CONSTRAINT FK_PurchaseOrderLines_PO FOREIGN KEY (PurchaseOrderId) REFERENCES dbo.PurchaseOrders (PurchaseOrderId),
        CONSTRAINT FK_PurchaseOrderLines_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
        CONSTRAINT CK_PurchaseOrderLines_QtyOrd CHECK (QuantityOrdered > 0),
        CONSTRAINT CK_PurchaseOrderLines_Cost CHECK (UnitCost >= 0),
        CONSTRAINT CK_PurchaseOrderLines_QtyRec CHECK (QuantityReceived >= 0 AND QuantityReceived <= QuantityOrdered)
    );
END;
GO


-- ============================================================
-- 07: Indexes
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Users_IsDeleted_Active')
    CREATE NONCLUSTERED INDEX IX_Users_IsDeleted_Active
        ON dbo.Users (IsDeleted, IsActive)
        INCLUDE (Email, FullName);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Products_Category_NotDeleted')
    CREATE NONCLUSTERED INDEX IX_Products_Category_NotDeleted
        ON dbo.Products (CategoryId, IsDeleted)
        INCLUDE (Sku, Name, ListPrice);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_StockMovements_Product_Location_Date')
    CREATE NONCLUSTERED INDEX IX_StockMovements_Product_Location_Date
        ON dbo.StockMovements (ProductId, LocationId, CreatedAt DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesOrders_Customer_Date')
    CREATE NONCLUSTERED INDEX IX_SalesOrders_Customer_Date
        ON dbo.SalesOrders (CustomerId, OrderDate DESC)
        INCLUDE (IsDeleted)
        WHERE IsDeleted = 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesOrderLines_Product')
    CREATE NONCLUSTERED INDEX IX_SalesOrderLines_Product
        ON dbo.SalesOrderLines (ProductId)
        INCLUDE (SalesOrderId, Quantity, UnitPrice);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_PurchaseOrders_Supplier_Status')
    CREATE NONCLUSTERED INDEX IX_PurchaseOrders_Supplier_Status
        ON dbo.PurchaseOrders (SupplierId, Status)
        INCLUDE (IsDeleted)
        WHERE IsDeleted = 0;
GO

-- ============================================================
-- Triggers
-- ============================================================
CREATE OR ALTER TRIGGER dbo.trg_Products_BlockDelete
ON dbo.Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET p.IsDeleted = 1,
        p.DeletedAt = SYSDATETIME()
    FROM dbo.Products p
    INNER JOIN deleted d ON d.ProductId = p.ProductId;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_StockMovements_AfterInsert_UpdateLevel
ON dbo.StockMovements
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.StockLevels AS T
    USING (
        SELECT ProductId, LocationId, SUM(QuantityDelta) AS DeltaQty
        FROM inserted
        GROUP BY ProductId, LocationId
    ) AS S
    ON T.ProductId = S.ProductId AND T.LocationId = S.LocationId
    WHEN MATCHED THEN
        UPDATE SET
            QuantityOnHand = T.QuantityOnHand + S.DeltaQty,
            UpdatedAt = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET AND S.DeltaQty > 0 THEN
        INSERT (LocationId, ProductId, QuantityOnHand)
        VALUES (S.LocationId, S.ProductId, S.DeltaQty);

    IF EXISTS (SELECT 1 FROM dbo.StockLevels WHERE QuantityOnHand < 0)
    BEGIN
        RAISERROR(N'Stock level would go negative; transaction rolled back.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- ============================================================
-- Views
-- ============================================================
CREATE OR ALTER VIEW dbo.vw_ActiveProductCatalog
AS
SELECT
    p.ProductId, p.Sku, p.Name, p.UnitOfMeasure, p.UnitCost, p.ListPrice, p.ReorderLevel,
    c.Name AS CategoryName,
    s.Name AS SupplierName
FROM dbo.Products p
INNER JOIN dbo.ProductCategories c ON c.CategoryId = p.CategoryId AND c.IsDeleted = 0
LEFT JOIN dbo.Suppliers s ON s.SupplierId = p.SupplierId AND s.IsDeleted = 0
WHERE p.IsDeleted = 0;
GO

CREATE OR ALTER VIEW dbo.vw_DeletedProducts
AS
SELECT ProductId, Sku, Name, CategoryId, DeletedAt
FROM dbo.Products
WHERE IsDeleted = 1;
GO

CREATE OR ALTER VIEW dbo.vw_InvoiceSummary
AS
SELECT
    inv.InvoiceId, inv.InvoiceNumber, inv.InvoiceDate, inv.PaymentStatus,
    so.OrderNumber, so.OrderStatus,
    c.Name AS CustomerName, c.Email AS CustomerEmail,
    l.Name AS FulfillingLocation,
    inv.SubTotal, inv.TaxAmount, inv.TotalAmount,
    u.FullName AS SalesRep
FROM dbo.Invoices inv
JOIN dbo.SalesOrders so ON so.SalesOrderId = inv.SalesOrderId
JOIN dbo.Customers c ON c.CustomerId = so.CustomerId
JOIN dbo.Locations l ON l.LocationId = so.LocationId
LEFT JOIN dbo.Users u ON u.UserId = so.CreatedByUserId
WHERE inv.IsDeleted = 0 AND so.IsDeleted = 0;
GO

CREATE OR ALTER VIEW dbo.vw_LowStockAlert
AS
SELECT
    p.ProductId, p.Sku, p.Name AS ProductName,
    pc.Name AS Category, s.Name AS Supplier,
    p.ReorderLevel,
    COALESCE(stock.TotalOnHand, 0) AS TotalOnHand,
    p.ReorderLevel - COALESCE(stock.TotalOnHand, 0) AS ShortfallQty
FROM dbo.Products p
LEFT JOIN dbo.ProductCategories pc ON pc.CategoryId = p.CategoryId
LEFT JOIN dbo.Suppliers s ON s.SupplierId = p.SupplierId
LEFT JOIN (
    SELECT ProductId, SUM(QuantityOnHand) AS TotalOnHand
    FROM dbo.StockLevels GROUP BY ProductId
) AS stock ON stock.ProductId = p.ProductId
WHERE p.IsDeleted = 0
  AND COALESCE(stock.TotalOnHand, 0) < p.ReorderLevel;
GO

CREATE OR ALTER VIEW dbo.vw_PurchaseOrderSummary
AS
SELECT
    po.PurchaseOrderId, po.PoNumber, po.OrderDate, po.Status,
    s.Name AS Supplier, l.Name AS ShipToLocation, u.FullName AS CreatedBy,
    COUNT(pol.PurchaseOrderLineId) AS LineCount,
    SUM(pol.QuantityOrdered) AS TotalQtyOrdered,
    SUM(pol.QuantityReceived) AS TotalQtyReceived,
    SUM(pol.QuantityOrdered * pol.UnitCost) AS TotalOrderedValue,
    SUM(pol.QuantityReceived * pol.UnitCost) AS TotalReceivedValue,
    CAST(CASE WHEN SUM(pol.QuantityOrdered) = 0 THEN 0
         ELSE 100.0 * SUM(pol.QuantityReceived) / SUM(pol.QuantityOrdered)
    END AS DECIMAL(5,2)) AS FulfilmentPct
FROM dbo.PurchaseOrders po
JOIN dbo.Suppliers s ON s.SupplierId = po.SupplierId
JOIN dbo.Locations l ON l.LocationId = po.LocationId
LEFT JOIN dbo.Users u ON u.UserId = po.CreatedByUserId
LEFT JOIN dbo.PurchaseOrderLines pol ON pol.PurchaseOrderId = po.PurchaseOrderId
WHERE po.IsDeleted = 0
GROUP BY po.PurchaseOrderId, po.PoNumber, po.OrderDate, po.Status, s.Name, l.Name, u.FullName;
GO

CREATE OR ALTER VIEW dbo.vw_SalesOrderSummary
AS
SELECT
    o.SalesOrderId, o.OrderNumber, o.OrderDate, o.OrderStatus,
    c.Name AS CustomerName, l.Name AS FulfillmentLocation,
    ISNULL(SUM(ln.Quantity * ln.UnitPrice), 0) AS LinesTotal
FROM dbo.SalesOrders o
INNER JOIN dbo.Customers c ON c.CustomerId = o.CustomerId AND c.IsDeleted = 0
INNER JOIN dbo.Locations l ON l.LocationId = o.LocationId AND l.IsDeleted = 0
LEFT JOIN dbo.SalesOrderLines ln ON ln.SalesOrderId = o.SalesOrderId
WHERE o.IsDeleted = 0
GROUP BY o.SalesOrderId, o.OrderNumber, o.OrderDate, o.OrderStatus, c.Name, l.Name;
GO

CREATE OR ALTER VIEW dbo.vw_StockMovementLog
AS
SELECT
    sm.MovementId, sm.CreatedAt,
    p.Sku, p.Name AS ProductName,
    l.Code AS LocationCode, l.Name AS LocationName,
    sm.QuantityDelta, sm.MovementType, sm.ReferenceType, sm.ReferenceId, sm.Note,
    u.FullName AS RecordedBy,
    sl.QuantityOnHand AS CurrentOnHand
FROM dbo.StockMovements sm
JOIN dbo.Products p ON p.ProductId = sm.ProductId
JOIN dbo.Locations l ON l.LocationId = sm.LocationId
LEFT JOIN dbo.Users u ON u.UserId = sm.CreatedByUserId
LEFT JOIN dbo.StockLevels sl ON sl.ProductId = sm.ProductId AND sl.LocationId = sm.LocationId;
GO


-- ============================================================
-- Seeds: Reference Data
-- ============================================================
SET NOCOUNT ON;
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

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = N'admin@ashcol.local')
    INSERT INTO dbo.Users (Email, PasswordHash, FullName)
    VALUES (N'admin@ashcol.local', N'PLACEHOLDER_HASH_REPLACE_ME', N'System Administrator');
GO

DECLARE @AdminId BIGINT = (SELECT UserId FROM dbo.Users WHERE Email = N'admin@ashcol.local');
DECLARE @RAdmin INT = (SELECT RoleId FROM dbo.Roles WHERE RoleName = N'Administrator');
IF @AdminId IS NOT NULL AND @RAdmin IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.UserRoles WHERE UserId = @AdminId AND RoleId = @RAdmin)
    INSERT INTO dbo.UserRoles (UserId, RoleId) VALUES (@AdminId, @RAdmin);
GO

MERGE dbo.ProductCategories AS T
USING (VALUES
    (N'HVAC Parts', NULL),(N'Refrigerants', NULL),(N'Consumables', NULL)
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
DECLARE @CatRef   INT = (SELECT CategoryId FROM dbo.ProductCategories WHERE Name = N'Refrigerants');
DECLARE @Sup1     INT = (SELECT SupplierId FROM dbo.Suppliers WHERE Name = N'Ashcol Preferred Vendor');

IF @CatParts IS NOT NULL AND @Sup1 IS NOT NULL
BEGIN
    MERGE dbo.Products AS T
    USING (VALUES
        (N'SKU-FILTER-001', N'AC Filter 1.5HP',    @CatParts, N'PCS', 120.0000, 199.0000, 20, @Sup1),
        (N'SKU-CAP-45',     N'Run Capacitor 45uF', @CatParts, N'PCS',  85.0000, 150.0000, 15, @Sup1)
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
DECLARE @Loc1  INT    = (SELECT LocationId FROM dbo.Locations WHERE Code = N'MWH-01');
INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
SELECT p.ProductId, @Loc1, 50, N'INITIAL', N'ADJUSTMENT', N'Seed opening balance', @Admin
FROM dbo.Products p
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.StockMovements m
    WHERE m.MovementType = N'INITIAL' AND m.ProductId = p.ProductId AND m.LocationId = @Loc1
);
GO

PRINT N'[setup] Reference seed complete.';
GO

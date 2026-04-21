-- =============================================================
-- AshcolInventory — Build Complete (fix missing objects)
-- Run this ONCE in SSMS to install all views, triggers, and
-- the warehouse star schema.
-- After this succeeds, run 03_seed_demo_transactions.sql next.
-- =============================================================

USE AshcolInventory;
GO

PRINT '========================================';
PRINT ' Step 1 of 4 — Creating / updating views';
PRINT '========================================';
GO

-- ── vw_ActiveProductCatalog ──────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_ActiveProductCatalog
AS
SELECT
    p.ProductId,
    p.Sku,
    p.Name,
    p.UnitOfMeasure,
    p.UnitCost,
    p.ListPrice,
    p.ReorderLevel,
    c.Name AS CategoryName,
    s.Name AS SupplierName
FROM dbo.Products p
INNER JOIN dbo.ProductCategories c ON c.CategoryId = p.CategoryId AND c.IsDeleted = 0
LEFT  JOIN dbo.Suppliers          s ON s.SupplierId  = p.SupplierId  AND s.IsDeleted = 0
WHERE p.IsDeleted = 0;
GO

-- ── vw_DeletedProducts ───────────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_DeletedProducts
AS
SELECT
    ProductId,
    Sku,
    Name,
    CategoryId,
    DeletedAt
FROM dbo.Products
WHERE IsDeleted = 1;
GO

-- ── vw_SalesOrderSummary ─────────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_SalesOrderSummary
AS
SELECT
    o.SalesOrderId,
    o.OrderNumber,
    o.OrderDate,
    o.OrderStatus,
    c.Name AS CustomerName,
    l.Name AS FulfillmentLocation,
    ISNULL(SUM(ln.Quantity * ln.UnitPrice), 0) AS LinesTotal
FROM dbo.SalesOrders       o
INNER JOIN dbo.Customers   c  ON c.CustomerId  = o.CustomerId  AND c.IsDeleted = 0
INNER JOIN dbo.Locations   l  ON l.LocationId  = o.LocationId  AND l.IsDeleted = 0
LEFT  JOIN dbo.SalesOrderLines ln ON ln.SalesOrderId = o.SalesOrderId
WHERE o.IsDeleted = 0
GROUP BY
    o.SalesOrderId, o.OrderNumber, o.OrderDate, o.OrderStatus,
    c.Name, l.Name;
GO

-- ── vw_LowStockAlert ─────────────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_LowStockAlert
AS
SELECT
    p.ProductId,
    p.Sku,
    p.Name                                          AS ProductName,
    pc.Name                                         AS Category,
    s.Name                                          AS Supplier,
    p.ReorderLevel,
    COALESCE(stock.TotalOnHand, 0)                  AS TotalOnHand,
    p.ReorderLevel - COALESCE(stock.TotalOnHand, 0) AS ShortfallQty
FROM dbo.Products AS p
LEFT JOIN dbo.ProductCategories AS pc ON pc.CategoryId = p.CategoryId
LEFT JOIN dbo.Suppliers         AS s  ON s.SupplierId  = p.SupplierId
LEFT JOIN (
    SELECT ProductId, SUM(QuantityOnHand) AS TotalOnHand
    FROM dbo.StockLevels
    GROUP BY ProductId
) AS stock ON stock.ProductId = p.ProductId
WHERE p.IsDeleted = 0
  AND COALESCE(stock.TotalOnHand, 0) < p.ReorderLevel;
GO

-- ── vw_PurchaseOrderSummary ──────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_PurchaseOrderSummary
AS
SELECT
    po.PurchaseOrderId,
    po.PoNumber,
    po.OrderDate,
    po.Status,
    s.Name                                       AS Supplier,
    l.Name                                       AS ShipToLocation,
    u.FullName                                   AS CreatedBy,
    COUNT(pol.PurchaseOrderLineId)               AS LineCount,
    SUM(pol.QuantityOrdered)                     AS TotalQtyOrdered,
    SUM(pol.QuantityReceived)                    AS TotalQtyReceived,
    SUM(pol.QuantityOrdered  * pol.UnitCost)     AS TotalOrderedValue,
    SUM(pol.QuantityReceived * pol.UnitCost)     AS TotalReceivedValue,
    CAST(
        CASE
            WHEN SUM(pol.QuantityOrdered) = 0 THEN 0
            ELSE 100.0 * SUM(pol.QuantityReceived) / SUM(pol.QuantityOrdered)
        END AS DECIMAL(5,2)
    )                                            AS FulfilmentPct
FROM dbo.PurchaseOrders          AS po
JOIN  dbo.Suppliers              AS s   ON s.SupplierId  = po.SupplierId
JOIN  dbo.Locations              AS l   ON l.LocationId  = po.LocationId
LEFT  JOIN dbo.Users             AS u   ON u.UserId      = po.CreatedByUserId
LEFT  JOIN dbo.PurchaseOrderLines AS pol ON pol.PurchaseOrderId = po.PurchaseOrderId
WHERE po.IsDeleted = 0
GROUP BY
    po.PurchaseOrderId, po.PoNumber, po.OrderDate, po.Status,
    s.Name, l.Name, u.FullName;
GO

-- ── vw_InvoiceSummary ────────────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_InvoiceSummary
AS
SELECT
    inv.InvoiceId,
    inv.InvoiceNumber,
    inv.InvoiceDate,
    inv.PaymentStatus,
    so.OrderNumber,
    so.OrderStatus,
    c.Name                  AS CustomerName,
    c.Email                 AS CustomerEmail,
    l.Name                  AS FulfillingLocation,
    inv.SubTotal,
    inv.TaxAmount,
    inv.TotalAmount,
    u.FullName              AS SalesRep
FROM dbo.Invoices           AS inv
JOIN  dbo.SalesOrders       AS so  ON so.SalesOrderId  = inv.SalesOrderId
JOIN  dbo.Customers         AS c   ON c.CustomerId      = so.CustomerId
JOIN  dbo.Locations         AS l   ON l.LocationId      = so.LocationId
LEFT  JOIN dbo.Users        AS u   ON u.UserId          = so.CreatedByUserId
WHERE inv.IsDeleted = 0
  AND so.IsDeleted  = 0;
GO

-- ── vw_StockMovementLog ──────────────────────────────────────
CREATE OR ALTER VIEW dbo.vw_StockMovementLog
AS
SELECT
    sm.MovementId,
    sm.CreatedAt,
    p.Sku,
    p.Name                  AS ProductName,
    l.Code                  AS LocationCode,
    l.Name                  AS LocationName,
    sm.QuantityDelta,
    sm.MovementType,
    sm.ReferenceType,
    sm.ReferenceId,
    sm.Note,
    u.FullName              AS RecordedBy,
    sl.QuantityOnHand       AS CurrentOnHand
FROM dbo.StockMovements     AS sm
JOIN  dbo.Products          AS p   ON p.ProductId   = sm.ProductId
JOIN  dbo.Locations         AS l   ON l.LocationId  = sm.LocationId
LEFT  JOIN dbo.Users        AS u   ON u.UserId      = sm.CreatedByUserId
LEFT  JOIN dbo.StockLevels  AS sl  ON sl.ProductId  = sm.ProductId
                                   AND sl.LocationId = sm.LocationId;
GO

PRINT 'Views OK';
GO

-- =============================================================
PRINT '=========================================';
PRINT ' Step 2 of 4 — Creating / updating triggers';
PRINT '=========================================';
GO
-- =============================================================

-- ── trg_Products_BlockDelete (soft-delete guard) ─────────────
CREATE OR ALTER TRIGGER dbo.trg_Products_BlockDelete
ON dbo.Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET    p.IsDeleted = 1,
           p.DeletedAt = SYSDATETIME()
    FROM   dbo.Products p
    INNER JOIN deleted  d ON d.ProductId = p.ProductId;
END;
GO

-- ── trg_StockMovements_AfterInsert_UpdateLevel ───────────────
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
    ON T.ProductId  = S.ProductId
   AND T.LocationId = S.LocationId
    WHEN MATCHED THEN
        UPDATE SET
            QuantityOnHand = T.QuantityOnHand + S.DeltaQty,
            UpdatedAt      = SYSDATETIME()
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

PRINT 'Triggers OK';
GO

-- =============================================================
PRINT '==================================================';
PRINT ' Step 3 of 4 — Star schema (dw) — safe CREATE';
PRINT '==================================================';
GO
-- =============================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'dw')
    EXEC(N'CREATE SCHEMA dw');
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dw.dim_date'))
BEGIN
    CREATE TABLE dw.dim_date (
        DateKey     INT  NOT NULL,
        FullDate    DATE NOT NULL,
        YearNo      INT  NOT NULL,
        MonthNo     INT  NOT NULL,
        DayNo       INT  NOT NULL,
        CONSTRAINT PK_dim_date       PRIMARY KEY CLUSTERED (DateKey),
        CONSTRAINT UQ_dim_date_Full  UNIQUE (FullDate)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dw.dim_product'))
BEGIN
    CREATE TABLE dw.dim_product (
        ProductKey   INT IDENTITY(1,1) NOT NULL,
        ProductId    INT           NOT NULL,
        Sku          NVARCHAR(64)  NOT NULL,
        CategoryName NVARCHAR(120) NULL,
        SupplierName NVARCHAR(200) NULL,
        ValidFrom    DATE          NOT NULL,
        ValidTo      DATE          NULL,
        CONSTRAINT PK_dim_product PRIMARY KEY CLUSTERED (ProductKey)
    );
    CREATE NONCLUSTERED INDEX IX_dim_product_ProductId ON dw.dim_product (ProductId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dw.dim_customer'))
BEGIN
    CREATE TABLE dw.dim_customer (
        CustomerKey INT IDENTITY(1,1) NOT NULL,
        CustomerId  INT           NOT NULL,
        Name        NVARCHAR(200) NOT NULL,
        ValidFrom   DATE          NOT NULL,
        ValidTo     DATE          NULL,
        CONSTRAINT PK_dim_customer PRIMARY KEY CLUSTERED (CustomerKey)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dw.dim_location'))
BEGIN
    CREATE TABLE dw.dim_location (
        LocationKey  INT IDENTITY(1,1) NOT NULL,
        LocationId   INT          NOT NULL,
        Code         NVARCHAR(32) NOT NULL,
        LocationType NVARCHAR(32) NOT NULL,
        CONSTRAINT PK_dim_location PRIMARY KEY CLUSTERED (LocationKey)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dw.fact_sales_line'))
BEGIN
    CREATE TABLE dw.fact_sales_line (
        SalesOrderLineId BIGINT        NOT NULL,
        DateKey          INT           NOT NULL,
        ProductKey       INT           NOT NULL,
        CustomerKey      INT           NOT NULL,
        LocationKey      INT           NOT NULL,
        Quantity         INT           NOT NULL,
        UnitPrice        DECIMAL(18,4) NOT NULL,
        LineAmount       DECIMAL(18,4) NOT NULL,
        CONSTRAINT PK_fact_sales_line       PRIMARY KEY CLUSTERED (SalesOrderLineId),
        CONSTRAINT FK_fact_date             FOREIGN KEY (DateKey)     REFERENCES dw.dim_date     (DateKey),
        CONSTRAINT FK_fact_product          FOREIGN KEY (ProductKey)  REFERENCES dw.dim_product  (ProductKey),
        CONSTRAINT FK_fact_customer         FOREIGN KEY (CustomerKey) REFERENCES dw.dim_customer (CustomerKey),
        CONSTRAINT FK_fact_location         FOREIGN KEY (LocationKey) REFERENCES dw.dim_location (LocationKey)
    );
    CREATE NONCLUSTERED INDEX NCI_fact_sales_line_Analytics
        ON dw.fact_sales_line (DateKey, ProductKey, CustomerKey, LocationKey)
        INCLUDE (Quantity, LineAmount);
END
GO

PRINT 'Star schema (dw) OK';
GO

-- =============================================================
PRINT '====================================================';
PRINT ' Step 4 of 4 — Verify: list all views and triggers';
PRINT '====================================================';
GO
-- =============================================================

SELECT
    type_desc AS ObjectType,
    name      AS ObjectName,
    SCHEMA_NAME(schema_id) AS SchemaName
FROM sys.objects
WHERE type IN ('V', 'TR')
  AND SCHEMA_NAME(schema_id) = 'dbo'
ORDER BY type_desc, name;

SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS TableName
FROM sys.tables
WHERE schema_id = SCHEMA_ID('dw')
ORDER BY name;

PRINT '';
PRINT '================================================';
PRINT ' BUILD COMPLETE.';
PRINT ' Now open and run:';
PRINT '   inventory/seeds/03_seed_demo_transactions.sql';
PRINT ' Then re-run: inventory/tests/run_all_tests.sql';
PRINT '================================================';
GO

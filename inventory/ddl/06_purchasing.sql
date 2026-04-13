-- Module: Purchasing (replenishment)
USE AshcolInventory;
GO

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
GO

CREATE TABLE dbo.PurchaseOrderLines (
    PurchaseOrderLineId BIGINT IDENTITY(1,1) NOT NULL,
    PurchaseOrderId BIGINT NOT NULL,
    LineNo          INT NOT NULL,
    ProductId       INT NOT NULL,
    QuantityOrdered INT NOT NULL,
    UnitCost        DECIMAL(18,4) NOT NULL,
    QuantityReceived INT NOT NULL CONSTRAINT DF_POLines_QtyRec DEFAULT (0),
    CONSTRAINT PK_PurchaseOrderLines PRIMARY KEY CLUSTERED (PurchaseOrderLineId),
    CONSTRAINT UQ_PurchaseOrderLines_OrderLine UNIQUE (PurchaseOrderId, LineNo),
    CONSTRAINT FK_PurchaseOrderLines_PO FOREIGN KEY (PurchaseOrderId) REFERENCES dbo.PurchaseOrders (PurchaseOrderId),
    CONSTRAINT FK_PurchaseOrderLines_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_PurchaseOrderLines_QtyOrd CHECK (QuantityOrdered > 0),
    CONSTRAINT CK_PurchaseOrderLines_Cost CHECK (UnitCost >= 0),
    CONSTRAINT CK_PurchaseOrderLines_QtyRec CHECK (QuantityReceived >= 0 AND QuantityReceived <= QuantityOrdered)
);
GO

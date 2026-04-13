-- Modules: Customers, Sales orders, Invoicing
USE AshcolInventory;
GO

CREATE TABLE dbo.Customers (
    CustomerId      INT IDENTITY(1,1) NOT NULL,
    LinkedUserId    BIGINT NULL, -- optional link to Users (e.g. Standard User)
    Name            NVARCHAR(200) NOT NULL,
    Email           NVARCHAR(256) NULL,
    Phone           NVARCHAR(40) NULL,
    AddressLine     NVARCHAR(300) NULL,
    IsDeleted       BIT NOT NULL CONSTRAINT DF_Customers_IsDeleted DEFAULT (0),
    DeletedAt       DATETIME2(0) NULL,
    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerId),
    CONSTRAINT FK_Customers_Users FOREIGN KEY (LinkedUserId) REFERENCES dbo.Users (UserId)
);
GO

CREATE TABLE dbo.SalesOrders (
    SalesOrderId    BIGINT IDENTITY(1,1) NOT NULL,
    OrderNumber     NVARCHAR(32) NOT NULL,
    CustomerId      INT NOT NULL,
    OrderStatus     NVARCHAR(32) NOT NULL CONSTRAINT DF_SalesOrders_Status DEFAULT (N'DRAFT'),
    OrderDate       DATETIME2(0) NOT NULL CONSTRAINT DF_SalesOrders_OrderDate DEFAULT (SYSDATETIME()),
    LocationId      INT NOT NULL, -- fulfilling location
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
GO

CREATE TABLE dbo.SalesOrderLines (
    SalesOrderLineId BIGINT IDENTITY(1,1) NOT NULL,
    SalesOrderId    BIGINT NOT NULL,
    LineNo          INT NOT NULL,
    ProductId       INT NOT NULL,
    Quantity        INT NOT NULL,
    UnitPrice       DECIMAL(18,4) NOT NULL,
    LineTotal       AS (CAST(Quantity * UnitPrice AS DECIMAL(18,4))) PERSISTED,
    CONSTRAINT PK_SalesOrderLines PRIMARY KEY CLUSTERED (SalesOrderLineId),
    CONSTRAINT UQ_SalesOrderLines_OrderLine UNIQUE (SalesOrderId, LineNo),
    CONSTRAINT FK_SalesOrderLines_Order FOREIGN KEY (SalesOrderId) REFERENCES dbo.SalesOrders (SalesOrderId),
    CONSTRAINT FK_SalesOrderLines_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_SalesOrderLines_Qty CHECK (Quantity > 0),
    CONSTRAINT CK_SalesOrderLines_Price CHECK (UnitPrice >= 0)
);
GO

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
GO

-- Modules: Product catalog, Suppliers
USE AshcolInventory;
GO

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
GO

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
GO

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
GO

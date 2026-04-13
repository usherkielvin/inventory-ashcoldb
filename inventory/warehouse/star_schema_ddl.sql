-- Analytical layer: star schema (separate schema `dw` in the same database)
-- ETL: INSERT/UPDATE from operational tables (scheduled job or SSIS — out of scope here)

USE AshcolInventory;
GO

CREATE SCHEMA dw;
GO

CREATE TABLE dw.dim_date (
    DateKey         INT NOT NULL,          -- YYYYMMDD
    FullDate        DATE NOT NULL,
    YearNo          INT NOT NULL,
    MonthNo         INT NOT NULL,
    DayNo           INT NOT NULL,
    CONSTRAINT PK_dim_date PRIMARY KEY CLUSTERED (DateKey),
    CONSTRAINT UQ_dim_date_FullDate UNIQUE (FullDate)
);
GO

CREATE TABLE dw.dim_product (
    ProductKey      INT IDENTITY(1,1) NOT NULL,
    ProductId       INT NOT NULL,
    Sku             NVARCHAR(64) NOT NULL,
    CategoryName    NVARCHAR(120) NULL,
    SupplierName    NVARCHAR(200) NULL,
    ValidFrom       DATE NOT NULL,
    ValidTo         DATE NULL,
    CONSTRAINT PK_dim_product PRIMARY KEY CLUSTERED (ProductKey)
);
GO

CREATE NONCLUSTERED INDEX IX_dim_product_ProductId ON dw.dim_product (ProductId);
GO

CREATE TABLE dw.dim_customer (
    CustomerKey     INT IDENTITY(1,1) NOT NULL,
    CustomerId      INT NOT NULL,
    Name            NVARCHAR(200) NOT NULL,
    ValidFrom       DATE NOT NULL,
    ValidTo         DATE NULL,
    CONSTRAINT PK_dim_customer PRIMARY KEY CLUSTERED (CustomerKey)
);
GO

CREATE TABLE dw.dim_location (
    LocationKey     INT IDENTITY(1,1) NOT NULL,
    LocationId      INT NOT NULL,
    Code            NVARCHAR(32) NOT NULL,
    LocationType    NVARCHAR(32) NOT NULL,
    CONSTRAINT PK_dim_location PRIMARY KEY CLUSTERED (LocationKey)
);
GO

CREATE TABLE dw.fact_sales_line (
    SalesOrderLineId BIGINT NOT NULL,
    DateKey         INT NOT NULL,
    ProductKey      INT NOT NULL,
    CustomerKey     INT NOT NULL,
    LocationKey     INT NOT NULL,
    Quantity        INT NOT NULL,
    UnitPrice       DECIMAL(18,4) NOT NULL,
    LineAmount      DECIMAL(18,4) NOT NULL,
    CONSTRAINT PK_fact_sales_line PRIMARY KEY CLUSTERED (SalesOrderLineId),
    CONSTRAINT FK_fact_sales_line_date FOREIGN KEY (DateKey) REFERENCES dw.dim_date (DateKey),
    CONSTRAINT FK_fact_sales_line_product FOREIGN KEY (ProductKey) REFERENCES dw.dim_product (ProductKey),
    CONSTRAINT FK_fact_sales_line_customer FOREIGN KEY (CustomerKey) REFERENCES dw.dim_customer (CustomerKey),
    CONSTRAINT FK_fact_sales_line_location FOREIGN KEY (LocationKey) REFERENCES dw.dim_location (LocationKey)
);
GO

-- Nonclustered index for analytical filters (use COLUMNSTORE on editions that support it)
CREATE NONCLUSTERED INDEX NCI_fact_sales_line_Analytics
    ON dw.fact_sales_line (DateKey, ProductKey, CustomerKey, LocationKey)
    INCLUDE (Quantity, LineAmount);
GO

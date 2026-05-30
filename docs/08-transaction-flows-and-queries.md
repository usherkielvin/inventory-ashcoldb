# 8. Transaction Flows and Database Schema Reference

This document maps out the logical transaction flows and provides the complete physical database schema (DDL) for the **AshcolInventory** system. It also includes standard query diagnostics to select and display table joins from users to roles, products, sales, and purchasing workloads.

---

## 8.1 Transaction Flowchart

The following flowchart outlines the relationship lifecycle of transactions within the RDBMS. It demonstrates how user roles (RBAC) govern master catalog setup, which in turn feeds into stock replenishment (Purchasing), sales billing (Sales & Invoicing), and installation/maintenance services (Service Operations).

```mermaid
graph TD
    %% Roles & Users (RBAC)
    subgraph Identity & Access (RBAC)
        Roles[Roles Table]
        Users[Users Table]
        UserRoles[UserRoles Table]
        Roles -->|M:N mapping| UserRoles
        Users -->|M:N mapping| UserRoles
    end

    %% Inventory Master Data
    subgraph Master Catalog
        ProductCategories[ProductCategories Table]
        Suppliers[Suppliers Table]
        Products[Products Table]
        Locations[Locations Table]
        ProductCategories -->|Classifies| Products
        Suppliers -->|Supplies| Products
    end

    %% Stock & Movement Control
    subgraph Stock Ledger
        StockLevels[StockLevels Table]
        StockMovements[StockMovements Table]
        Products -->|FK| StockLevels
        Locations -->|FK| StockLevels
        Products -->|FK| StockMovements
        Locations -->|FK| StockMovements
        StockMovements -->|Trigger maintains| StockLevels
    end

    %% Purchasing Workflows
    subgraph Purchasing & Replenishment
        PurchaseOrders[PurchaseOrders Table]
        PurchaseOrderLines[PurchaseOrderLines Table]
        PurchaseOrders -->|Contains| PurchaseOrderLines
        Suppliers -->|Receives PO| PurchaseOrders
        Products -->|Ordered Item| PurchaseOrderLines
        PurchaseOrders -->|Trigger/API| StockMovements : "Receipt"
    end

    %% Sales & Billing Workflows
    subgraph Sales & Invoicing
        Customers[Customers Table]
        SalesOrders[SalesOrders Table]
        SalesOrderLines[SalesOrderLines Table]
        Invoices[Invoices Table]
        Customers -->|Places| SalesOrders
        SalesOrders -->|Contains| SalesOrderLines
        SalesOrders -->|Billed as| Invoices
        Products -->|Sold Item| SalesOrderLines
        SalesOrders -->|Trigger/API| StockMovements : "Sale"
    end

    %% Service Workflows
    subgraph Service Operations
        ServiceJobs[ServiceJobs Table]
        ServiceJobMaterials[ServiceJobMaterials Table]
        ServiceJobs -->|Contains| ServiceJobMaterials
        Customers -->|Request service| ServiceJobs
        Products -->|Required material| ServiceJobMaterials
        ServiceJobs -->|Trigger/API| StockMovements : "Service Deduction"
    end
```

---

## 8.2 Database Schema (DDL)

Below is the complete physical table structure deployed to **SQL Server**.

### 8.2.1 Identity and Access Control

```sql
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
    CONSTRAINT CK_Users_Email CHECK (Email LIKE '%@%.%'),
    CONSTRAINT FK_Users_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserId)
);

CREATE TABLE dbo.UserRoles (
    UserId          BIGINT NOT NULL,
    RoleId          INT NOT NULL,
    AssignedAt      DATETIME2(0) NOT NULL CONSTRAINT DF_UserRoles_AssignedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_UserRoles PRIMARY KEY CLUSTERED (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId)
);
```

### 8.2.2 Inventory Master Data

```sql
CREATE TABLE dbo.ProductCategories (
    CategoryId      INT IDENTITY(1,1) NOT NULL,
    Name            NVARCHAR(120) NOT NULL,
    ParentCategoryId INT NULL,
    IsDeleted       BIT NOT NULL CONSTRAINT DF_ProductCategories_IsDeleted DEFAULT (0),
    DeletedAt       DATETIME2(0) NULL,
    CONSTRAINT PK_ProductCategories PRIMARY KEY CLUSTERED (CategoryId),
    CONSTRAINT FK_ProductCategories_Parent FOREIGN KEY (ParentCategoryId) REFERENCES dbo.ProductCategories (CategoryId),
    CONSTRAINT UQ_ProductCategories_Name UNIQUE (Name)
);

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
```

### 8.2.3 Stock Ledger

```sql
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
    CONSTRAINT CK_StockMovements_Type CHECK (MovementType IN (N'RECEIPT', N'SALE', N'ADJUSTMENT', N'TRANSFER_IN', N'TRANSFER_OUT', N'INITIAL')),
    CONSTRAINT CK_StockMovements_Delta CHECK (QuantityDelta <> 0)
);
```

### 8.2.4 Customers & Sales Transactions

```sql
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
```

### 8.2.5 Purchasing & Replenishment

```sql
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
```

### 8.2.6 Service Jobs

```sql
CREATE TABLE dbo.ServiceJobs (
    JobId               BIGINT IDENTITY(1,1) NOT NULL,
    JobNumber           NVARCHAR(32) NOT NULL,
    CustomerId          INT NOT NULL,
    LocationId          INT NOT NULL,
    ManagedByUserId     BIGINT NULL,
    AssigneeName        NVARCHAR(200) NULL,
    JobStatus           NVARCHAR(32) NOT NULL CONSTRAINT DF_ServiceJobs_Status DEFAULT (N'PENDING'),
    ScheduledDate       DATETIME2(0) NOT NULL,
    CompletedDate       DATETIME2(0) NULL,
    Notes               NVARCHAR(500) NULL,
    IsDeleted           BIT NOT NULL CONSTRAINT DF_ServiceJobs_IsDeleted DEFAULT (0),
    DeletedAt           DATETIME2(0) NULL,
    CreatedAt           DATETIME2(0) NOT NULL CONSTRAINT DF_ServiceJobs_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_ServiceJobs PRIMARY KEY CLUSTERED (JobId),
    CONSTRAINT UQ_ServiceJobs_Number UNIQUE (JobNumber),
    CONSTRAINT FK_ServiceJobs_Customer FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (CustomerId),
    CONSTRAINT FK_ServiceJobs_Location FOREIGN KEY (LocationId) REFERENCES dbo.Locations (LocationId),
    CONSTRAINT FK_ServiceJobs_Manager FOREIGN KEY (ManagedByUserId) REFERENCES dbo.Users (UserId),
    CONSTRAINT CK_ServiceJobs_Status CHECK (JobStatus IN (N'PENDING', N'IN_PROGRESS', N'COMPLETED', N'CANCELLED'))
);

CREATE TABLE dbo.ServiceJobMaterials (
    JobMaterialId       BIGINT IDENTITY(1,1) NOT NULL,
    JobId               BIGINT NOT NULL,
    LineNumber          INT NOT NULL,
    ProductId           INT NOT NULL,
    QuantityRequired    INT NOT NULL,
    QuantityUsed        INT NULL,
    CONSTRAINT PK_ServiceJobMaterials PRIMARY KEY CLUSTERED (JobMaterialId),
    CONSTRAINT UQ_ServiceJobMaterials_Line UNIQUE (JobId, LineNumber),
    CONSTRAINT FK_ServiceJobMaterials_Job FOREIGN KEY (JobId) REFERENCES dbo.ServiceJobs (JobId),
    CONSTRAINT FK_ServiceJobMaterials_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_ServiceJobMaterials_QtyReq CHECK (QuantityRequired > 0)
);
```

---

## 8.3 Join Diagnostic Queries

These queries illustrate how different transaction components relate to each other by linking foreign keys across schemas.

### 8.3.1 Users to Roles (RBAC mapping)
Use this query to show which users have been assigned which permissions within the system.

```sql
SELECT 
    u.UserId, 
    u.FullName, 
    u.Email, 
    u.IsActive,
    r.RoleName, 
    r.Description AS RoleDescription,
    ur.AssignedAt
FROM dbo.Users u
INNER JOIN dbo.UserRoles ur ON u.UserId = ur.UserId
INNER JOIN dbo.Roles r ON ur.RoleId = r.RoleId
WHERE u.IsDeleted = 0 AND r.IsDeleted = 0;
```

### 8.3.2 Catalog Mapping (Products, Categories, and Suppliers)
Determines which category classifies each product, alongside its default replenishment supplier.

```sql
SELECT 
    p.ProductId, 
    p.Sku, 
    p.Name AS ProductName, 
    p.UnitOfMeasure,
    c.Name AS CategoryName, 
    s.Name AS DefaultSupplierName, 
    p.UnitCost,
    p.ListPrice,
    p.ReorderLevel
FROM dbo.Products p
INNER JOIN dbo.ProductCategories c ON p.CategoryId = c.CategoryId
LEFT JOIN dbo.Suppliers s ON p.SupplierId = s.SupplierId
WHERE p.IsDeleted = 0;
```

### 8.3.3 Current Stock Levels by Location
Shows exact quantity on hand of each product inside each specific warehouse or branch location.

```sql
SELECT 
    l.Code AS LocationCode, 
    l.Name AS LocationName, 
    l.LocationType,
    p.Sku, 
    p.Name AS ProductName, 
    sl.QuantityOnHand,
    sl.UpdatedAt
FROM dbo.StockLevels sl
INNER JOIN dbo.Locations l ON sl.LocationId = l.LocationId
INNER JOIN dbo.Products p ON sl.ProductId = p.ProductId
WHERE l.IsActive = 1 AND p.IsDeleted = 0
ORDER BY l.Code, p.Sku;
```

### 8.3.4 Sales Orders & Customer Lines
Fetches sales orders, who purchased them, which location fulfilled them, and the specific items that comprised each order.

```sql
SELECT 
    so.OrderNumber, 
    so.OrderDate, 
    so.OrderStatus, 
    c.Name AS CustomerName, 
    l.Name AS FulfilledFrom,
    sol.LineNumber,
    p.Sku, 
    p.Name AS ProductName,
    sol.Quantity, 
    sol.UnitPrice, 
    sol.LineTotal
FROM dbo.SalesOrders so
INNER JOIN dbo.Customers c ON so.CustomerId = c.CustomerId
INNER JOIN dbo.Locations l ON so.LocationId = l.LocationId
INNER JOIN dbo.SalesOrderLines sol ON so.SalesOrderId = sol.SalesOrderId
INNER JOIN dbo.Products p ON sol.ProductId = p.ProductId
WHERE so.IsDeleted = 0
ORDER BY so.OrderDate DESC, sol.LineNumber;
```

### 8.3.5 Invoices Linked to Sales Orders & Customers
Summarizes billing details including base subtotal, tax collection (VAT), and final amounts linked directly back to sales agreements.

```sql
SELECT 
    inv.InvoiceNumber, 
    inv.InvoiceDate, 
    inv.PaymentStatus, 
    so.OrderNumber, 
    c.Name AS CustomerName, 
    inv.SubTotal, 
    inv.TaxAmount, 
    inv.TotalAmount,
    u.FullName AS SalesRep
FROM dbo.Invoices inv
INNER JOIN dbo.SalesOrders so ON inv.SalesOrderId = so.SalesOrderId
INNER JOIN dbo.Customers c ON so.CustomerId = c.CustomerId
LEFT JOIN dbo.Users u ON so.CreatedByUserId = u.UserId
WHERE inv.IsDeleted = 0
ORDER BY inv.InvoiceDate DESC;
```

### 8.3.6 Purchase Orders & Supplier Replenishments
Inspects restock orders, which suppliers they were sent to, how many items are expected, and how many have been received so far.

```sql
SELECT 
    po.PoNumber, 
    po.OrderDate, 
    po.Status AS PoStatus, 
    s.Name AS SupplierName, 
    l.Name AS ReceivingWarehouse,
    pol.LineNumber,
    p.Sku, 
    p.Name AS ProductName,
    pol.QuantityOrdered, 
    pol.QuantityReceived,
    pol.UnitCost,
    u.FullName AS CreatedBy
FROM dbo.PurchaseOrders po
INNER JOIN dbo.Suppliers s ON po.SupplierId = s.SupplierId
INNER JOIN dbo.Locations l ON po.LocationId = l.LocationId
INNER JOIN dbo.PurchaseOrderLines pol ON po.PurchaseOrderId = pol.PurchaseOrderId
INNER JOIN dbo.Products p ON pol.ProductId = p.ProductId
LEFT JOIN dbo.Users u ON po.CreatedByUserId = u.UserId
WHERE po.IsDeleted = 0
ORDER BY po.OrderDate DESC, pol.LineNumber;
```

### 8.3.7 Service Jobs & Material Consumptions
Retrieves maintenance work orders, assigned technicians, customer details, and the items pulled from inventory for the repairs.

```sql
SELECT 
    sj.JobNumber, 
    sj.JobStatus, 
    sj.ScheduledDate,
    c.Name AS CustomerName, 
    l.Name AS PullingFromLocation,
    sj.AssigneeName AS Technician,
    sjm.LineNumber,
    p.Sku, 
    p.Name AS MaterialName,
    sjm.QuantityRequired, 
    sjm.QuantityUsed,
    p.UnitCost AS MaterialCost
FROM dbo.ServiceJobs sj
INNER JOIN dbo.Customers c ON sj.CustomerId = c.CustomerId
INNER JOIN dbo.Locations l ON sj.LocationId = l.LocationId
INNER JOIN dbo.ServiceJobMaterials sjm ON sj.JobId = sjm.JobId
INNER JOIN dbo.Products p ON sjm.ProductId = p.ProductId
WHERE sj.IsDeleted = 0
ORDER BY sj.CreatedAt DESC, sjm.LineNumber;
```

-- Module: Warehouse / location master
USE AshcolInventory;
GO

CREATE TABLE dbo.Locations (
    LocationId      INT IDENTITY(1,1) NOT NULL,
    Code            NVARCHAR(32) NOT NULL,
    Name            NVARCHAR(200) NOT NULL,
    LocationType    NVARCHAR(32) NOT NULL, -- WAREHOUSE, STORE, BRANCH_VAN
    AddressLine     NVARCHAR(300) NULL,
    IsActive        BIT NOT NULL CONSTRAINT DF_Locations_IsActive DEFAULT (1),
    IsDeleted       BIT NOT NULL CONSTRAINT DF_Locations_IsDeleted DEFAULT (0),
    DeletedAt       DATETIME2(0) NULL,
    CONSTRAINT PK_Locations PRIMARY KEY CLUSTERED (LocationId),
    CONSTRAINT UQ_Locations_Code UNIQUE (Code),
    CONSTRAINT CK_Locations_Type CHECK (LocationType IN (N'WAREHOUSE', N'STORE', N'BRANCH_VAN'))
);
GO

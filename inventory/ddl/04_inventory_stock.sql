-- Module: Stock levels + movement ledger (3NF: movements are facts; balance is per location-product)
USE AshcolInventory;
GO

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
GO

CREATE TABLE dbo.StockMovements (
    MovementId      BIGINT IDENTITY(1,1) NOT NULL,
    ProductId       INT NOT NULL,
    LocationId      INT NOT NULL,
    QuantityDelta   INT NOT NULL, -- positive = in, negative = out
    MovementType    NVARCHAR(32) NOT NULL,
    ReferenceType   NVARCHAR(32) NULL, -- SALES_ORDER, PURCHASE_ORDER, ADJUSTMENT, TRANSFER
    ReferenceId       BIGINT NULL,
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
GO

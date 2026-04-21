-- ============================================================
-- Module: Service Jobs (Installation / Service Work Orders)
-- Ashcol Airconditioning Inventory System
--
-- ServiceJobs   : work order header (manager-managed)
-- ServiceJobMaterials : Bill of Materials per job
--
-- On completion, API inserts StockMovements (SALE / SERVICE_JOB)
-- which the TRIGGER trg_StockMovements_AfterInsert_UpdateLevel
-- uses to automatically deduct from StockLevels.
-- ============================================================
USE AshcolInventory;
GO

CREATE TABLE dbo.ServiceJobs (
    JobId               BIGINT IDENTITY(1,1) NOT NULL,
    JobNumber           NVARCHAR(32) NOT NULL,
    CustomerId          INT NOT NULL,
    LocationId          INT NOT NULL,                          -- stock pulled from this location
    ManagedByUserId     BIGINT NULL,                           -- manager who owns the job
    AssigneeName        NVARCHAR(200) NULL,                    -- technician free-text name
    JobStatus           NVARCHAR(32) NOT NULL
        CONSTRAINT DF_ServiceJobs_Status DEFAULT (N'PENDING'),
    ScheduledDate       DATETIME2(0) NOT NULL,
    CompletedDate       DATETIME2(0) NULL,
    Notes               NVARCHAR(500) NULL,
    IsDeleted           BIT NOT NULL
        CONSTRAINT DF_ServiceJobs_IsDeleted DEFAULT (0),
    DeletedAt           DATETIME2(0) NULL,
    CreatedAt           DATETIME2(0) NOT NULL
        CONSTRAINT DF_ServiceJobs_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_ServiceJobs PRIMARY KEY CLUSTERED (JobId),
    CONSTRAINT UQ_ServiceJobs_Number UNIQUE (JobNumber),
    CONSTRAINT FK_ServiceJobs_Customer
        FOREIGN KEY (CustomerId) REFERENCES dbo.Customers (CustomerId),
    CONSTRAINT FK_ServiceJobs_Location
        FOREIGN KEY (LocationId) REFERENCES dbo.Locations (LocationId),
    CONSTRAINT FK_ServiceJobs_Manager
        FOREIGN KEY (ManagedByUserId) REFERENCES dbo.Users (UserId),
    CONSTRAINT CK_ServiceJobs_Status
        CHECK (JobStatus IN (N'PENDING', N'IN_PROGRESS', N'COMPLETED', N'CANCELLED'))
);
GO

CREATE TABLE dbo.ServiceJobMaterials (
    JobMaterialId       BIGINT IDENTITY(1,1) NOT NULL,
    JobId               BIGINT NOT NULL,
    LineNumber          INT NOT NULL,
    ProductId           INT NOT NULL,
    QuantityRequired    INT NOT NULL,
    QuantityUsed        INT NULL,                              -- filled on completion
    CONSTRAINT PK_ServiceJobMaterials PRIMARY KEY CLUSTERED (JobMaterialId),
    CONSTRAINT UQ_ServiceJobMaterials_Line UNIQUE (JobId, LineNumber),
    CONSTRAINT FK_ServiceJobMaterials_Job
        FOREIGN KEY (JobId) REFERENCES dbo.ServiceJobs (JobId),
    CONSTRAINT FK_ServiceJobMaterials_Product
        FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_ServiceJobMaterials_QtyReq
        CHECK (QuantityRequired > 0)
);
GO

PRINT N'[ddl] ServiceJobs + ServiceJobMaterials tables created.';
GO

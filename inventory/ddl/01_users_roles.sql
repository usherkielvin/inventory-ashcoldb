-- Module: User & Role Management (mandatory)
USE AshcolInventory;
GO

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
GO

CREATE TABLE dbo.Users (
    UserId          BIGINT IDENTITY(1,1) NOT NULL,
    Email           NVARCHAR(256) NOT NULL,
    PasswordHash    NVARCHAR(512) NOT NULL, -- store hash only, never plain text
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
GO

CREATE TABLE dbo.UserRoles (
    UserId  BIGINT NOT NULL,
    RoleId  INT NOT NULL,
    AssignedAt DATETIME2(0) NOT NULL CONSTRAINT DF_UserRoles_AssignedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_UserRoles PRIMARY KEY CLUSTERED (UserId, RoleId),
    CONSTRAINT FK_UserRoles_Users FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId),
    CONSTRAINT FK_UserRoles_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles (RoleId)
);
GO

ALTER TABLE dbo.Users
    ADD CONSTRAINT FK_Users_DeletedBy FOREIGN KEY (DeletedBy) REFERENCES dbo.Users (UserId);
GO

-- Prevent physical DELETE on Products; use soft delete (IsDeleted) from application layer.
USE AshcolInventory;
GO

CREATE OR ALTER TRIGGER dbo.trg_Products_BlockDelete
ON dbo.Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Optional: mark soft-deleted instead of blocking
    UPDATE p
    SET p.IsDeleted = 1,
        p.DeletedAt = SYSDATETIME()
    FROM dbo.Products p
    INNER JOIN deleted d ON d.ProductId = p.ProductId;
END;
GO

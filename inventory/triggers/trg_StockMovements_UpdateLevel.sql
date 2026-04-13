-- After each movement row, adjust StockLevels (same transaction as insert).
USE AshcolInventory;
GO

CREATE OR ALTER TRIGGER dbo.trg_StockMovements_AfterInsert_UpdateLevel
ON dbo.StockMovements
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.StockLevels AS T
    USING (
        SELECT ProductId, LocationId, SUM(QuantityDelta) AS DeltaQty
        FROM inserted
        GROUP BY ProductId, LocationId
    ) AS S
    ON T.ProductId = S.ProductId AND T.LocationId = S.LocationId
    WHEN MATCHED THEN
        UPDATE SET
            QuantityOnHand = T.QuantityOnHand + S.DeltaQty,
            UpdatedAt = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET AND S.DeltaQty > 0 THEN
        INSERT (LocationId, ProductId, QuantityOnHand)
        VALUES (S.LocationId, S.ProductId, S.DeltaQty);

    IF EXISTS (SELECT 1 FROM dbo.StockLevels WHERE QuantityOnHand < 0)
    BEGIN
        RAISERROR(N'Stock level would go negative; transaction rolled back.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- Demo: explicit transaction, isolation level, COMMIT / ROLLBACK
-- Run step-by-step in SSMS; inspect results between batches.

USE AshcolInventory;
GO

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Alternatives for coursework narrative: REPEATABLE READ, SERIALIZABLE

BEGIN TRANSACTION;

BEGIN TRY
    UPDATE dbo.Products
    SET ListPrice = ListPrice + 1
    WHERE Sku = N'SKU-FILTER-001';

    -- Uncomment to simulate business rule failure:
    -- RAISERROR(N'Demo rollback', 16, 1);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- View: Stock movement log (human-readable)
-- Joins StockMovements with product/location/user names so SSMS results
-- are immediately readable without manual joins.

USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_StockMovementLog
AS
SELECT
    sm.MovementId,
    sm.CreatedAt,
    p.Sku,
    p.Name                  AS ProductName,
    l.Code                  AS LocationCode,
    l.Name                  AS LocationName,
    sm.QuantityDelta,
    sm.MovementType,
    sm.ReferenceType,
    sm.ReferenceId,
    sm.Note,
    u.FullName              AS RecordedBy,
    -- Running balance is expensive on large tables; include on-hand snapshot instead
    sl.QuantityOnHand       AS CurrentOnHand
FROM dbo.StockMovements     AS sm
JOIN dbo.Products           AS p   ON p.ProductId   = sm.ProductId
JOIN dbo.Locations          AS l   ON l.LocationId  = sm.LocationId
LEFT JOIN dbo.Users         AS u   ON u.UserId      = sm.CreatedByUserId
LEFT JOIN dbo.StockLevels   AS sl  ON sl.ProductId  = sm.ProductId
                                   AND sl.LocationId = sm.LocationId;
GO

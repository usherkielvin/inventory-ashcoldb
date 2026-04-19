-- View: Purchase order summary
-- Summarises each PO header with supplier, ship-to location, line count,
-- total ordered value, total received value, and fulfilment %.

USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_PurchaseOrderSummary
AS
SELECT
    po.PurchaseOrderId,
    po.PoNumber,
    po.OrderDate,
    po.Status,
    s.Name                                      AS Supplier,
    l.Name                                      AS ShipToLocation,
    u.FullName                                  AS CreatedBy,
    COUNT(pol.PurchaseOrderLineId)              AS LineCount,
    SUM(pol.QuantityOrdered)                    AS TotalQtyOrdered,
    SUM(pol.QuantityReceived)                   AS TotalQtyReceived,
    SUM(pol.QuantityOrdered * pol.UnitCost)     AS TotalOrderedValue,
    SUM(pol.QuantityReceived * pol.UnitCost)    AS TotalReceivedValue,
    CAST(
        CASE
            WHEN SUM(pol.QuantityOrdered) = 0 THEN 0
            ELSE 100.0 * SUM(pol.QuantityReceived) / SUM(pol.QuantityOrdered)
        END AS DECIMAL(5,2)
    )                                           AS FulfilmentPct
FROM dbo.PurchaseOrders         AS po
JOIN dbo.Suppliers              AS s   ON s.SupplierId  = po.SupplierId
JOIN dbo.Locations              AS l   ON l.LocationId  = po.LocationId
LEFT JOIN dbo.Users             AS u   ON u.UserId      = po.CreatedByUserId
LEFT JOIN dbo.PurchaseOrderLines AS pol ON pol.PurchaseOrderId = po.PurchaseOrderId
WHERE po.IsDeleted = 0
GROUP BY
    po.PurchaseOrderId, po.PoNumber, po.OrderDate, po.Status,
    s.Name, l.Name, u.FullName;
GO

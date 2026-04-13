USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_SalesOrderSummary
AS
SELECT
    o.SalesOrderId,
    o.OrderNumber,
    o.OrderDate,
    o.OrderStatus,
    c.Name AS CustomerName,
    l.Name AS FulfillmentLocation,
    ISNULL(SUM(ln.Quantity * ln.UnitPrice), 0) AS LinesTotal
FROM dbo.SalesOrders o
INNER JOIN dbo.Customers c ON c.CustomerId = o.CustomerId AND c.IsDeleted = 0
INNER JOIN dbo.Locations l ON l.LocationId = o.LocationId AND l.IsDeleted = 0
LEFT JOIN dbo.SalesOrderLines ln ON ln.SalesOrderId = o.SalesOrderId
WHERE o.IsDeleted = 0
GROUP BY
    o.SalesOrderId, o.OrderNumber, o.OrderDate, o.OrderStatus,
    c.Name, l.Name;
GO

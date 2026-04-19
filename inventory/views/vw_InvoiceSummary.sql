-- View: Invoice summary
-- Shows each invoice with linked sales order, customer, invoice date,
-- amounts, and payment status.  Supports the billing/reporting module.

USE AshcolInventory;
GO

CREATE OR ALTER VIEW dbo.vw_InvoiceSummary
AS
SELECT
    inv.InvoiceId,
    inv.InvoiceNumber,
    inv.InvoiceDate,
    inv.PaymentStatus,
    so.OrderNumber,
    so.OrderStatus,
    c.Name                  AS CustomerName,
    c.Email                 AS CustomerEmail,
    l.Name                  AS FulfillingLocation,
    inv.SubTotal,
    inv.TaxAmount,
    inv.TotalAmount,
    u.FullName              AS SalesRep
FROM dbo.Invoices           AS inv
JOIN dbo.SalesOrders        AS so  ON so.SalesOrderId  = inv.SalesOrderId
JOIN dbo.Customers          AS c   ON c.CustomerId     = so.CustomerId
JOIN dbo.Locations          AS l   ON l.LocationId     = so.LocationId
LEFT JOIN dbo.Users         AS u   ON u.UserId         = so.CreatedByUserId
WHERE inv.IsDeleted = 0
  AND so.IsDeleted  = 0;
GO

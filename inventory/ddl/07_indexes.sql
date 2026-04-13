-- Nonclustered indexes (clustered indexes are primary keys on each table)
USE AshcolInventory;
GO

CREATE NONCLUSTERED INDEX IX_Users_IsDeleted_Active
    ON dbo.Users (IsDeleted, IsActive)
    INCLUDE (Email, FullName);
GO

CREATE NONCLUSTERED INDEX IX_Products_Category_NotDeleted
    ON dbo.Products (CategoryId, IsDeleted)
    INCLUDE (Sku, Name, ListPrice);
GO

CREATE NONCLUSTERED INDEX IX_StockMovements_Product_Location_Date
    ON dbo.StockMovements (ProductId, LocationId, CreatedAt DESC);
GO

CREATE NONCLUSTERED INDEX IX_SalesOrders_Customer_Date
    ON dbo.SalesOrders (CustomerId, OrderDate DESC)
    WHERE IsDeleted = 0;
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderLines_Product
    ON dbo.SalesOrderLines (ProductId)
    INCLUDE (SalesOrderId, Quantity, UnitPrice);
GO

CREATE NONCLUSTERED INDEX IX_PurchaseOrders_Supplier_Status
    ON dbo.PurchaseOrders (SupplierId, Status)
    WHERE IsDeleted = 0;
GO

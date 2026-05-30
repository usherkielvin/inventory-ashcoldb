-- 1. Identity & Access Control (RBAC)
SELECT * FROM dbo.Roles;
SELECT * FROM dbo.Users;
SELECT * FROM dbo.UserRoles;

-- 2. Master Catalog & Locations
SELECT * FROM dbo.ProductCategories;
SELECT * FROM dbo.Suppliers;
SELECT * FROM dbo.Products;
SELECT * FROM dbo.Locations;

-- 3. Stock Ledger
SELECT * FROM dbo.StockLevels;
SELECT * FROM dbo.StockMovements;

-- 4. Sales & Invoicing
SELECT * FROM dbo.Customers;
SELECT * FROM dbo.SalesOrders;
SELECT * FROM dbo.SalesOrderLines;
SELECT * FROM dbo.Invoices;

-- 5. Purchasing & Replenishment
SELECT * FROM dbo.PurchaseOrders;
SELECT * FROM dbo.PurchaseOrderLines;

-- 6. Service Operations
SELECT * FROM dbo.ServiceJobs;
SELECT * FROM dbo.ServiceJobMaterials;

-- OLAP-style reporting using ROLLUP / CUBE (no SSAS required for class demos)
USE AshcolInventory;
GO

-- Sales by month and category (operational tables — works before dw ETL is populated)
SELECT
    YEAR(o.OrderDate) AS OrderYear,
    MONTH(o.OrderDate) AS OrderMonth,
    c.Name AS CategoryName,
    SUM(ln.Quantity) AS UnitsSold,
    SUM(ln.Quantity * ln.UnitPrice) AS Revenue
FROM dbo.SalesOrders o
INNER JOIN dbo.SalesOrderLines ln ON ln.SalesOrderId = o.SalesOrderId
INNER JOIN dbo.Products p ON p.ProductId = ln.ProductId AND p.IsDeleted = 0
INNER JOIN dbo.ProductCategories c ON c.CategoryId = p.CategoryId AND c.IsDeleted = 0
WHERE o.IsDeleted = 0
GROUP BY ROLLUP (
    YEAR(o.OrderDate),
    MONTH(o.OrderDate),
    c.Name
)
ORDER BY OrderYear, OrderMonth, CategoryName;
GO

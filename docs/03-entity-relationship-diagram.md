# 3. Entity-relationship diagram (ERD)

## Diagram

![AshcolInventory ERD](assets/erd.png)

> Mermaid source below — paste into [Mermaid Live](https://mermaid.live) or export to PNG/PDF for your submission if your instructor requires a standalone diagram file.

```mermaid
erDiagram
    Roles ||--o{ UserRoles : assigns
    Users ||--o{ UserRoles : has
    Users ||--o| Users : "DeletedBy"

    ProductCategories ||--o{ ProductCategories : parent
    ProductCategories ||--o{ Products : classifies
    Suppliers ||--o{ Products : supplies

    Locations ||--o{ StockLevels : holds
    Products ||--o{ StockLevels : stocked_as
    Products ||--o{ StockMovements : moves
    Locations ||--o{ StockMovements : at
    Users ||--o{ StockMovements : records

    Users ||--o| Customers : "LinkedUser optional"
    Customers ||--o{ SalesOrders : places
    Locations ||--o{ SalesOrders : fulfills
    Users ||--o{ SalesOrders : creates
    SalesOrders ||--|{ SalesOrderLines : contains
    Products ||--o{ SalesOrderLines : line_item

    SalesOrders ||--o{ Invoices : billed_as

    Suppliers ||--o{ PurchaseOrders : receives_po
    Locations ||--o{ PurchaseOrders : ship_to
    Users ||--o{ PurchaseOrders : creates
    PurchaseOrders ||--|{ PurchaseOrderLines : contains
    Products ||--o{ PurchaseOrderLines : line_item
```

## Relationship summary

| Relationship | Cardinality | Notes |
|--------------|-------------|--------|
| Users — UserRoles — Roles | M:N | RBAC |
| Products — ProductCategories | N:1 | Optional parent category self-FK |
| StockLevels | (Location, Product) | Composite PK |
| StockMovements | Many per product/location | Ledger |
| SalesOrders — SalesOrderLines | 1:N | |
| PurchaseOrders — PurchaseOrderLines | 1:N | |

For the **warehouse** star schema, see [`inventory/warehouse/star_schema_ddl.sql`](../inventory/warehouse/star_schema_ddl.sql) (facts and dimensions).

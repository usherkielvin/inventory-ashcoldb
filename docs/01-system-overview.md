# 1. System overview

**Ashcol Inventory & Sales** is a relational database blueprint for managing HVAC-oriented **parts**, **warehouse locations**, **stock movements**, **suppliers**, **purchase orders**, **customers**, **sales orders**, and **invoices**. It includes **role-based identities** (Administrator, Staff, Standard User) and **soft deletion** on core entities.

- **DBMS:** Microsoft SQL Server  
- **Database name:** `AshcolInventory`  
- **Repository:** [inventory-ashcoldb](https://github.com/usherkielvin/inventory-ashcoldb)  
- **Implementation assets:** T-SQL under [`inventory/`](../inventory/) (DDL, seeds, views, triggers, transactions, warehouse)

The design supports **CRUD** via application or ad hoc SQL, enforces **referential integrity**, and separates **operational** tables from an optional **`dw` star schema** for reporting and OLAP-style queries.

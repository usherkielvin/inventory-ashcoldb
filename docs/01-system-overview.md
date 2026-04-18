# 1. System overview

**Ashcol Inventory & Sales** is a relational database blueprint for managing HVAC-oriented **parts**, **warehouse locations**, **stock movements**, **suppliers**, **purchase orders**, **customers**, **sales orders**, and **invoices**. It includes **role-based identities** (Administrator, Staff, Standard User) and **soft deletion** on core entities.

- **DBMS:** Microsoft SQL Server  
- **Database name:** `AshcolInventory`  
- **Repository:** [inventory-ashcoldb](https://github.com/usherkielvin/inventory-ashcoldb)  
- **Implementation assets:** T-SQL under [`inventory/`](../inventory/) (DDL, seeds, views, triggers, transactions, warehouse)  
- **Required client (project):** **SQL Server Management Studio (SSMS)** — use SSMS to deploy scripts, run ad hoc **CRUD** and report queries, verify objects in **Object Explorer**, and capture output for **testing procedures** ([`05-testing-procedures.md`](05-testing-procedures.md)). This matches the course expectation of an **MS SQL Server** backend built and exercised through the standard Microsoft tooling.

The design supports **CRUD** via application or ad hoc SQL, enforces **referential integrity**, and separates **operational** tables from an optional **`dw` star schema** for reporting and OLAP-style queries.

**Boundary:** This blueprint targets **SQL Server** only. Other systems (for example a separate web stack with MySQL) are **out of scope** for this repository; you may reuse **ideas** from the ERD and modules when designing elsewhere, without implying a shared database or deployment.

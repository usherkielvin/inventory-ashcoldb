# Course RDBMS requirements — reference (Inventory)

This document maps the **Database System Project** syllabus expectations to **this repository only**: the **Inventory & Sales Management** blueprint on **Microsoft SQL Server** (`AshcolInventory`). It is **not** a replacement for your graded write-ups; use it as a checklist while you complete **§1 System overview** through **§5 Testing** in this `docs/` folder.

**Separate repo, separate database:** This project is graded as its own **MS SQL Server** implementation. Any **Ashcol** web portal or Spring API lives in **other repositories** and uses **a different database engine and schema** (for example MySQL for the running app). There is **no requirement** to connect or sync them. If you mention Ashcol at all, treat overlap as **business context and design ideas only**—not a shared runtime or single “source of truth” across stacks.

---

## I. System choice

| Syllabus option | This project |
|-----------------|----------------|
| **Inventory & Sales Management System** | **Selected.** Operational scope: product catalog, suppliers, locations, stock ledger, customers, sales, purchasing, invoicing, reporting, user/role identities. |

Other listed systems (hospital, university, e-commerce, etc.) are **out of scope** for this repository.

---

## II. General requirements

| Requirement | How it is addressed (inventory focus) |
|-------------|----------------------------------------|
| **RDBMS** | SQL Server database with related tables, constraints, and executable T-SQL under [`inventory/`](../inventory/). |
| **≥ 10 modules** | Documented across [`inventory/modules/`](../inventory/modules/) and summarized in [`README.md`](../README.md) (users/roles, catalog, suppliers, locations, stock, customers, sales, purchasing, invoicing, reporting/warehouse). **User & Role Management** is mandatory and implemented via `Roles`, `Users`, `UserRoles`. |
| **Normalization (≥ 3NF)** | Described in [`04-database-schema-design.md`](04-database-schema-design.md); line items normalized into `SalesOrderLines`, `PurchaseOrderLines`, etc. |
| **MS SQL Server** | All DDL, seeds, views, triggers, and demos target SQL Server. |
| **Implementation & testing tool** | **SQL Server Management Studio (SSMS)** — required to run scripts in order, perform **CRUD** and report queries against `AshcolInventory`, and produce evidence for [`05-testing-procedures.md`](05-testing-procedures.md) (results grids, messages, Object Explorer checks). Aligns with **platform: MS SQL Server** in the project specification. |
| **ERD** | [`03-entity-relationship-diagram.md`](03-entity-relationship-diagram.md) (and any diagram assets your course requires). |
| **Soft deletion** | `IsDeleted` / `DeletedAt` (and related patterns) on core entities; e.g. `vw_DeletedProducts`, trigger blocking hard delete on `Products` where implemented. |
| **Backend implementation** | Required: scripts in [`inventory/ddl/`](../inventory/ddl/), [`views/`](../inventory/views/), [`triggers/`](../inventory/triggers/), [`seeds/`](../inventory/seeds/). **Frontend optional** per syllabus; a small static explainer exists in [`demo/`](../demo/). Any third-party app that shows similar wording is **documentation only** and does not use this SQL Server database unless you deliberately build that integration. |

---

## III. Functional requirements

| Requirement | Inventory implementation pointers |
|-------------|-----------------------------------|
| **CRUD on major entities** | Tables support insert/update/select; soft delete favors `UPDATE` over physical `DELETE` where triggers apply. Exercise CRUD via SSMS or parameterized app queries. |
| **Authentication & RBAC** | Seed roles align with **Administrator**, **Staff**, **Standard User**; `Users` + `UserRoles` model. Real login and JWT/session handling live in whatever **application** you build; they are **not** defined by this T-SQL repo alone. |
| **Business transactions + validation** | `CHECK` constraints, FKs, and triggers (e.g. stock non-negative). See [`transactions/01_transaction_demo.sql`](../inventory/transactions/01_transaction_demo.sql). |
| **Operational & analytical reporting** | Views such as `vw_ActiveProductCatalog`, `vw_SalesOrderSummary`; OLAP samples under [`inventory/warehouse/`](../inventory/warehouse/). |
| **Integrity (PK, FK, UNIQUE, CHECK)** | Declared in DDL scripts under [`inventory/ddl/`](../inventory/ddl/). |
| **Triggers** | [`inventory/triggers/`](../inventory/triggers/) (e.g. stock maintenance, soft-delete guard). |
| **Views** | [`inventory/views/`](../inventory/views/). |
| **Clustered & nonclustered indexes** | Clustered = PKs by default; extra indexes in [`07_indexes.sql`](../inventory/ddl/07_indexes.sql). |
| **Concurrency** | SQL Server concurrent sessions; isolation and deadlock exercises in [`inventory/transactions/`](../inventory/transactions/). |

---

## IV. Non-functional requirements

| Theme | Practical alignment (inventory) |
|-------|----------------------------------|
| **Performance** | Indexes + sensible join paths via views; document any `SET STATISTICS IO`/plan analysis you run for the course. |
| **Scalability** | Normalized design; index strategy documented in schema design doc. |
| **Security** | RBAC at data model; row-level security not required unless your instructor adds it. Application tiers enforce access on **their** database separately from this SQL Server project. |
| **Reliability & availability** | Constraints + triggers + transactions; HA clustering is out of scope unless specified. |
| **ACID** | Use explicit `BEGIN TRAN` / `COMMIT` / `ROLLBACK` in demos; document isolation behavior where required. |

---

## V. Advanced design requirements

| Topic | Where it lives |
|-------|----------------|
| **≥ 10 related tables** | See table list in [`04-database-schema-design.md`](04-database-schema-design.md) (operational `dbo` exceeds minimum). |
| **Relationships** | FK graph in ERD doc and DDL. |
| **Clustered / nonclustered indexes** | [`07_indexes.sql`](../inventory/ddl/07_indexes.sql). |
| **Transaction management** | [`01_transaction_demo.sql`](../inventory/transactions/01_transaction_demo.sql). |
| **Isolation levels** | Covered in transaction lab materials under [`inventory/transactions/`](../inventory/transactions/). |
| **Deadlock simulation** | [`02_deadlock_lab.md`](../inventory/transactions/02_deadlock_lab.md). |
| **Distributed DB simulation** | [`03_distributed_database_simulation.md`](../inventory/transactions/03_distributed_database_simulation.md). |
| **Data warehouse / star schema** | [`star_schema_ddl.sql`](../inventory/warehouse/star_schema_ddl.sql), samples in same folder. |
| **OLAP-style reporting** | [`olap_reporting_samples.sql`](../inventory/warehouse/olap_reporting_samples.sql). |

---

## VI. Documentation mapping (submission bundle)

| Required deliverable | This repo |
|---------------------|-----------|
| **System overview** | [`01-system-overview.md`](01-system-overview.md) |
| **Scope and limitations** | [`02-scope-and-limitations.md`](02-scope-and-limitations.md) |
| **ERD** | [`03-entity-relationship-diagram.md`](03-entity-relationship-diagram.md) |
| **Database schema design** | [`04-database-schema-design.md`](04-database-schema-design.md) |
| **Testing procedures and results** | [`05-testing-procedures.md`](05-testing-procedures.md) — paste **your** run outputs/screenshots there. |

---

## Optional: same problem domain elsewhere (ideas only)

- **This repository:** Evidence for the **RDBMS** subject — **SQL Server**, `AshcolInventory`, scripts under `inventory/`.
- **Other apps (e.g. a company portal):** May use **another DBMS** and **other table names**. They might borrow **concepts** (products, locations, stock ledger, orders) from your ERD and module list when designing **their** schema; that design work is **not** part of this repo unless you choose to copy ideas manually.
- **No default integration:** Do not assume one connection string, one migration pipeline, or one deployment spans both. Keep submissions and grading boundaries clear.

When writing narratives, cite this file if helpful, then point readers to **`docs/01`–`05`** for the technical content of **this** database project.

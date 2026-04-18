# Ashcol Inventory & Sales — Database Blueprint

Relational database blueprint for an **Inventory & Sales Management** system on **Microsoft SQL Server**. Domain wording (parts, locations, warehouses, sales) is **inspiration only** and does **not** imply this database is attached to the Ashcol web app, which uses a **different** DBMS and schema.

**Remote repository:** [github.com/usherkielvin/inventory-ashcoldb](https://github.com/usherkielvin/inventory-ashcoldb)

## Repository layout

| Path | Purpose |
|------|--------|
| [`docs/`](docs/) | Course documentation; **full SSMS setup:** [`docs/07-ssms-database-setup-from-scratch.md`](docs/07-ssms-database-setup-from-scratch.md); syllabus mapping: [`docs/00-course-requirements-reference-inventory.md`](docs/00-course-requirements-reference-inventory.md) |
| [`inventory/`](inventory/) | All executable SQL and warehouse artifacts (DDL, seeds, views, triggers, demos) |
| [`web/`](web/) | **Optional:** React (Vite) + Express API — first `cd web` then `npm run bootstrap` once, then `npm run dev`; see [`web/README.md`](web/README.md) |

## Prerequisites (required for this project)

Per the **RDBMS / database project** specification (**MS SQL Server** implementation and documented testing):

| Requirement | Notes |
|-------------|--------|
| **Microsoft SQL Server** | 2019+ (Express, Developer, or Azure SQL) hosting `AshcolInventory`. |
| **SQL Server Management Studio (SSMS)** | **Required** primary tool: open and run all `.sql` scripts in order, run verification queries, capture **Results** grids and messages for [`docs/05-testing-procedures.md`](docs/05-testing-procedures.md), and use **Object Explorer** to confirm tables, views, triggers, and indexes. |

Azure Data Studio may be used only if your instructor explicitly allows it as a substitute; otherwise document everything using **SSMS**.

## Quick start (SSMS)

**First-time setup (step by step):** use **[`docs/07-ssms-database-setup-from-scratch.md`](docs/07-ssms-database-setup-from-scratch.md)** — install, mixed mode / login, script order, verification, and fixing the optional web API when “nothing shows.”

Short version:

1. Install **SSMS** and **SQL Server** if not already installed.
2. Open **SSMS** → connect to `(local)` or `localhost\SQLEXPRESS` (your instance).
3. Run scripts in order from [`inventory/README.md`](inventory/README.md): DDL `00`–`07` → **views** → **triggers** → **seeds**.
4. Press **F5** in each opened file; fix errors before continuing.
5. Run the verification `SELECT` in doc **07** or **`docs/05-testing-procedures.md`**.

## Functional modules (10+)

1. User & role management (mandatory)  
2. Product catalog & categories  
3. Supplier management  
4. Warehouse / location master  
5. Stock levels & movements (inventory ledger)  
6. Customer master  
7. Sales orders & line items  
8. Purchasing (PO) & receiving  
9. Invoicing (sales billing)  
10. Reporting views & star-schema (analytical)  

## Separation from other projects

This repository is the **MS SQL Server** deliverable for the **database / RDBMS** subject. Any web portal or Spring API uses **its own database** (for example MySQL elsewhere). Reuse here is **conceptual only**—entity names, modules, and normalization ideas—not a shared connection string or mirrored deployment.

## License

Use for academic / capstone purposes unless otherwise specified.

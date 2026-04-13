# Ashcol Inventory & Sales — Database Blueprint

Relational database blueprint for an **Inventory & Sales Management** system on **Microsoft SQL Server**, aligned with the Ashcol capstone domain (parts, locations, branch-style warehouses, sales).

**Remote repository:** [github.com/usherkielvin/inventory-ashcoldb](https://github.com/usherkielvin/inventory-ashcoldb)

## Repository layout

| Path | Purpose |
|------|--------|
| [`docs/`](docs/) | Course documentation: overview, scope, ERD, schema narrative, testing notes |
| [`inventory/`](inventory/) | All executable SQL and warehouse artifacts (DDL, seeds, views, triggers, demos) |

## Prerequisites

- **SQL Server** 2019+ (Express or Developer) or **Azure SQL**
- **SSMS** or **Azure Data Studio** to run scripts in dependency order

## Quick start

1. Open SSMS, connect to your instance.
2. Run scripts in order (see [`inventory/README.md`](inventory/README.md)).
3. Adjust file paths or database name in `inventory/ddl/00_create_database.sql` if needed.

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

## Capstone alignment

This database is the **source of truth design** you can later **port** to PostgreSQL + Spring Flyway for the main Ashcol API. Conceptual entities (products, locations, stock, orders) should match; T-SQL remains specific to this course repo.

## License

Use for academic / capstone purposes unless otherwise specified.

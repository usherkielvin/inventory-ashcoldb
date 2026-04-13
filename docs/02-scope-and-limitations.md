# 2. Scope and limitations

## In scope

- Normalized operational schema (**3NF** target) with **15** related tables.
- **Soft delete** flags and **restore** path via `UPDATE` (plus `vw_DeletedProducts` for catalog).
- **Triggers:** soft-delete on `Products` delete attempt; **stock level** maintenance on `StockMovements` insert.
- **Views** for catalog abstraction and sales summaries.
- **Indexes:** clustered PKs; additional **nonclustered** indexes in `inventory/ddl/07_indexes.sql`.
- **Transactions** demo and lab notes for **isolation** and **deadlock**.
- **Star schema** (`dw`) and **ROLLUP** sample for analytical reporting.

## Out of scope (typical for a first DB course delivery)

- Full application UI (optional per syllabus); password hashing implementation left to application layer (`PasswordHash` placeholder in seed).
- Payment gateway, tax jurisdictions, multi-currency, serial/lot tracking, and barcode tables.
- Automated ETL to `dw` (document procedure; implement minimal `INSERT` scripts if required).
- High availability (Always On), full **distributed** two-phase commit (see simulation notes in [`inventory/transactions/03_distributed_database_simulation.md`](../inventory/transactions/03_distributed_database_simulation.md)).

## Assumptions

- Single enterprise; locations are **warehouses / stores / vans** identified in `dbo.Locations`.
- **Line totals** on sales are derived from `Quantity * UnitPrice` (persisted computed column).
- **Stock** is non-negative; oversell is rejected by trigger logic.

# Distributed database simulation (course narrative)

This project’s **primary implementation** is a **single SQL Server instance** (`AshcolInventory`). For coursework that requires a *distributed database simulation*, document one or more of the following patterns (no second server required for a passing narrative if your instructor allows **design + partial demo**):

## Option A — Linked server (real split)

- Install a second SQL Server instance (or use Azure SQL + on-prem).
- Register **Linked Server**; run `INSERT ... SELECT` across nodes for **replicated reference data** (e.g. `Products` on Node A, `SalesOrders` on Node B).
- Discuss **latency**, **two-phase commit** limitations, and **eventual consistency** for reporting.

## Option B — Same instance, two databases (logical distribution)

- Create `AshcolInventory_HO` (head office) and `AshcolInventory_BRANCH` (branch).
- Use **synonyms** or **cross-database FKs** (where supported) to show **federated** boundaries.
- ETL job (scheduled agent job or script) **syncs** dimension tables nightly.

## Option C — Read replicas (Azure / managed SQL)

- Document **geo-replication** or **read scale-out** for reporting workloads hitting **views** / **star schema** only.

## What to submit

- Short **architecture diagram** (two boxes + arrow).
- **One** working script or screenshot (e.g. cross-db query or linked server `SELECT`).
- **Risks**: split transactions, identity ranges, conflict resolution.

Align this section with your instructor’s exact definition of “simulation.”

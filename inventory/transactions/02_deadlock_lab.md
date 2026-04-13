# Deadlock simulation and resolution (lab)

SQL Server detects deadlocks automatically and kills one session (**victim**). Document the exercise in `docs/05-testing-procedures.md`.

## Setup

1. Open **two** query windows in SSMS, both `USE AshcolInventory`.
2. Ensure at least two products exist (seed script).

## Session A (run first, do not commit)

```sql
BEGIN TRANSACTION;
UPDATE dbo.Products SET ListPrice = ListPrice WHERE ProductId = 1;
-- hold lock, do not commit yet
```

## Session B

```sql
BEGIN TRANSACTION;
UPDATE dbo.Products SET ListPrice = ListPrice WHERE ProductId = 2;
UPDATE dbo.Products SET ListPrice = ListPrice WHERE ProductId = 1;
-- may block, then deadlock when Session A updates ProductId 2
```

## Session A (continue)

```sql
UPDATE dbo.Products SET ListPrice = ListPrice WHERE ProductId = 2;
```

One session receives **error 1205**. The other completes.

## Resolution strategies (write-up)

- **Consistent lock order** — always lock `ProductId` in ascending order across procedures.
- **Short transactions** — avoid user interaction inside `BEGIN TRAN`.
- **Retry** — application catches 1205 and retries the batch.
- **`SET DEADLOCK_PRIORITY LOW`** on reporting sessions when acceptable.

## Capture proof

Enable **Extended Events** or trace flag 1222 / 1204 to log deadlock graphs for your report appendix.

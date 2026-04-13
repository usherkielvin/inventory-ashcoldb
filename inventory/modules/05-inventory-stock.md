# Module 5 — Inventory & stock control

**Tables:** `dbo.StockLevels`, `dbo.StockMovements`  
**Scripts:** [`../ddl/04_inventory_stock.sql`](../ddl/04_inventory_stock.sql), [`../triggers/trg_StockMovements_UpdateLevel.sql`](../triggers/trg_StockMovements_UpdateLevel.sql)

**Ledger** pattern: every change is a `StockMovements` row; trigger maintains `StockLevels`. Prevents **negative** on-hand quantity.

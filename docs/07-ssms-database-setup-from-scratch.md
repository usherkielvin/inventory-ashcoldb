# 7. SSMS database setup — step by step (from nothing)

Follow this when **nothing shows** in the web UI or SSMS: usually the database was not built, scripts ran out of order, or SQL Server is not accepting remote-style connections on the port your API uses.

---

## Part A — Install and open SSMS

1. Install **Microsoft SQL Server** (Express is fine for class) from Microsoft’s site. Note whether you chose **Default instance** or **Named instance** (e.g. `SQLEXPRESS`).
2. Install **SQL Server Management Studio (SSMS)** (current release).
3. Open **SSMS** → **Connect**:
   - Default instance: Server name `localhost` or `.` or `(local)`.
   - Named instance: `localhost\SQLEXPRESS` (replace `SQLEXPRESS` with your instance name).

If you cannot connect, fix that **before** running any project scripts (Windows Authentication is enough for SSMS on the same machine).

---

## Part B — Mixed Mode + SQL login (needed for Node / Express)

The optional **Express API** uses **SQL Server Authentication** (`SQL_USER` / `SQL_PASSWORD` in `.env`). SSMS can still use Windows auth while you create a SQL login.

1. In SSMS, right-click the server → **Properties** → **Security**.
2. Set **SQL Server and Windows Authentication mode** → **OK** → restart the **SQL Server** Windows service when prompted (Services app: `SQL Server (MSSQLSERVER)` or `SQL Server (SQLEXPRESS)`).

**Option 1 — use `sa` (simple for local dev)**  
3. **Security** → **Logins** → **sa** → **Properties** → set a **strong password** → **Status** → **Login: Enabled** → **OK**.

**Option 2 — dedicated login (good practice)**  
3. **Security** → **Logins** → right-click **Logins** → **New Login** → **SQL Server authentication** → name e.g. `inventory_app` → password → uncheck “enforce password policy” only if your course allows (otherwise keep it).  
4. **User Mapping** → check **`AshcolInventory`** (after the database exists in Part C) → role **`db_datareader`** (and later **`db_datawriter`** if you add inserts/updates). For a first read-only API, **`db_datareader`** on `AshcolInventory` is enough.

Until Part C is done, you can create the login first and map the user after the database exists.

---

## Part C — Run project scripts in the exact order

All paths are under your cloned repo, folder **`inventory/`**.

### C1 — Drop old database (only if you need a clean rebuild)

In SSMS, **New Query**, connect to **`master`**:

```sql
USE master;
GO
IF DB_ID(N'AshcolInventory') IS NOT NULL
BEGIN
    ALTER DATABASE AshcolInventory SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AshcolInventory;
END
GO
```

Skip this on a **first-time** install.

### C2 — DDL (schema) — run each file completely

Use **File → Open → File** in SSMS, open each script from your disk, check the status bar shows the right path, then **Execute (F5)**. Fix any **red errors** before continuing.

| Step | File (in repo) |
|------|----------------|
| 1 | `inventory/ddl/00_create_database.sql` |
| 2 | `inventory/ddl/01_users_roles.sql` |
| 3 | `inventory/ddl/02_catalog_suppliers.sql` |
| 4 | `inventory/ddl/03_locations.sql` |
| 5 | `inventory/ddl/04_inventory_stock.sql` |
| 6 | `inventory/ddl/05_customers_sales.sql` |
| 7 | `inventory/ddl/06_purchasing.sql` |
| 8 | `inventory/ddl/07_indexes.sql` |

**Check:** In **Object Explorer**, refresh **Databases** → **`AshcolInventory`** → **Tables** — you should see many tables (e.g. `Products`, `Roles`, `StockMovements`).

### C3 — Views

Run **all** of these (order between them is fine):

- `inventory/views/vw_ActiveProductCatalog.sql`
- `inventory/views/vw_DeletedProducts.sql`
- `inventory/views/vw_SalesOrderSummary.sql`

**Check:** **Views** under `AshcolInventory` → `dbo.vw_ActiveProductCatalog` exists.

### C4 — Triggers (must run before seeds)

Run **both**:

- `inventory/triggers/trg_Products_SoftDeleteOnly.sql`
- `inventory/triggers/trg_StockMovements_UpdateLevel.sql`

Seeds insert **`StockMovements`**; the trigger fills **`StockLevels`**. If you seed first, you can get wrong or empty stock.

### C5 — Seed data

- `inventory/seeds/01_seed_reference_data.sql`

**Check:** Messages pane should end with something like `Seed complete.`

### C6 — Quick verification query

**New Query**, database **`AshcolInventory`**:

```sql
USE AshcolInventory;
GO
SELECT COUNT(*) AS ProductCount FROM dbo.Products WHERE IsDeleted = 0;
SELECT COUNT(*) AS RowCount FROM dbo.vw_ActiveProductCatalog;
```

You should see **ProductCount ≥ 1** and **RowCount** matching non-deleted catalog rows (same idea as `docs/05-testing-procedures.md`).

If **`vw_ActiveProductCatalog`** returns **0 rows** but `Products` has rows, check **`IsDeleted = 0`** and that categories/suppliers are not deleted.

---

## Part D — If the web app still shows nothing

### D1 — Confirm SQL Server listens on TCP

1. Open **SQL Server Configuration Manager**.
2. **SQL Server Network Configuration** → **Protocols for &lt;YOUR INSTANCE&gt;** → enable **TCP/IP**.
3. Under **TCP/IP** → **IP Addresses** → scroll to **IPAll** → note **TCP Dynamic Ports** or set **TCP Port** (e.g. **1433**) for a fixed port.
4. **Restart** the **SQL Server** service.

**Named instance** (`SQLEXPRESS`): either start **SQL Server Browser** service, or put the **actual port** into `web/server/.env` as `SQL_PORT=xxxxx`.

### D2 — Match `web/server/.env` to your instance

Edit **`web/server/.env`** (copy from **`web/server/.env.example`** if missing).

**If you use Windows Authentication in SSMS** (same as your PC user, e.g. `OMEN-15\usher`), set:

| Variable | Example |
|----------|---------|
| `SQL_USE_WINDOWS_AUTH` | `true` |
| `SQL_SERVER` | In `.env` use **double** backslashes: `localhost\\SQLEXPRESS01` (matches server name `localhost\SQLEXPRESS01`) |
| `SQL_PORT` | Leave **empty** for a named instance so the driver can use **SQL Server Browser** — or set the **TCP Dynamic Port** from Configuration Manager if Browser is off |
| `SQL_DATABASE` | `AshcolInventory` |
| `SQL_ENCRYPT` | `true` (mandatory encryption) |
| `SQL_TRUST_SERVER_CERTIFICATE` | `true` (trust server certificate, like your connection dialog) |

Run **`npm run dev`** from the same Windows account you use in SSMS so **integrated security** matches.

**If you use SQL Server authentication** instead, set `SQL_USE_WINDOWS_AUTH=false`, `SQL_USER`, `SQL_PASSWORD`, and usually `SQL_PORT=1433` (or your fixed port).

Restart the API after any `.env` change: in `web/server` Ctrl+C, then `npm run dev`.

### D3 — Two terminals

1. **`web/server`:** `npm run dev` → API **http://localhost:3001**  
2. **`web/client`:** `npm run dev` → **http://localhost:5174**

Open **http://localhost:3001/api/health** in a browser. You want **`"ok": true`** and **`database": "AshcolInventory"`**. If **`ok": false`**, read the `error` string (login failed vs network vs database missing).

Then open **http://localhost:5174** and refresh.

---

## Part E — Optional advanced scripts (course labs)

Only after the database works:

- `inventory/transactions/` — transaction / isolation / deadlock labs  
- `inventory/warehouse/` — star schema and OLAP samples  

Record results in **`docs/05-testing-procedures.md`**.

---

## Checklist (copy for your notes)

- [ ] SSMS connects to the instance  
- [ ] Mixed Mode + SQL login (or `sa`) configured  
- [ ] DDL `00` → `07` executed with no errors  
- [ ] All three views created  
- [ ] Both triggers created **before** seed  
- [ ] Seed ran; verification `SELECT` returns rows from `vw_ActiveProductCatalog`  
- [ ] TCP/IP enabled; port known for `.env`  
- [ ] API health OK; Vite UI shows the table  

If one step fails, **stop** and fix the error message from SSMS before going to the next file.

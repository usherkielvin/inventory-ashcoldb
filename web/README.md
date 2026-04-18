# Web stack (optional) — React + Vite + Express → SQL Server

This folder is **in addition to** the professor-required **SSMS + SQL Server** scripts under [`../inventory/`](../inventory/). The API reads **`AshcolInventory`** (same database you build with DDL, views, triggers, seeds).

## Fix setup (connection errors first)

1. **Database exists** — follow **[`../docs/07-ssms-database-setup-from-scratch.md`](../docs/07-ssms-database-setup-from-scratch.md)** (DDL → views → triggers → seeds).
2. **Test SQL from Node** (uses `web/server/.env`):

   ```powershell
   cd path\to\Inventory Database\web
   npm run test:sql
   ```

   You should see **`OK — connected`**. If **`FAILED`**, follow the printed checklist (TCP port, service, Windows user).
3. **Match SSMS (TCP port)** — In SSMS, try **`127.0.0.1,1433`** (comma + port). If that fails, **`SQL_PORT`** in `.env` is wrong: open **SQL Server Configuration Manager** → **TCP/IP** → **IPAll** for **your** instance, set **`SQL_PORT`** to that number, **restart SQL Server**, run **`npm run test:sql`** again.  
   For **Windows auth + this API**, prefer **`SQL_SERVER=localhost`** with **`SQL_PORT`** (see [Windows authentication (ODBC + msnodesqlv8)](#windows-authentication-odbc--msnodesqlv8)); using **`127.0.0.1`** with integrated security often triggers **SSPI / “out of sequence”** errors with the ODBC driver.
4. **Then** run **`npm run dev`** and open **`http://localhost:3001/api/health`**.

**Nothing shows in the browser?** Fix **`npm run test:sql`** first, then the table below.

### Quick troubleshooting

| Symptom | What to do |
|--------|----------------|
| Blank page / “Checking…” forever | Open **http://localhost:3001/api/health** — if that fails, the API is down or SQL is unreachable. |
| Health shows `"ok": false` or **`ETIMEOUT` / `Failed to connect ... SQLEXPRESS01`** | Named instance needs **SQL Server Browser** *or* an explicit **`SQL_PORT`** from **Configuration Manager → TCP/IP → IPAll** for **that** instance. Set **`SQL_PORT`** in `server/.env`. See **`server/.env.example`**. |
| **`ESOCKET` / `Failed to connect ... :1433`** | (a) **Wrong port or service down** — run **`netstat -ano`** and confirm a **`LISTENING`** row on your **`SQL_PORT`** (often **1433**). The port must match **IPAll** for your instance after **TCP/IP Enabled** + **service restart** (Admin PowerShell: **`Restart-Service -Name 'MSSQL$YOURINSTANCE'`** — use **single quotes** so **`$`** is not expanded). (b) **SQL login (`SQL_USE_WINDOWS_AUTH=false`)** — the default **tedious** driver maps **`localhost` → `127.0.0.1`** when **`SQL_PORT`** is set (IPv6 workaround). (c) **Windows auth** — keep **`SQL_SERVER=localhost`** (do not force **`127.0.0.1`**); see the **ODBC + msnodesqlv8** section below. |
| **`Data source name not found`** / ODBC driver errors | Install **Microsoft ODBC Driver 18 for SQL Server** (or 17). Verify with `Get-OdbcDriver` (PowerShell). Optionally set **`SQL_ODBC_DRIVER`** in `server/.env` to the exact driver name. |
| **`Login failed for user ''`** (with **`127.0.0.1`** + Windows auth) | You hit the **tedious** path (integrated security is not supported). Ensure **`SQL_USE_WINDOWS_AUTH=true`** and this repo’s **`msnodesqlv8`** setup; use **`localhost`** + **`SQL_PORT`** per below. |
| **`Cannot generate SSPI context`** / **verification is out of sequence** | Common when using **`127.0.0.1`** + **Trusted Connection** over ODBC. Use **`SQL_SERVER=localhost`** + **`SQL_PORT`**, or use a **SQL login** instead. |
| Health `ok` but table empty | In SSMS run `SELECT COUNT(*) FROM dbo.vw_ActiveProductCatalog`. If **0**, rerun **seeds** after **triggers**, or check `Products.IsDeleted`. |
| `EADDRINUSE` on 3001 | Another Node/Express is still bound to **3001**. **Option A:** from repo root run **`web/scripts/free-port-api.ps1`** (PowerShell). **Option B:** Task Manager → end extra **Node** processes. **Option C:** set **`PORT=3002`** in `server/.env`, add **`web/client/.env`** with **`VITE_API_PROXY_TARGET=http://localhost:3002`**, restart `npm run dev`. |
| Vite on **5175/5176** | Ports **5174–5175** busy; UI URL is whatever Vite prints — proxy still works if API is up. |
| Vite errors on `/api` | API must be running on **3001** while Vite runs on **5174** (proxy in `client/vite.config.ts`). |

## Prerequisites

- Node.js **18+** ([nodejs.org](https://nodejs.org/))
- SQL Server with **`AshcolInventory`** deployed (DDL → views → triggers → seeds in SSMS)
- Either **Windows Authentication** (same Windows user as runs Node — `SQL_USE_WINDOWS_AUTH=true` in `server/.env`) **or** a **SQL login** with `SELECT` on `dbo.vw_ActiveProductCatalog`

## Windows authentication (ODBC + msnodesqlv8)

Teammates on **Windows** using **`SQL_USE_WINDOWS_AUTH=true`** should read this section. The default **`mssql`** driver (**tedious**) **does not** support **Windows / Trusted Connection** logins ([`mssql` README](https://github.com/tediousjs/node-mssql/blob/master/README.md) — tedious authentication notes). This project therefore uses:

- **`mssql/msnodesqlv8`** (from `msnodesqlv8` on npm) — talks to SQL Server through **ODBC**
- An explicit ODBC connection string built in code, using **`ODBC Driver 18 for SQL Server`** by default (not “SQL Server Native Client 11.0”, which is often missing)

### 1) Install the Microsoft ODBC Driver for SQL Server

On Windows, install **ODBC Driver 18 for SQL Server** (or **17**) from Microsoft. It is **usually already present** if SSMS or SQL Server tools were installed.

Check installed drivers (PowerShell):

```powershell
Get-OdbcDriver | Where-Object Name -Like '*SQL Server*' | Format-Table Name, Platform -AutoSize
```

You should see **`ODBC Driver 18 for SQL Server`** (64-bit). If not, install the driver, then rerun:

```powershell
cd path\to\Inventory Database\web\server
npm install
```

### 2) `npm install` / native module notes

`msnodesqlv8` includes a **native** addon. Normally `npm install` downloads a **prebuilt binary**. If install fails with compile errors, install **Visual Studio Build Tools** (Desktop development with C++ / MSVC) and retry.

### 3) `.env` values that work well together

**Recommended (TCP + Windows auth):** explicit port from **SQL Server Configuration Manager → TCP/IP → IPAll**, same port you use in SSMS as `host,port`:

```env
SQL_USE_WINDOWS_AUTH=true
SQL_SERVER=localhost
SQL_PORT=1433
SQL_DATABASE=AshcolInventory
SQL_ENCRYPT=true
SQL_TRUST_SERVER_CERTIFICATE=true
```

Why **`localhost`** instead of **`127.0.0.1`** here: with **Trusted_Connection** over ODBC, **`127.0.0.1`** often causes **SSPI / “out of sequence”** errors. **`localhost`** avoids that on typical Windows setups.

Optional: if your ODBC driver name differs, set exactly what `Get-OdbcDriver` prints:

```env
SQL_ODBC_DRIVER=ODBC Driver 18 for SQL Server
```

**Alternative (SSMS “Server name” string):** set **`SQL_SERVER_FULL=localhost\INSTANCE`** and omit **`SQL_PORT`**. That path normally requires **SQL Server Browser** running unless you only rely on shared-memory/local (not suitable for remote teammates).

### 4) Verify from Node (before `npm run dev`)

```powershell
cd path\to\Inventory Database\web
npm run test:sql
```

Expect **`OK — connected`**. Resolved JSON should include **`"driver":"msnodesqlv8"`** when Windows auth is enabled.

### 5) SQL login mode (no Windows auth)

If **`SQL_USE_WINDOWS_AUTH=false`**, the API uses the default **`mssql`** (**tedious**) driver with **`SQL_USER` / `SQL_PASSWORD`**. That path does **not** use ODBC for authentication. For **`localhost` + SQL_PORT**, the config may still map **`localhost` → `127.0.0.1`** to reduce IPv6 issues.

## Environment (`web/server/.env`)

From repo root, copy the example if needed:

```powershell
Set-Location "D:\usher\Documents\Capstone Project\Inventory Database\web\server"
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

For **Windows auth** + **TCP** (recommended for Node + teammates), use **`SQL_SERVER=localhost`** and **`SQL_PORT`** from **Configuration Manager → IPAll** (see section above).

For **SQL login**, set `SQL_USE_WINDOWS_AUTH=false`, `SQL_USER`, `SQL_PASSWORD`, and `SQL_PORT` if required.

```env
PORT=3001
CORS_ORIGIN=http://localhost:5174
```

---

## Option A — One command (API + UI together)

From the **`web`** folder (install once, then dev):

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web"
npm run bootstrap
npm run dev
```

- API: **http://localhost:3001** — open **http://localhost:3001/api/health** (expect `data.ok = true`).
- UI: **http://localhost:5174** (Vite proxies **`/api`** to port 3001).

Stop both with **Ctrl+C** in that terminal.

---

## Option B — Two terminals (manual)

**Terminal 1 — API**

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web\server"
npm install
npm run dev
```

**Terminal 2 — UI**

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web\client"
npm install
npm run dev
```

---

## Option C — Two PowerShell windows (script)

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web"
.\start-dev.ps1
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Service + DB health. Returns envelope: `{ data: { ok, database, serverVersion }, error, meta }` |
| GET | `/api/lookups` | Category, supplier, and location lookups for forms/filters |
| GET | `/api/products` | Paginated product list with filtering (`q`, `categoryId`, `supplierId`) and sorting (`sortBy`, `sortDir`) |
| GET | `/api/products/:productId` | Product details + `stockByLocation` |
| POST | `/api/products` | Create product (write flow) |
| POST | `/api/stock-adjustments` | Insert stock movement adjustment (write flow) |

### API contract checks

Run while API is already up:

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web\server"
npm run test:api
```

Run SQL smoke test:

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web"
npm run test:sql
```

## Feature walkthrough (3–5 minute demo)

1. Open **`/api/health`** to show DB connectivity.
2. Open UI and show:
   - Search by SKU/Name
   - Filter by category/supplier
   - Sorting and pagination
3. Click **Details** on a product to show stock by location.
4. Create a new product in **Inventory actions**.
5. Post a stock adjustment and re-open Details to show updated on-hand quantity.

## Known limitations

- No authentication/authorization yet (single shared operator view).
- Stock adjustments are manual and do not yet require approval workflow.
- API tests are smoke/contract-level (not full integration suite with isolated DB fixtures).

## Next improvements

- Add role-based auth (admin vs clerk vs viewer).
- Add edit/deactivate product workflows and audit history screens.
- Add stronger automated tests (API integration + UI interaction tests).

## Production build (client only)

```powershell
cd web/client
npm run build
npm run preview
```

Serve `client/dist` with any static host; you must configure that host to **reverse-proxy** `/api` to your Express process (or set `VITE_API_URL` and change the client to call an absolute URL — not included by default).

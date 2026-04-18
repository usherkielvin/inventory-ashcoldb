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
3. **Match SSMS** — In SSMS, try server **`127.0.0.1,1433`** (comma + port). If that fails, **`SQL_PORT`** in `.env` is wrong: open **SQL Server Configuration Manager** → **TCP/IP** → **IPAll** for **your** instance, set **`SQL_PORT`** to that number, **restart SQL Server**, run **`npm run test:sql`** again.
4. **Then** run **`npm run dev`** and open **`http://localhost:3001/api/health`**.

**Nothing shows in the browser?** Fix **`npm run test:sql`** first, then the table below.

### Quick troubleshooting

| Symptom | What to do |
|--------|----------------|
| Blank page / “Checking…” forever | Open **http://localhost:3001/api/health** — if that fails, the API is down or SQL is unreachable. |
| Health shows `"ok": false` or **`ETIMEOUT` / `Failed to connect ... SQLEXPRESS01`** | Named instance needs **SQL Server Browser** *or* an explicit **`SQL_PORT`** from **Configuration Manager → TCP/IP → IPAll** for **that** instance. Set **`SQL_PORT`** in `server/.env`. See **`server/.env.example`**. |
| **`ESOCKET` / `Failed to connect ... :1433`** | (a) **Wrong port or service down** — in PowerShell run `Get-NetTCPConnection -LocalPort 1433 -State Listen` (or `netstat -ano` and find `1433`). The port must match **IPAll** for **SQL Server (SQLEXPRESS01)** after **TCP/IP Enabled** + **service restart**. (b) **IPv6** — use **`SQL_SERVER=127.0.0.1`** in `server/.env`, or leave `localhost` (the API uses `127.0.0.1` when `SQL_PORT` is set and `SQL_PREFER_IPV6` is not true). |
| Health `ok` but table empty | In SSMS run `SELECT COUNT(*) FROM dbo.vw_ActiveProductCatalog`. If **0**, rerun **seeds** after **triggers**, or check `Products.IsDeleted`. |
| `EADDRINUSE` on 3001 | Another Node/Express is still bound to **3001**. **Option A:** from repo root run **`web/scripts/free-port-api.ps1`** (PowerShell). **Option B:** Task Manager → end extra **Node** processes. **Option C:** set **`PORT=3002`** in `server/.env`, add **`web/client/.env`** with **`VITE_API_PROXY_TARGET=http://localhost:3002`**, restart `npm run dev`. |
| Vite on **5175/5176** | Ports **5174–5175** busy; UI URL is whatever Vite prints — proxy still works if API is up. |
| Vite errors on `/api` | API must be running on **3001** while Vite runs on **5174** (proxy in `client/vite.config.ts`). |

## Prerequisites

- Node.js **18+** ([nodejs.org](https://nodejs.org/))
- SQL Server with **`AshcolInventory`** deployed (DDL → views → triggers → seeds in SSMS)
- Either **Windows Authentication** (same Windows user as runs Node — `SQL_USE_WINDOWS_AUTH=true` in `server/.env`) **or** a **SQL login** with `SELECT` on `dbo.vw_ActiveProductCatalog`

## Environment (`web/server/.env`)

From repo root, copy the example if needed:

```powershell
Set-Location "D:\usher\Documents\Capstone Project\Inventory Database\web\server"
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

For **`localhost\SQLEXPRESS01`** + **Windows auth** (typical class setup), **`server/.env`** should include:

```env
SQL_USE_WINDOWS_AUTH=true
SQL_SERVER=localhost\SQLEXPRESS01
SQL_PORT=
SQL_DATABASE=AshcolInventory
SQL_ENCRYPT=true
SQL_TRUST_SERVER_CERTIFICATE=true
PORT=3001
CORS_ORIGIN=http://localhost:5174
```

Use **SQL login** instead: set `SQL_USE_WINDOWS_AUTH=false`, `SQL_USER`, `SQL_PASSWORD`, and `SQL_PORT` if required.

---

## Option A — One command (API + UI together)

From the **`web`** folder (install once, then dev):

```powershell
cd "D:\usher\Documents\Capstone Project\Inventory Database\web"
npm run bootstrap
npm run dev
```

- API: **http://localhost:3001** — open **http://localhost:3001/api/health** (expect `"ok": true`).
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
| GET | `/api/health` | Confirms DB connection and returns current database name |
| GET | `/api/products` | Rows from `dbo.vw_ActiveProductCatalog` |

## Production build (client only)

```powershell
cd web/client
npm run build
npm run preview
```

Serve `client/dist` with any static host; you must configure that host to **reverse-proxy** `/api` to your Express process (or set `VITE_API_URL` and change the client to call an absolute URL — not included by default).

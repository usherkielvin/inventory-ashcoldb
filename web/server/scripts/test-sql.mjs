/**
 * Smoke test: same connection settings as Express. Run from folder web/server:
 *   npm run test:sql
 */
import { config as loadEnv } from 'dotenv'
import { dirname, resolve } from 'path'
import { fileURLToPath } from 'url'
import { buildSqlConfig } from '../src/sqlConfig.js'
import { getMssql } from '../src/sqlClient.js'

const __dirname = dirname(fileURLToPath(import.meta.url))
loadEnv({ path: resolve(__dirname, '..', '.env') })

const sql = getMssql()

console.log('Testing SQL connection (same config as API)...\n')

let cfg
try {
  cfg = buildSqlConfig()
} catch (e) {
  console.error('Config error:', e.message || e)
  process.exit(1)
}

console.log('Resolved:', JSON.stringify({
  server: cfg.server,
  port: cfg.port,
  instanceName: cfg.options.instanceName,
  driver: cfg.driver,
  mode: process.env.SQL_SERVER_FULL?.trim() ? 'SQL_SERVER_FULL' : 'host/instance/port',
  database: cfg.database,
  windowsAuth: Boolean(cfg.options.trustedConnection),
  timeoutMs: cfg.connectionTimeout,
}))

try {
  await sql.connect(cfg)
  const r = await sql.query`
    SELECT @@SERVERNAME AS ServerName, DB_NAME() AS DbName, (SELECT COUNT(*) FROM dbo.Roles) AS RoleCount
  `
  console.log('\nOK — connected. Row:', r.recordset[0])
  await sql.close()
  process.exit(0)
} catch (e) {
  console.error('\nFAILED:', e.message || e)
  const msg = String(e.message || e)
  if (/60000ms|ETIMEOUT|timeout/i.test(msg) && process.env.SQL_SERVER_FULL?.trim()) {
    console.error(`
Hint: Named instance without SQL_PORT usually needs the "SQL Server Browser" service (UDP 1434).
  services.msc → SQL Server Browser → Start (Automatic). Or use TCP: clear SQL_SERVER_FULL, set SQL_SERVER=127.0.0.1 and SQL_PORT from Configuration Manager → TCP/IP → IPAll.
`)
  }
  console.error(`
Fix checklist:
  1) Services: "SQL Server (SQLEXPRESS01)" is Running.
  2) If you use 127.0.0.1 + SQL_PORT: SSMS must connect to "127.0.0.1,<port>" (comma). If that fails, SQL_PORT is wrong or TCP is off.
  3) SQL Server Configuration Manager: TCP/IP Enabled for SQLEXPRESS01 → IPAll TCP Port matches SQL_PORT → Restart SQL service.
  4) Only one instance can use port 1433; if default instance took it, pick another port for Express in IPAll and set SQL_PORT.
  5) Windows auth: run this terminal as the same user you use in SSMS (e.g. OMEN-15\\usher).
  6) Named instance without SQL_PORT: start "SQL Server Browser" (or use TCP: SQL_SERVER + SQL_PORT from IPAll and remove SQL_SERVER_FULL).
  7) Easiest match to SSMS server box: SQL_SERVER_FULL=localhost\\YOURINSTANCE (one backslash in the value is fine in .env on Windows).
`)
  process.exit(1)
}

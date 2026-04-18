import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import sql from 'mssql'
import { buildSqlConfig } from './sqlConfig.js'

const PORT = Number(process.env.PORT || 3001)

let sqlConfig
try {
  sqlConfig = buildSqlConfig()
  const dbg = {
    server: sqlConfig.server,
    port: sqlConfig.port,
    instanceName: sqlConfig.options.instanceName,
    database: sqlConfig.database,
    windowsAuth: Boolean(sqlConfig.options.trustedConnection),
    connectionTimeoutMs: sqlConfig.connectionTimeout,
  }
  console.log('[sql] config (no secrets):', JSON.stringify(dbg))
  if (!sqlConfig.port && sqlConfig.options.instanceName) {
    console.log(
      '[sql] Named instance without SQL_PORT — needs SQL Server Browser OR set SQL_PORT (IPAll). Run: npm run test:sql',
    )
  }
} catch (e) {
  console.error(e.message || e)
  sqlConfig = null
}

const corsOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((s) => s.trim()).filter(Boolean)
  : true

const app = express()
app.use(cors({ origin: corsOrigins }))
app.use(express.json())

let pool

async function getPool() {
  if (!sqlConfig) {
    throw new Error('Invalid SQL config — fix web/server/.env and restart')
  }
  if (!pool) {
    pool = await sql.connect(sqlConfig)
  }
  return pool
}

app.get('/api/health', async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query('SELECT DB_NAME() AS DbName, @@VERSION AS Version')
    const row = result.recordset[0]
    res.json({
      ok: true,
      database: row?.DbName,
      serverVersion: typeof row?.Version === 'string' ? row.Version.split('\n')[0] : row?.Version,
    })
  } catch (e) {
    console.error(e)
    res.status(503).json({
      ok: false,
      error: String(e.message || e),
      hint: 'Run from web/server: npm run test:sql — then match SQL_PORT to IPAll and restart SQL Server service.',
    })
  }
})

app.get('/api/products', async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT
        ProductId,
        Sku,
        Name,
        UnitOfMeasure,
        UnitCost,
        ListPrice,
        ReorderLevel,
        CategoryName,
        SupplierName
      FROM dbo.vw_ActiveProductCatalog
      ORDER BY Sku
    `)
    res.json({ data: result.recordset })
  } catch (e) {
    console.error(e)
    res.status(500).json({ error: String(e.message || e) })
  }
})

const server = app.listen(PORT, () => {
  console.log(`Inventory API listening on http://localhost:${PORT}`)
  console.log('SQL smoke test: npm run test:sql (in web/server folder)')
})

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `\nPort ${PORT} is already in use. Close the other Node/Express window, or run web/scripts/free-port-api.ps1, or set PORT=3002 in web/server/.env and VITE_API_PROXY_TARGET=http://localhost:3002 in web/client/.env\n`,
    )
  } else {
    console.error(err)
  }
  process.exit(1)
})

import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import jwt from 'jsonwebtoken'
import { getMssql } from './sqlClient.js'
import { buildSqlConfig } from './sqlConfig.js'

const sql = getMssql()
const PORT = Number(process.env.PORT || 3001)
const JWT_SECRET = process.env.JWT_SECRET || 'ashcol-dev-secret'

// ─── Demo credentials (academic project — real app uses bcrypt + DB lookup) ──
const DEMO_CREDENTIALS = {
  'admin@ashcol.local':           { password: 'admin123', role: 'Administrator', fullName: 'System Administrator' },
  'juan.delacruz@ashcol.local':   { password: 'staff123', role: 'Staff',         fullName: 'Juan dela Cruz' },
  'maria.santos@ashcol.local':    { password: 'staff123', role: 'Staff',         fullName: 'Maria Santos' },
}

let sqlConfig
try {
  sqlConfig = buildSqlConfig()
  const dbg = {
    server: sqlConfig.server, port: sqlConfig.port,
    instanceName: sqlConfig.options.instanceName, database: sqlConfig.database,
    driver: sqlConfig.driver, windowsAuth: Boolean(sqlConfig.options.trustedConnection),
    connectionTimeoutMs: sqlConfig.connectionTimeout,
  }
  console.log('[sql] config (no secrets):', JSON.stringify(dbg))
  if (!sqlConfig.port && sqlConfig.options.instanceName) {
    console.log('[sql] Named instance without SQL_PORT — needs SQL Server Browser OR set SQL_PORT (IPAll).')
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
  if (!sqlConfig) throw new Error('Invalid SQL config — fix web/server/.env and restart')
  if (!pool) pool = await sql.connect(sqlConfig)
  return pool
}

// ─── Auth middleware ──────────────────────────────────────────────────────────
function requireAuth(req, res, next) {
  const auth = req.headers.authorization
  if (!auth?.startsWith('Bearer ')) {
    return res.status(401).json(envelope({ error: { message: 'Authentication required' } }))
  }
  try {
    req.user = jwt.verify(auth.slice(7), JWT_SECRET)
    next()
  } catch {
    return res.status(401).json(envelope({ error: { message: 'Invalid or expired token' } }))
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function asInt(value) {
  if (value === undefined || value === null || value === '') return undefined
  const n = Number(value)
  if (!Number.isInteger(n)) return undefined
  return n
}

function asDecimal(value) {
  if (value === undefined || value === null || value === '') return undefined
  const n = Number(value)
  if (!Number.isFinite(n)) return undefined
  return n
}

function asNonEmptyString(value) {
  if (typeof value !== 'string') return undefined
  const s = value.trim()
  return s.length > 0 ? s : undefined
}

function envelope({ data = null, error = null, meta = {} } = {}) {
  return { data, error, meta }
}

function normalizePage(query) {
  const pageRaw = asInt(query.page) ?? 1
  const pageSizeRaw = asInt(query.pageSize) ?? 10
  const page = Math.max(1, pageRaw)
  const pageSize = Math.min(50, Math.max(1, pageSizeRaw))
  return { page, pageSize, offset: (page - 1) * pageSize }
}

// =============================================================================
// AUTH
// =============================================================================

app.post('/api/auth/login', (req, res) => {
  const email = String(req.body?.email || '').trim().toLowerCase()
  const password = String(req.body?.password || '')
  const user = DEMO_CREDENTIALS[email]
  if (!user || user.password !== password) {
    return res.status(401).json(envelope({ error: { message: 'Invalid email or password' } }))
  }
  const token = jwt.sign(
    { email, role: user.role, fullName: user.fullName },
    JWT_SECRET,
    { expiresIn: '8h' },
  )
  return res.json(envelope({ data: { token, email, role: user.role, fullName: user.fullName } }))
})

// =============================================================================
// HEALTH (public)
// =============================================================================

app.get('/api/health', async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query('SELECT DB_NAME() AS DbName, @@VERSION AS Version')
    const row = result.recordset[0]
    res.json(envelope({
      data: {
        ok: true,
        database: row?.DbName,
        serverVersion: typeof row?.Version === 'string' ? row.Version.split('\n')[0] : row?.Version,
      },
    }))
  } catch (e) {
    console.error(e)
    res.status(503).json({
      data: { ok: false },
      error: { message: String(e.message || e), hint: 'Run npm run test:sql from web/server' },
      meta: {},
    })
  }
})

// =============================================================================
// DASHBOARD (protected)
// =============================================================================

app.get('/api/dashboard', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT
        (SELECT COUNT(*) FROM dbo.Products   WHERE IsDeleted = 0)                             AS TotalProducts,
        (SELECT COUNT(*) FROM dbo.vw_LowStockAlert)                                           AS LowStockCount,
        (SELECT COUNT(*) FROM dbo.SalesOrders WHERE OrderStatus NOT IN (N'COMPLETED', N'CANCELLED') AND IsDeleted = 0) AS PendingOrders,
        (SELECT ISNULL(SUM(TotalAmount), 0) FROM dbo.Invoices WHERE PaymentStatus IN (N'PAID', N'PARTIAL') AND IsDeleted = 0) AS TotalRevenuePaid,
        (SELECT COUNT(*) FROM dbo.Invoices   WHERE PaymentStatus = N'UNPAID' AND IsDeleted = 0) AS UnpaidInvoices;
    `)
    res.json(envelope({ data: result.recordset[0] }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// LOOKUPS (protected)
// =============================================================================

app.get('/api/lookups', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const categories = await p.request().query(`SELECT CategoryId, Name FROM dbo.ProductCategories WHERE IsDeleted = 0 ORDER BY Name`)
    const suppliers  = await p.request().query(`SELECT SupplierId, Name FROM dbo.Suppliers WHERE IsDeleted = 0 ORDER BY Name`)
    const locations  = await p.request().query(`SELECT LocationId, Code, Name, LocationType FROM dbo.Locations WHERE IsDeleted = 0 AND IsActive = 1 ORDER BY Name`)
    const customers  = await p.request().query(`SELECT CustomerId, Name, Email, Phone FROM dbo.Customers WHERE IsDeleted = 0 ORDER BY Name`)
    res.json(envelope({ data: { categories: categories.recordset, suppliers: suppliers.recordset, locations: locations.recordset, customers: customers.recordset } }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// PRODUCTS (protected)
// =============================================================================

app.get('/api/products', requireAuth, async (req, res) => {
  try {
    const q          = asNonEmptyString(req.query.q)
    const categoryId = asInt(req.query.categoryId)
    const supplierId = asInt(req.query.supplierId)
    const { page, pageSize, offset } = normalizePage(req.query)
    const sortByRaw  = asNonEmptyString(req.query.sortBy) || 'Sku'
    const sortDirRaw = (asNonEmptyString(req.query.sortDir) || 'asc').toLowerCase()
    const sortMap    = { sku: 'Sku', name: 'Name', category: 'CategoryName', supplier: 'SupplierName', price: 'ListPrice', reorder: 'ReorderLevel' }
    const sortBy     = sortMap[sortByRaw.toLowerCase()] || 'Sku'
    const sortDir    = sortDirRaw === 'desc' ? 'DESC' : 'ASC'

    const p = await getPool()
    const request = p.request()
    request.input('q',          sql.NVarChar(200), q          || null)
    request.input('categoryId', sql.Int,           categoryId || null)
    request.input('supplierId', sql.Int,           supplierId || null)
    request.input('offset',     sql.Int,           offset)
    request.input('pageSize',   sql.Int,           pageSize)

    const result = await request.query(`
      ;WITH filtered AS (
        SELECT ProductId, Sku, Name, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, CategoryName, SupplierName
        FROM dbo.vw_ActiveProductCatalog
        WHERE
          (@q IS NULL OR Sku LIKE CONCAT('%',@q,'%') OR Name LIKE CONCAT('%',@q,'%'))
          AND (@categoryId IS NULL OR EXISTS (SELECT 1 FROM dbo.Products p WHERE p.ProductId = vw_ActiveProductCatalog.ProductId AND p.CategoryId = @categoryId))
          AND (@supplierId IS NULL OR EXISTS (SELECT 1 FROM dbo.Products p WHERE p.ProductId = vw_ActiveProductCatalog.ProductId AND p.SupplierId = @supplierId))
      )
      SELECT * FROM filtered
      ORDER BY ${sortBy} ${sortDir}, ProductId ASC
      OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY;

      SELECT COUNT(*) AS TotalCount
      FROM dbo.vw_ActiveProductCatalog
      WHERE
        (@q IS NULL OR Sku LIKE CONCAT('%',@q,'%') OR Name LIKE CONCAT('%',@q,'%'))
        AND (@categoryId IS NULL OR EXISTS (SELECT 1 FROM dbo.Products p WHERE p.ProductId = vw_ActiveProductCatalog.ProductId AND p.CategoryId = @categoryId))
        AND (@supplierId IS NULL OR EXISTS (SELECT 1 FROM dbo.Products p WHERE p.ProductId = vw_ActiveProductCatalog.ProductId AND p.SupplierId = @supplierId));
    `)
    const rows  = result.recordsets[0] || []
    const total = Number(result.recordsets[1]?.[0]?.TotalCount || 0)
    res.json(envelope({
      data: rows,
      meta: { page, pageSize, total, totalPages: Math.max(1, Math.ceil(total / pageSize)),
               sortBy, sortDir: sortDir.toLowerCase(), filters: { q: q || '', categoryId: categoryId || null, supplierId: supplierId || null } },
    }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.get('/api/products/:productId', requireAuth, async (req, res) => {
  try {
    const productId = asInt(req.params.productId)
    if (!productId) return res.status(400).json(envelope({ error: { message: 'Invalid productId' } }))
    const p   = await getPool()
    const req2 = p.request()
    req2.input('productId', sql.Int, productId)
    const result = await req2.query(`
      SELECT p.ProductId, p.Sku, p.Name, p.Description, p.UnitOfMeasure, p.UnitCost, p.ListPrice, p.ReorderLevel,
             c.Name AS CategoryName, s.Name AS SupplierName
      FROM   dbo.Products p
      INNER JOIN dbo.ProductCategories c ON c.CategoryId = p.CategoryId AND c.IsDeleted = 0
      LEFT  JOIN dbo.Suppliers         s ON s.SupplierId = p.SupplierId AND s.IsDeleted = 0
      WHERE  p.ProductId = @productId AND p.IsDeleted = 0;

      SELECT l.LocationId, l.Code, l.Name, l.LocationType, ISNULL(sl.QuantityOnHand, 0) AS QuantityOnHand
      FROM   dbo.Locations l
      LEFT  JOIN dbo.StockLevels sl ON sl.LocationId = l.LocationId AND sl.ProductId = @productId
      WHERE  l.IsDeleted = 0
      ORDER  BY l.Name;
    `)
    const product = result.recordsets[0]?.[0]
    if (!product) return res.status(404).json(envelope({ error: { message: 'Product not found' } }))
    return res.json(envelope({ data: { ...product, stockByLocation: result.recordsets[1] || [] } }))
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.post('/api/products', requireAuth, async (req, res) => {
  try {
    const payload      = req.body || {}
    const sku          = asNonEmptyString(payload.sku)
    const name         = asNonEmptyString(payload.name)
    const categoryId   = asInt(payload.categoryId)
    const supplierId   = asInt(payload.supplierId)
    const unitOfMeasure = asNonEmptyString(payload.unitOfMeasure) || 'PCS'
    const unitCost     = asDecimal(payload.unitCost) ?? 0
    const listPrice    = asDecimal(payload.listPrice) ?? 0
    const reorderLevel = asInt(payload.reorderLevel) ?? 0
    const description  = asNonEmptyString(payload.description) || null

    if (!sku || !name || !categoryId) return res.status(400).json(envelope({ error: { message: 'sku, name, and categoryId are required' } }))
    if (unitCost < 0 || listPrice < 0 || reorderLevel < 0) return res.status(400).json(envelope({ error: { message: 'unitCost, listPrice, and reorderLevel must be non-negative' } }))

    const p = await getPool()
    const request = p.request()
    request.input('sku',          sql.NVarChar(64),    sku)
    request.input('name',         sql.NVarChar(200),   name)
    request.input('description',  sql.NVarChar(sql.MAX), description)
    request.input('categoryId',   sql.Int,             categoryId)
    request.input('unitOfMeasure',sql.NVarChar(20),    unitOfMeasure)
    request.input('unitCost',     sql.Decimal(18,4),   unitCost)
    request.input('listPrice',    sql.Decimal(18,4),   listPrice)
    request.input('reorderLevel', sql.Int,             reorderLevel)
    request.input('supplierId',   sql.Int,             supplierId || null)
    const inserted  = await request.query(`
      INSERT INTO dbo.Products (Sku, Name, Description, CategoryId, UnitOfMeasure, UnitCost, ListPrice, ReorderLevel, SupplierId)
      OUTPUT inserted.ProductId
      VALUES (@sku, @name, @description, @categoryId, @unitOfMeasure, @unitCost, @listPrice, @reorderLevel, @supplierId)
    `)
    return res.status(201).json(envelope({ data: { productId: inserted.recordset[0]?.ProductId } }))
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.post('/api/stock-adjustments', requireAuth, async (req, res) => {
  try {
    const payload       = req.body || {}
    const productId     = asInt(payload.productId)
    const locationId    = asInt(payload.locationId)
    const quantityDelta = asInt(payload.quantityDelta)
    const note          = asNonEmptyString(payload.note) || null

    if (!productId || !locationId || !quantityDelta) return res.status(400).json(envelope({ error: { message: 'productId, locationId, and non-zero quantityDelta are required' } }))

    const p = await getPool()
    const request = p.request()
    request.input('productId',     sql.Int,          productId)
    request.input('locationId',    sql.Int,          locationId)
    request.input('quantityDelta', sql.Int,          quantityDelta)
    request.input('note',          sql.NVarChar(500), note)
    const result = await request.query(`
      INSERT INTO dbo.StockMovements (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, Note, CreatedByUserId)
      OUTPUT inserted.MovementId
      VALUES (@productId, @locationId, @quantityDelta, N'ADJUSTMENT', N'ADJUSTMENT', @note, NULL);
    `)
    return res.status(201).json(envelope({ data: { movementId: result.recordset[0]?.MovementId } }))
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// SALES ORDERS (protected)
// =============================================================================

app.get('/api/sales-orders', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT SalesOrderId, OrderNumber, OrderDate, OrderStatus, CustomerName, FulfillmentLocation, LinesTotal
      FROM dbo.vw_SalesOrderSummary
      ORDER BY OrderDate DESC;
    `)
    res.json(envelope({ data: result.recordset }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// INVOICES (protected)
// =============================================================================

app.get('/api/invoices', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT InvoiceId, InvoiceNumber, InvoiceDate, PaymentStatus, OrderNumber, OrderStatus,
             CustomerName, CustomerEmail, FulfillingLocation, SubTotal, TaxAmount, TotalAmount, SalesRep
      FROM dbo.vw_InvoiceSummary
      ORDER BY InvoiceDate DESC;
    `)
    res.json(envelope({ data: result.recordset }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.patch('/api/invoices/:id/pay', requireAuth, async (req, res) => {
  try {
    const invoiceId = asInt(req.params.id)
    if (!invoiceId) return res.status(400).json(envelope({ error: { message: 'Invalid invoiceId' } }))
    const p = await getPool()
    const request = p.request()
    request.input('invoiceId', sql.Int, invoiceId)
    await request.query(`UPDATE dbo.Invoices SET PaymentStatus = N'PAID' WHERE InvoiceId = @invoiceId AND IsDeleted = 0;`)
    return res.json(envelope({ data: { updated: true } }))
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// PURCHASE ORDERS (protected)
// =============================================================================

app.get('/api/purchase-orders', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT PurchaseOrderId, PoNumber, OrderDate, Status, Supplier, ShipToLocation,
             CreatedBy, LineCount, TotalQtyOrdered, TotalQtyReceived,
             TotalOrderedValue, TotalReceivedValue, FulfilmentPct
      FROM dbo.vw_PurchaseOrderSummary
      ORDER BY OrderDate DESC;
    `)
    res.json(envelope({ data: result.recordset }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// LOW STOCK (protected)
// =============================================================================

app.get('/api/low-stock', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT ProductId, Sku, ProductName, Category, Supplier, ReorderLevel, TotalOnHand, ShortfallQty
      FROM dbo.vw_LowStockAlert
      ORDER BY ShortfallQty DESC;
    `)
    res.json(envelope({ data: result.recordset }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// SERVICE JOBS (protected)
// =============================================================================

app.get('/api/service-jobs', requireAuth, async (req, res) => {
  try {
    const p = await getPool()
    const result = await p.request().query(`
      SELECT
        sj.JobId, sj.JobNumber, sj.JobStatus, sj.ScheduledDate, sj.CompletedDate,
        sj.Notes, sj.AssigneeName, sj.CreatedAt,
        c.Name  AS CustomerName,
        l.Name  AS LocationName, l.Code AS LocationCode,
        u.FullName AS ManagerName,
        (SELECT COUNT(*) FROM dbo.ServiceJobMaterials m WHERE m.JobId = sj.JobId) AS MaterialCount,
        ISNULL((SELECT SUM(p2.UnitCost * m2.QuantityRequired)
                FROM dbo.ServiceJobMaterials m2
                INNER JOIN dbo.Products p2 ON p2.ProductId = m2.ProductId
                WHERE m2.JobId = sj.JobId), 0) AS EstimatedCost
      FROM dbo.ServiceJobs sj
      INNER JOIN dbo.Customers c ON c.CustomerId = sj.CustomerId
      INNER JOIN dbo.Locations l ON l.LocationId  = sj.LocationId
      LEFT  JOIN dbo.Users    u ON u.UserId       = sj.ManagedByUserId
      WHERE sj.IsDeleted = 0
      ORDER BY sj.CreatedAt DESC;
    `)
    res.json(envelope({ data: result.recordset }))
  } catch (e) {
    console.error(e)
    res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.get('/api/service-jobs/:id', requireAuth, async (req, res) => {
  try {
    const jobId = asInt(req.params.id)
    if (!jobId) return res.status(400).json(envelope({ error: { message: 'Invalid jobId' } }))
    const p    = await getPool()
    const req2 = p.request()
    req2.input('jobId', sql.BigInt, jobId)
    const result = await req2.query(`
      SELECT sj.JobId, sj.JobNumber, sj.JobStatus, sj.ScheduledDate, sj.CompletedDate,
             sj.Notes, sj.AssigneeName, sj.CreatedAt, sj.CustomerId, sj.LocationId,
             c.Name  AS CustomerName, c.Email AS CustomerEmail, c.Phone AS CustomerPhone,
             l.Name  AS LocationName, l.Code AS LocationCode,
             u.FullName AS ManagerName,
             ISNULL((SELECT SUM(p2.UnitCost * m2.QuantityRequired)
                     FROM dbo.ServiceJobMaterials m2
                     INNER JOIN dbo.Products p2 ON p2.ProductId = m2.ProductId
                     WHERE m2.JobId = sj.JobId), 0) AS EstimatedCost
      FROM dbo.ServiceJobs sj
      INNER JOIN dbo.Customers c ON c.CustomerId = sj.CustomerId
      INNER JOIN dbo.Locations l ON l.LocationId  = sj.LocationId
      LEFT  JOIN dbo.Users    u ON u.UserId       = sj.ManagedByUserId
      WHERE sj.JobId = @jobId AND sj.IsDeleted = 0;

      SELECT m.JobMaterialId, m.LineNumber, m.QuantityRequired, m.QuantityUsed,
             p.ProductId, p.Sku, p.Name AS ProductName,
             p.UnitCost, p.UnitOfMeasure,
             CAST(p.UnitCost * m.QuantityRequired AS DECIMAL(18,4)) AS LineTotal
      FROM dbo.ServiceJobMaterials m
      INNER JOIN dbo.Products p ON p.ProductId = m.ProductId
      WHERE m.JobId = @jobId
      ORDER BY m.LineNumber;
    `)
    const job = result.recordsets[0]?.[0]
    if (!job) return res.status(404).json(envelope({ error: { message: 'Service job not found' } }))
    return res.json(envelope({ data: { ...job, materials: result.recordsets[1] || [] } }))
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.post('/api/service-jobs', requireAuth, async (req, res) => {
  try {
    const payload       = req.body || {}
    const customerId    = asInt(payload.customerId)
    const locationId    = asInt(payload.locationId)
    const assigneeName  = asNonEmptyString(payload.assigneeName)
    const scheduledDate = asNonEmptyString(payload.scheduledDate)
    const notes         = asNonEmptyString(payload.notes) || null
    const materials     = Array.isArray(payload.materials) ? payload.materials : []

    if (!customerId || !locationId || !scheduledDate)
      return res.status(400).json(envelope({ error: { message: 'customerId, locationId, and scheduledDate are required' } }))
    if (materials.length === 0)
      return res.status(400).json(envelope({ error: { message: 'At least one material line is required' } }))

    const p           = await getPool()
    const transaction = new sql.Transaction(p)
    await transaction.begin()
    try {
      const yearStr    = new Date().getFullYear()
      const req1       = new sql.Request(transaction)
      const countRes   = await req1.query(`SELECT COUNT(*) AS Cnt FROM dbo.ServiceJobs`)
      const seq        = String(countRes.recordset[0].Cnt + 1).padStart(3, '0')
      const jobNumber  = `SJ-${yearStr}-${seq}`

      const req2 = new sql.Request(transaction)
      req2.input('jobNumber',    sql.NVarChar(32),  jobNumber)
      req2.input('customerId',   sql.Int,           customerId)
      req2.input('locationId',   sql.Int,           locationId)
      req2.input('assigneeName', sql.NVarChar(200), assigneeName || null)
      req2.input('scheduledDate', sql.DateTime2,    new Date(scheduledDate))
      req2.input('notes',        sql.NVarChar(500), notes)
      const inserted = await req2.query(`
        INSERT INTO dbo.ServiceJobs (JobNumber, CustomerId, LocationId, AssigneeName, ScheduledDate, Notes)
        OUTPUT inserted.JobId
        VALUES (@jobNumber, @customerId, @locationId, @assigneeName, @scheduledDate, @notes)
      `)
      const jobId = inserted.recordset[0]?.JobId

      for (let i = 0; i < materials.length; i++) {
        const mat       = materials[i]
        const productId = Number(mat.productId)
        const qty       = Number(mat.quantity)
        if (!productId || qty <= 0) continue
        const req3 = new sql.Request(transaction)
        req3.input('jobId',      sql.BigInt, jobId)
        req3.input('lineNumber', sql.Int,    i + 1)
        req3.input('productId',  sql.Int,    productId)
        req3.input('qty',        sql.Int,    qty)
        await req3.query(`
          INSERT INTO dbo.ServiceJobMaterials (JobId, LineNumber, ProductId, QuantityRequired)
          VALUES (@jobId, @lineNumber, @productId, @qty)
        `)
      }

      await transaction.commit()
      return res.status(201).json(envelope({ data: { jobId, jobNumber } }))
    } catch (innerErr) {
      await transaction.rollback().catch(() => {})
      throw innerErr
    }
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.patch('/api/service-jobs/:id/start', requireAuth, async (req, res) => {
  try {
    const jobId = asInt(req.params.id)
    if (!jobId) return res.status(400).json(envelope({ error: { message: 'Invalid jobId' } }))
    const p    = await getPool()
    const req2 = p.request()
    req2.input('jobId', sql.BigInt, jobId)
    const check = await req2.query(`SELECT JobStatus FROM dbo.ServiceJobs WHERE JobId = @jobId AND IsDeleted = 0`)
    if (!check.recordset[0]) return res.status(404).json(envelope({ error: { message: 'Job not found' } }))
    if (check.recordset[0].JobStatus !== 'PENDING')
      return res.status(409).json(envelope({ error: { message: 'Job must be PENDING to start' } }))
    const req3 = p.request()
    req3.input('jobId', sql.BigInt, jobId)
    await req3.query(`UPDATE dbo.ServiceJobs SET JobStatus = N'IN_PROGRESS' WHERE JobId = @jobId`)
    return res.json(envelope({ data: { started: true } }))
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

app.patch('/api/service-jobs/:id/complete', requireAuth, async (req, res) => {
  try {
    const jobId = asInt(req.params.id)
    if (!jobId) return res.status(400).json(envelope({ error: { message: 'Invalid jobId' } }))
    const p           = await getPool()
    const transaction = new sql.Transaction(p)
    await transaction.begin()
    try {
      const req1 = new sql.Request(transaction)
      req1.input('jobId', sql.BigInt, jobId)
      const jobRes = await req1.query(`SELECT JobId, JobStatus, LocationId FROM dbo.ServiceJobs WHERE JobId = @jobId AND IsDeleted = 0`)
      const job    = jobRes.recordset[0]
      if (!job) { await transaction.rollback(); return res.status(404).json(envelope({ error: { message: 'Job not found' } })) }
      if (!['PENDING', 'IN_PROGRESS'].includes(job.JobStatus)) {
        await transaction.rollback()
        return res.status(409).json(envelope({ error: { message: `Cannot complete job with status: ${job.JobStatus}` } }))
      }

      const req2   = new sql.Request(transaction)
      req2.input('jobId', sql.BigInt, jobId)
      const matsRes = await req2.query(`SELECT ProductId, QuantityRequired, JobMaterialId FROM dbo.ServiceJobMaterials WHERE JobId = @jobId`)
      const mats    = matsRes.recordset

      for (const mat of mats) {
        // Insert movement — trigger auto-updates StockLevels
        const req3 = new sql.Request(transaction)
        req3.input('productId',  sql.Int,    mat.ProductId)
        req3.input('locationId', sql.Int,    job.LocationId)
        req3.input('qty',        sql.Int,    -mat.QuantityRequired)
        req3.input('refId',      sql.BigInt, jobId)
        await req3.query(`
          INSERT INTO dbo.StockMovements
            (ProductId, LocationId, QuantityDelta, MovementType, ReferenceType, ReferenceId, Note)
          VALUES
            (@productId, @locationId, @qty, N'SALE', N'SERVICE_JOB', @refId,
             N'Auto-deducted: service job completion')
        `)
        // Mark qty used
        const req4 = new sql.Request(transaction)
        req4.input('matId', sql.BigInt, mat.JobMaterialId)
        req4.input('qty',   sql.Int,    mat.QuantityRequired)
        await req4.query(`UPDATE dbo.ServiceJobMaterials SET QuantityUsed = @qty WHERE JobMaterialId = @matId`)
      }

      const req5 = new sql.Request(transaction)
      req5.input('jobId', sql.BigInt, jobId)
      await req5.query(`UPDATE dbo.ServiceJobs SET JobStatus = N'COMPLETED', CompletedDate = SYSDATETIME() WHERE JobId = @jobId`)

      await transaction.commit()
      return res.json(envelope({ data: { completed: true, materialsDeducted: mats.length } }))
    } catch (innerErr) {
      await transaction.rollback().catch(() => {})
      throw innerErr
    }
  } catch (e) {
    console.error(e)
    return res.status(500).json(envelope({ error: { message: String(e.message || e) } }))
  }
})

// =============================================================================
// SERVER START
// =============================================================================

const server = app.listen(PORT, () => {
  console.log(`Inventory API listening on http://localhost:${PORT}`)
  console.log('SQL smoke test: npm run test:sql (in web/server folder)')
})

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`\nPort ${PORT} is already in use. Close the other process or set PORT=3002 in .env\n`)
  } else {
    console.error(err)
  }
  process.exit(1)
})

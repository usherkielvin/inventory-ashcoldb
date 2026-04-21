import { useEffect, useMemo, useState } from 'react'

// ─── Types ────────────────────────────────────────────────────────────────────
type Page = 'dashboard' | 'products' | 'sales-orders' | 'invoices' | 'purchase-orders'

type User = { email: string; role: string; fullName: string }

type ApiEnvelope<T> = {
  data: T | null
  error: { message: string; hint?: string } | null
  meta: Record<string, unknown>
}

type HealthData    = { ok: boolean; database?: string; serverVersion?: string }
type LookupCategory = { CategoryId: number; Name: string }
type LookupSupplier = { SupplierId: number; Name: string }
type LookupLocation = { LocationId: number; Code: string; Name: string; LocationType: string }
type LookupData    = { categories: LookupCategory[]; suppliers: LookupSupplier[]; locations: LookupLocation[] }

type Product = {
  ProductId: number; Sku: string; Name: string; UnitOfMeasure: string
  UnitCost: number; ListPrice: number; ReorderLevel: number
  CategoryName: string; SupplierName: string | null
}
type ProductListMeta = { page: number; pageSize: number; total: number; totalPages: number; sortBy: string; sortDir: 'asc' | 'desc' }
type ProductDetails = Product & { Description?: string | null; stockByLocation: Array<{ LocationId: number; Code: string; Name: string; LocationType: string; QuantityOnHand: number }> }

type DashStats = { TotalProducts: number; LowStockCount: number; PendingOrders: number; TotalRevenuePaid: number; UnpaidInvoices: number }

type SalesOrder = { SalesOrderId: number; OrderNumber: string; OrderDate: string; OrderStatus: string; CustomerName: string; FulfillmentLocation: string; LinesTotal: number }

type Invoice = { InvoiceId: number; InvoiceNumber: string; InvoiceDate: string; PaymentStatus: string; OrderNumber: string; OrderStatus: string; CustomerName: string; CustomerEmail: string; FulfillingLocation: string; SubTotal: number; TaxAmount: number; TotalAmount: number; SalesRep: string | null }

type PurchaseOrder = { PurchaseOrderId: number; PoNumber: string; OrderDate: string; Status: string; Supplier: string; ShipToLocation: string; CreatedBy: string | null; LineCount: number; TotalQtyOrdered: number; TotalQtyReceived: number; TotalOrderedValue: number; TotalReceivedValue: number; FulfilmentPct: number }

type LowStockItem = { ProductId: number; Sku: string; ProductName: string; Category: string; Supplier: string; ReorderLevel: number; TotalOnHand: number; ShortfallQty: number }

// ─── API Helper ───────────────────────────────────────────────────────────────
function makeApi(token: string) {
  return async function apiFetch<T>(url: string, init?: RequestInit): Promise<ApiEnvelope<T>> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json', ...(init?.headers as Record<string, string>) }
    if (token) headers['Authorization'] = `Bearer ${token}`
    const response = await fetch(url, { ...init, headers })
    const payload = (await response.json().catch(() => ({}))) as Partial<ApiEnvelope<T>>
    if (!response.ok) throw new Error(payload.error?.message || response.statusText || 'Request failed')
    return payload as ApiEnvelope<T>
  }
}

// ─── Utilities ────────────────────────────────────────────────────────────────
function fmt(n: number) { return new Intl.NumberFormat('en-PH', { style: 'currency', currency: 'PHP' }).format(n) }
function fmtDate(s: string) { return new Date(s).toLocaleDateString('en-PH', { year: 'numeric', month: 'short', day: 'numeric' }) }
function initials(name: string) { return name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase() }

// ─── Status Badge ─────────────────────────────────────────────────────────────
function Badge({ status }: { status: string }) {
  const map: Record<string, string> = {
    PAID: 'badge-green', RECEIVED: 'badge-green', COMPLETED: 'badge-green',
    UNPAID: 'badge-amber', PARTIAL: 'badge-amber', SHIPPED: 'badge-amber',
    OPEN: 'badge-blue', CONFIRMED: 'badge-blue',
    DRAFT: 'badge-muted', CANCELLED: 'badge-muted',
  }
  return <span className={`badge ${map[status] ?? 'badge-muted'}`}>{status}</span>
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────
function ProgressBar({ pct }: { pct: number }) {
  const color = pct >= 100 ? 'var(--green)' : pct === 0 ? 'var(--text-dim)' : 'var(--amber)'
  return (
    <div className="progress-wrap">
      <div className="progress-bar"><div className="progress-fill" style={{ width: `${Math.min(pct,100)}%`, background: color }} /></div>
      <span className="progress-label">{pct.toFixed(0)}%</span>
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ═════════════════════════════════════════════════════════════════════════════
function LoginPage({ onLogin }: { onLogin: (token: string, user: User) => void }) {
  const [email,    setEmail]    = useState('admin@ashcol.local')
  const [password, setPassword] = useState('')
  const [loading,  setLoading]  = useState(false)
  const [error,    setError]    = useState('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true); setError('')
    try {
      const res  = await fetch('/api/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) })
      const data = await res.json() as ApiEnvelope<{ token: string; email: string; role: string; fullName: string }>
      if (!res.ok || !data.data) { setError(data.error?.message ?? 'Login failed'); return }
      onLogin(data.data.token, { email: data.data.email, role: data.data.role, fullName: data.data.fullName })
    } catch { setError('Cannot connect to API. Make sure npm run dev is running.') }
    finally { setLoading(false) }
  }

  return (
    <div className="login-bg">
      <div className="login-card" style={{ animation: 'fadeSlideUp 0.4s ease' }}>
        <div className="login-brand">
          <div className="brand-icon">📦</div>
          <div><strong>Ashcol Inventory</strong><p>Management System</p></div>
        </div>

        <h2>Welcome back</h2>
        <p className="sub">Sign in to your account to continue</p>

        {error && <div className="alert alert-error">⚠ {error}</div>}

        <form className="form-grid" onSubmit={handleSubmit}>
          <label>Email address
            <input id="login-email" type="email" value={email} required autoFocus
              onChange={e => setEmail(e.target.value)} placeholder="you@ashcol.local" />
          </label>
          <label>Password
            <input id="login-password" type="password" value={password} required
              onChange={e => setPassword(e.target.value)} placeholder="••••••••" />
          </label>
          <button id="login-submit" className="btn btn-full" style={{ marginTop: '0.4rem' }} disabled={loading}>
            {loading ? '⏳ Signing in…' : '→ Sign in'}
          </button>
        </form>

        <div className="demo-hint">
          <p className="dem-label">Demo credentials</p>
          <p><strong>admin@ashcol.local</strong> / admin123 — Administrator</p>
          <p><strong>juan.delacruz@ashcol.local</strong> / staff123 — Staff</p>
          <p><strong>maria.santos@ashcol.local</strong> / staff123 — Staff</p>
        </div>
      </div>
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═════════════════════════════════════════════════════════════════════════════
function Sidebar({ page, setPage, user, onLogout }: { page: Page; setPage: (p: Page) => void; user: User; onLogout: () => void }) {
  const navItems: { id: Page; icon: string; label: string }[] = [
    { id: 'dashboard',       icon: '⬛', label: 'Dashboard' },
    { id: 'products',        icon: '📦', label: 'Products' },
    { id: 'sales-orders',    icon: '🛒', label: 'Sales Orders' },
    { id: 'invoices',        icon: '🧾', label: 'Invoices' },
    { id: 'purchase-orders', icon: '📋', label: 'Purchase Orders' },
  ]

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="b-icon">📦</div>
        <div className="b-text"><strong>Ashcol Inventory</strong><span>Management System</span></div>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section-label">Main Menu</div>
        {navItems.map(item => (
          <button key={item.id} id={`nav-${item.id}`} className={`nav-item${page === item.id ? ' active' : ''}`} onClick={() => setPage(item.id)}>
            <span className="nav-icon">{item.icon}</span>
            {item.label}
          </button>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="user-chip">
          <div className="user-avatar">{initials(user.fullName)}</div>
          <div className="user-info"><strong>{user.fullName.split(' ')[0]}</strong><span>{user.role}</span></div>
        </div>
        <button id="btn-logout" className="btn btn-ghost btn-sm" style={{ width: '100%' }} onClick={onLogout}>↩ Sign out</button>
      </div>
    </aside>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD PAGE
// ═════════════════════════════════════════════════════════════════════════════
function DashboardPage({ api, health }: { api: ReturnType<typeof makeApi>; health: HealthData | null }) {
  const [stats,     setStats]     = useState<DashStats | null>(null)
  const [lowStock,  setLowStock]  = useState<LowStockItem[]>([])
  const [loading,   setLoading]   = useState(true)

  useEffect(() => {
    setLoading(true)
    Promise.all([
      api<DashStats>('/api/dashboard').then(r => setStats(r.data)),
      api<LowStockItem[]>('/api/low-stock').then(r => setLowStock(r.data ?? [])),
    ]).finally(() => setLoading(false))
  }, [])

  const statCards = [
    { id: 'stat-products',   icon: '📦', label: 'Total Products',    value: stats?.TotalProducts  ?? '—', color: 'var(--blue)'   },
    { id: 'stat-low-stock',  icon: '⚠️', label: 'Low Stock Items',   value: stats?.LowStockCount  ?? '—', color: 'var(--amber)'  },
    { id: 'stat-orders',     icon: '🛒', label: 'Pending Orders',    value: stats?.PendingOrders  ?? '—', color: 'var(--purple)' },
    { id: 'stat-revenue',    icon: '💰', label: 'Revenue Collected', value: stats ? fmt(stats.TotalRevenuePaid) : '—', color: 'var(--green)'  },
  ]

  return (
    <div className="main">
      <div className="page-header">
        <h1>Dashboard</h1>
        <p>Real-time overview of your inventory system</p>
      </div>

      {health?.ok && (
        <div className="health-bar">
          <span className="dot" />
          Connected to <strong style={{ marginLeft: 4 }}>{health.database}</strong>
          <span className="text-muted" style={{ marginLeft: 8, fontSize: '0.78rem' }}>— {health.serverVersion}</span>
        </div>
      )}

      {loading ? <p className="text-muted">Loading stats…</p> : (
        <>
          <div className="card-grid">
            {statCards.map(sc => (
              <div key={sc.id} id={sc.id} className="stat-card" style={{ '--stat-color': sc.color } as React.CSSProperties}>
                <div className="stat-icon">{sc.icon}</div>
                <div className="stat-value">{sc.value}</div>
                <div className="stat-label">{sc.label}</div>
              </div>
            ))}
          </div>

          {lowStock.length > 0 && (
            <div className="card" style={{ marginTop: '1rem' }}>
              <div className="section-head">
                <h2>⚠️ Low Stock Alerts</h2>
                <span className="badge badge-amber">{lowStock.length} item{lowStock.length !== 1 ? 's' : ''}</span>
              </div>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>SKU</th><th>Product</th><th>Category</th><th>On Hand</th><th>Reorder Level</th><th>Shortfall</th></tr></thead>
                  <tbody>
                    {lowStock.map(r => (
                      <tr key={r.ProductId}>
                        <td className="mono">{r.Sku}</td>
                        <td>{r.ProductName}</td>
                        <td>{r.Category}</td>
                        <td style={{ color: r.TotalOnHand === 0 ? 'var(--red)' : 'var(--amber)', fontWeight: 600 }}>{r.TotalOnHand}</td>
                        <td>{r.ReorderLevel}</td>
                        <td style={{ color: 'var(--red)', fontWeight: 700 }}>−{r.ShortfallQty}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// PRODUCTS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function ProductsPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [lookups,   setLookups]   = useState<LookupData>({ categories: [], suppliers: [], locations: [] })
  const [products,  setProducts]  = useState<Product[]>([])
  const [meta,      setMeta]      = useState<ProductListMeta>({ page: 1, pageSize: 10, total: 0, totalPages: 1, sortBy: 'Sku', sortDir: 'asc' })
  const [loading,   setLoading]   = useState(false)
  const [search,    setSearch]    = useState('')
  const [filters,   setFilters]   = useState({ q: '', categoryId: '', supplierId: '', sortBy: 'sku', sortDir: 'asc', page: 1 })
  const [selected,  setSelected]  = useState<ProductDetails | null>(null)
  const [detailLoading, setDL]    = useState(false)
  const [message,   setMessage]   = useState<{ text: string; ok: boolean } | null>(null)
  const [draft,     setDraft]     = useState({ sku:'', name:'', categoryId:'', supplierId:'', unitOfMeasure:'PCS', unitCost:'0', listPrice:'0', reorderLevel:'0', description:'' })
  const [adj,       setAdj]       = useState({ productId:'', locationId:'', quantityDelta:'', note:'' })
  const [saving,    setSaving]    = useState(false)

  const startIdx = useMemo(() => meta.total === 0 ? 0 : (meta.page - 1) * meta.pageSize + 1, [meta])
  const endIdx   = useMemo(() => Math.min(meta.total, meta.page * meta.pageSize), [meta])

  useEffect(() => {
    api<LookupData>('/api/lookups').then(r => setLookups(r.data ?? { categories: [], suppliers: [], locations: [] }))
    loadProducts(filters)
  }, [])

  async function loadProducts(f = filters) {
    setLoading(true)
    const params = new URLSearchParams({ page: String(f.page), pageSize: '10', sortBy: f.sortBy, sortDir: f.sortDir })
    if (f.q) params.set('q', f.q)
    if (f.categoryId) params.set('categoryId', f.categoryId)
    if (f.supplierId)  params.set('supplierId',  f.supplierId)
    try {
      const res = await api<Product[]>(`/api/products?${params}`)
      setProducts(res.data ?? [])
      const m = res.meta as Partial<ProductListMeta>
      setMeta({ page: Number(m.page||1), pageSize: Number(m.pageSize||10), total: Number(m.total||0), totalPages: Number(m.totalPages||1), sortBy: String(m.sortBy||'Sku'), sortDir: (String(m.sortDir||'asc')) as 'asc'|'desc' })
    } finally { setLoading(false) }
  }

  async function loadDetails(id: number) {
    setDL(true)
    try { const r = await api<ProductDetails>(`/api/products/${id}`); setSelected(r.data) }
    finally { setDL(false) }
  }

  function applyFilters() {
    const next = { ...filters, q: search.trim(), page: 1 }
    setFilters(next); loadProducts(next)
  }

  function resetFilters() {
    const next = { q:'', categoryId:'', supplierId:'', sortBy:'sku', sortDir:'asc', page:1 }
    setSearch(''); setFilters(next); loadProducts(next)
  }

  function setSort(sortBy: string) {
    const next = { ...filters, sortBy, sortDir: filters.sortBy===sortBy && filters.sortDir==='asc' ? 'desc' : 'asc', page: 1 }
    setFilters(next); loadProducts(next)
  }

  function goPage(p: number) {
    const next = { ...filters, page: Math.max(1, Math.min(meta.totalPages, p)) }
    setFilters(next); loadProducts(next)
  }

  async function submitProduct(e: React.FormEvent) {
    e.preventDefault(); setSaving(true); setMessage(null)
    try {
      await api<{ productId: number }>('/api/products', { method: 'POST', body: JSON.stringify({ ...draft, categoryId: Number(draft.categoryId), supplierId: draft.supplierId ? Number(draft.supplierId) : null, unitCost: Number(draft.unitCost), listPrice: Number(draft.listPrice), reorderLevel: Number(draft.reorderLevel) }) })
      setDraft({ sku:'', name:'', categoryId:'', supplierId:'', unitOfMeasure:'PCS', unitCost:'0', listPrice:'0', reorderLevel:'0', description:'' })
      setMessage({ text: 'Product created successfully.', ok: true })
      loadProducts()
    } catch (err) { setMessage({ text: String(err instanceof Error ? err.message : err), ok: false }) }
    finally { setSaving(false) }
  }

  async function submitAdj(e: React.FormEvent) {
    e.preventDefault(); setSaving(true); setMessage(null)
    try {
      await api<{ movementId: number }>('/api/stock-adjustments', { method: 'POST', body: JSON.stringify({ productId: Number(adj.productId), locationId: Number(adj.locationId), quantityDelta: Number(adj.quantityDelta), note: adj.note }) })
      setAdj({ productId:'', locationId:'', quantityDelta:'', note:'' })
      setMessage({ text: 'Stock adjustment saved.', ok: true })
      loadProducts()
      if (selected) loadDetails(selected.ProductId)
    } catch (err) { setMessage({ text: String(err instanceof Error ? err.message : err), ok: false }) }
    finally { setSaving(false) }
  }

  return (
    <div className="main">
      <div className="page-header">
        <h1>Products</h1>
        <p>Browse and manage your product catalog</p>
      </div>

      <div className="card" style={{ marginBottom: '1.25rem' }}>
        <div className="section-head">
          <h2>Catalog</h2>
          <button className="btn btn-ghost btn-sm" id="btn-refresh-products" onClick={() => loadProducts()} disabled={loading}>↻ Refresh</button>
        </div>

        <div className="toolbar">
          <div className="field">
            <label>Search</label>
            <input id="search-products" value={search} onChange={e => setSearch(e.target.value)} placeholder="SKU or Name" onKeyDown={e => e.key === 'Enter' && applyFilters()} />
          </div>
          <div className="field">
            <label>Category</label>
            <select id="filter-category" value={filters.categoryId} onChange={e => setFilters(s => ({ ...s, categoryId: e.target.value, page: 1 }))}>
              <option value="">All</option>
              {lookups.categories.map(c => <option key={c.CategoryId} value={c.CategoryId}>{c.Name}</option>)}
            </select>
          </div>
          <div className="field">
            <label>Supplier</label>
            <select id="filter-supplier" value={filters.supplierId} onChange={e => setFilters(s => ({ ...s, supplierId: e.target.value, page: 1 }))}>
              <option value="">All</option>
              {lookups.suppliers.map(s => <option key={s.SupplierId} value={s.SupplierId}>{s.Name}</option>)}
            </select>
          </div>
          <button className="btn btn-sm" id="btn-apply-filters" onClick={applyFilters} disabled={loading}>Apply</button>
          <button className="btn btn-ghost btn-sm" id="btn-reset-filters" onClick={resetFilters} disabled={loading}>Reset</button>
        </div>

        <div className="table-wrap">
          <table>
            <thead><tr>
              <th><button className="head-btn" onClick={() => setSort('sku')}>SKU</button></th>
              <th><button className="head-btn" onClick={() => setSort('name')}>Name</button></th>
              <th><button className="head-btn" onClick={() => setSort('category')}>Category</button></th>
              <th>UOM</th>
              <th><button className="head-btn" onClick={() => setSort('price')}>List Price</button></th>
              <th>Supplier</th>
              <th>Action</th>
            </tr></thead>
            <tbody>
              {loading && <tr><td colSpan={7} className="text-muted">Loading…</td></tr>}
              {!loading && products.length === 0 && <tr><td colSpan={7} className="text-muted">No products match your filters.</td></tr>}
              {!loading && products.map(p => (
                <tr key={p.ProductId}>
                  <td className="mono">{p.Sku}</td>
                  <td>{p.Name}</td>
                  <td>{p.CategoryName}</td>
                  <td>{p.UnitOfMeasure}</td>
                  <td>{fmt(Number(p.ListPrice))}</td>
                  <td>{p.SupplierName ?? '—'}</td>
                  <td><button className="btn btn-sm" onClick={() => loadDetails(p.ProductId)}>Details</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="pagination">
          <span className="text-muted">Showing {startIdx}–{endIdx} of {meta.total}</span>
          <div className="pager-buttons">
            <button className="btn btn-ghost btn-sm" onClick={() => goPage(meta.page - 1)} disabled={meta.page <= 1 || loading}>‹ Prev</button>
            <span>Page {meta.page} / {meta.totalPages}</span>
            <button className="btn btn-ghost btn-sm" onClick={() => goPage(meta.page + 1)} disabled={meta.page >= meta.totalPages || loading}>Next ›</button>
          </div>
        </div>
      </div>

      <div className="grid-2">
        {/* Actions panel */}
        <div className="card">
          <h2 style={{ margin: '0 0 1rem' }}>Inventory Actions</h2>
          {message && <div className={`alert ${message.ok ? 'alert-success' : 'alert-error'}`}>{message.text}</div>}

          <p className="text-muted" style={{ fontSize: '0.82rem', margin: '0 0 0.5rem' }}>Add Product</p>
          <form className="form-grid" onSubmit={submitProduct} style={{ marginBottom: '1.5rem' }}>
            <label>SKU<input required value={draft.sku} onChange={e => setDraft(s => ({ ...s, sku: e.target.value }))} /></label>
            <label>Name<input required value={draft.name} onChange={e => setDraft(s => ({ ...s, name: e.target.value }))} /></label>
            <label>Category
              <select required value={draft.categoryId} onChange={e => setDraft(s => ({ ...s, categoryId: e.target.value }))}>
                <option value="">Select…</option>
                {lookups.categories.map(c => <option key={c.CategoryId} value={c.CategoryId}>{c.Name}</option>)}
              </select>
            </label>
            <label>Supplier
              <select value={draft.supplierId} onChange={e => setDraft(s => ({ ...s, supplierId: e.target.value }))}>
                <option value="">None</option>
                {lookups.suppliers.map(s => <option key={s.SupplierId} value={s.SupplierId}>{s.Name}</option>)}
              </select>
            </label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.6rem' }}>
              <label>UOM<input value={draft.unitOfMeasure} onChange={e => setDraft(s => ({ ...s, unitOfMeasure: e.target.value }))} /></label>
              <label>Reorder Level<input type="number" min="0" value={draft.reorderLevel} onChange={e => setDraft(s => ({ ...s, reorderLevel: e.target.value }))} /></label>
              <label>Unit Cost<input type="number" step="0.01" min="0" value={draft.unitCost} onChange={e => setDraft(s => ({ ...s, unitCost: e.target.value }))} /></label>
              <label>List Price<input type="number" step="0.01" min="0" value={draft.listPrice} onChange={e => setDraft(s => ({ ...s, listPrice: e.target.value }))} /></label>
            </div>
            <button className="btn" disabled={saving}>{saving ? 'Saving…' : 'Create Product'}</button>
          </form>

          <p className="text-muted" style={{ fontSize: '0.82rem', margin: '0 0 0.5rem' }}>Stock Adjustment</p>
          <form className="form-grid" onSubmit={submitAdj}>
            <label>Product
              <select required value={adj.productId} onChange={e => setAdj(s => ({ ...s, productId: e.target.value }))}>
                <option value="">Select product…</option>
                {products.map(p => <option key={p.ProductId} value={p.ProductId}>{p.Sku} — {p.Name}</option>)}
              </select>
            </label>
            <label>Location
              <select required value={adj.locationId} onChange={e => setAdj(s => ({ ...s, locationId: e.target.value }))}>
                <option value="">Select location…</option>
                {lookups.locations.map(l => <option key={l.LocationId} value={l.LocationId}>{l.Code} — {l.Name}</option>)}
              </select>
            </label>
            <label>Quantity Delta<input required type="number" value={adj.quantityDelta} onChange={e => setAdj(s => ({ ...s, quantityDelta: e.target.value }))} placeholder="Positive or negative" /></label>
            <label>Note<textarea rows={2} value={adj.note} onChange={e => setAdj(s => ({ ...s, note: e.target.value }))} /></label>
            <button className="btn" disabled={saving}>{saving ? 'Saving…' : 'Post Adjustment'}</button>
          </form>
        </div>

        {/* Detail panel */}
        <div className="card">
          <h2 style={{ margin: '0 0 1rem' }}>Product Details</h2>
          {!selected && !detailLoading && <p className="text-muted">Select a product from the table to view stock by location.</p>}
          {detailLoading && <p className="text-muted">Loading…</p>}
          {selected && !detailLoading && (
            <>
              <div className="detail-panel" style={{ marginBottom: '1rem' }}>
                <h3>{selected.Name}</h3>
                <p>{selected.Sku} · {selected.CategoryName} · {selected.SupplierName ?? 'No supplier'}</p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem', fontSize: '0.83rem' }}>
                  <div><span className="text-muted">Unit Cost</span><br /><strong>{fmt(Number(selected.UnitCost))}</strong></div>
                  <div><span className="text-muted">List Price</span><br /><strong>{fmt(Number(selected.ListPrice))}</strong></div>
                  <div><span className="text-muted">UOM</span><br /><strong>{selected.UnitOfMeasure}</strong></div>
                  <div><span className="text-muted">Reorder Level</span><br /><strong>{selected.ReorderLevel}</strong></div>
                </div>
              </div>
              <p className="text-muted" style={{ fontSize: '0.78rem', textTransform: 'uppercase', fontWeight: 600, letterSpacing: '0.05em', margin: '0 0 0.5rem' }}>Stock by Location</p>
              <div className="table-wrap">
                <table>
                  <thead><tr><th>Location</th><th>Type</th><th>On Hand</th></tr></thead>
                  <tbody>
                    {selected.stockByLocation.map(row => (
                      <tr key={row.LocationId}>
                        <td>{row.Code} — {row.Name}</td>
                        <td>{row.LocationType}</td>
                        <td style={{ fontWeight: 700, color: row.QuantityOnHand === 0 ? 'var(--red)' : row.QuantityOnHand < 5 ? 'var(--amber)' : 'var(--green)' }}>{row.QuantityOnHand}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// SALES ORDERS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function SalesOrdersPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [orders,  setOrders]  = useState<SalesOrder[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => { api<SalesOrder[]>('/api/sales-orders').then(r => setOrders(r.data ?? [])).finally(() => setLoading(false)) }, [])

  const totals = useMemo(() => ({
    revenue: orders.filter(o => ['CONFIRMED','SHIPPED','COMPLETED'].includes(o.OrderStatus)).reduce((s, o) => s + Number(o.LinesTotal), 0),
    byStatus: orders.reduce((acc, o) => { acc[o.OrderStatus] = (acc[o.OrderStatus] ?? 0) + 1; return acc }, {} as Record<string,number>),
  }), [orders])

  return (
    <div className="main">
      <div className="page-header">
        <h1>Sales Orders</h1>
        <p>All customer orders from the database</p>
      </div>

      <div className="card-grid" style={{ marginBottom: '1.25rem' }}>
        {Object.entries(totals.byStatus).map(([status, count]) => (
          <div key={status} className="stat-card" style={{ '--stat-color': status === 'COMPLETED' ? 'var(--green)' : status === 'SHIPPED' ? 'var(--amber)' : status === 'CONFIRMED' ? 'var(--blue)' : 'var(--text-muted)' } as React.CSSProperties}>
            <div className="stat-value">{count}</div>
            <div className="stat-label">{status}</div>
          </div>
        ))}
        <div className="stat-card" style={{ '--stat-color': 'var(--green)' } as React.CSSProperties}>
          <div className="stat-value">{fmt(totals.revenue)}</div>
          <div className="stat-label">Confirmed Revenue</div>
        </div>
      </div>

      <div className="card">
        <div className="section-head">
          <h2>All Orders</h2>
          <button className="btn btn-ghost btn-sm" onClick={() => { setLoading(true); api<SalesOrder[]>('/api/sales-orders').then(r => setOrders(r.data ?? [])).finally(() => setLoading(false)) }}>↻ Refresh</button>
        </div>
        <div className="table-wrap">
          <table>
            <thead><tr><th>Order #</th><th>Date</th><th>Customer</th><th>Location</th><th>Status</th><th>Total</th></tr></thead>
            <tbody>
              {loading && <tr><td colSpan={6} className="text-muted">Loading…</td></tr>}
              {!loading && orders.map(o => (
                <tr key={o.SalesOrderId}>
                  <td className="mono">{o.OrderNumber}</td>
                  <td>{fmtDate(o.OrderDate)}</td>
                  <td>{o.CustomerName}</td>
                  <td>{o.FulfillmentLocation}</td>
                  <td><Badge status={o.OrderStatus} /></td>
                  <td style={{ fontWeight: 600 }}>{fmt(Number(o.LinesTotal))}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// INVOICES PAGE
// ═════════════════════════════════════════════════════════════════════════════
function InvoicesPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [loading,  setLoading]  = useState(true)
  const [paying,   setPaying]   = useState<number | null>(null)
  const [message,  setMessage]  = useState<{ text: string; ok: boolean } | null>(null)

  useEffect(() => { api<Invoice[]>('/api/invoices').then(r => setInvoices(r.data ?? [])).finally(() => setLoading(false)) }, [])

  async function markPaid(inv: Invoice) {
    setPaying(inv.InvoiceId)
    try {
      await api(`/api/invoices/${inv.InvoiceId}/pay`, { method: 'PATCH' })
      setInvoices(prev => prev.map(i => i.InvoiceId === inv.InvoiceId ? { ...i, PaymentStatus: 'PAID' } : i))
      setMessage({ text: `${inv.InvoiceNumber} marked as PAID.`, ok: true })
    } catch (err) {
      setMessage({ text: String(err instanceof Error ? err.message : err), ok: false })
    } finally { setPaying(null) }
  }

  const totals = useMemo(() => ({
    paid:   invoices.filter(i => i.PaymentStatus === 'PAID').reduce((s, i)  => s + Number(i.TotalAmount), 0),
    unpaid: invoices.filter(i => i.PaymentStatus === 'UNPAID').reduce((s, i) => s + Number(i.TotalAmount), 0),
  }), [invoices])

  return (
    <div className="main">
      <div className="page-header">
        <h1>Invoices</h1>
        <p>Billing records for all completed and shipped orders</p>
      </div>

      <div className="card-grid" style={{ marginBottom: '1.25rem' }}>
        <div className="stat-card" style={{ '--stat-color': 'var(--green)' } as React.CSSProperties}>
          <div className="stat-icon">✅</div>
          <div className="stat-value">{fmt(totals.paid)}</div>
          <div className="stat-label">Collected Revenue</div>
        </div>
        <div className="stat-card" style={{ '--stat-color': 'var(--amber)' } as React.CSSProperties}>
          <div className="stat-icon">⏳</div>
          <div className="stat-value">{fmt(totals.unpaid)}</div>
          <div className="stat-label">Outstanding</div>
        </div>
        <div className="stat-card" style={{ '--stat-color': 'var(--blue)' } as React.CSSProperties}>
          <div className="stat-icon">🧾</div>
          <div className="stat-value">{invoices.length}</div>
          <div className="stat-label">Total Invoices</div>
        </div>
      </div>

      {message && <div className={`alert ${message.ok ? 'alert-success' : 'alert-error'}`} style={{ marginBottom: '1rem' }}>{message.text}</div>}

      <div className="card">
        <div className="section-head"><h2>All Invoices</h2></div>
        <div className="table-wrap">
          <table>
            <thead><tr><th>Invoice #</th><th>Date</th><th>Customer</th><th>Order</th><th>Sub-Total</th><th>VAT (12%)</th><th>Total</th><th>Status</th><th>Action</th></tr></thead>
            <tbody>
              {loading && <tr><td colSpan={9} className="text-muted">Loading…</td></tr>}
              {!loading && invoices.map(inv => (
                <tr key={inv.InvoiceId}>
                  <td className="mono">{inv.InvoiceNumber}</td>
                  <td>{fmtDate(inv.InvoiceDate)}</td>
                  <td>{inv.CustomerName}</td>
                  <td className="mono">{inv.OrderNumber}</td>
                  <td>{fmt(Number(inv.SubTotal))}</td>
                  <td>{fmt(Number(inv.TaxAmount))}</td>
                  <td style={{ fontWeight: 700 }}>{fmt(Number(inv.TotalAmount))}</td>
                  <td><Badge status={inv.PaymentStatus} /></td>
                  <td>
                    {inv.PaymentStatus === 'UNPAID'
                      ? <button id={`btn-pay-${inv.InvoiceId}`} className="btn btn-green btn-sm" disabled={paying === inv.InvoiceId} onClick={() => markPaid(inv)}>{paying === inv.InvoiceId ? '…' : '✓ Mark Paid'}</button>
                      : <span className="text-muted" style={{ fontSize: '0.78rem' }}>—</span>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// PURCHASE ORDERS PAGE
// ═════════════════════════════════════════════════════════════════════════════
function PurchaseOrdersPage({ api }: { api: ReturnType<typeof makeApi> }) {
  const [pos,     setPos]     = useState<PurchaseOrder[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => { api<PurchaseOrder[]>('/api/purchase-orders').then(r => setPos(r.data ?? [])).finally(() => setLoading(false)) }, [])

  return (
    <div className="main">
      <div className="page-header">
        <h1>Purchase Orders</h1>
        <p>Replenishment orders sent to suppliers</p>
      </div>

      <div className="card-grid" style={{ marginBottom: '1.25rem' }}>
        {['RECEIVED','PARTIAL','OPEN'].map(status => {
          const filtered = pos.filter(p => p.Status === status)
          return (
            <div key={status} className="stat-card" style={{ '--stat-color': status === 'RECEIVED' ? 'var(--green)' : status === 'PARTIAL' ? 'var(--amber)' : 'var(--blue)' } as React.CSSProperties}>
              <div className="stat-value">{filtered.length}</div>
              <div className="stat-label">{status} POs</div>
            </div>
          )
        })}
      </div>

      <div className="card">
        <div className="section-head"><h2>All Purchase Orders</h2></div>
        <div className="table-wrap">
          <table>
            <thead><tr><th>PO #</th><th>Date</th><th>Supplier</th><th>Ship To</th><th>Lines</th><th>Ordered Value</th><th>Status</th><th>Fulfilment</th></tr></thead>
            <tbody>
              {loading && <tr><td colSpan={8} className="text-muted">Loading…</td></tr>}
              {!loading && pos.map(po => (
                <tr key={po.PurchaseOrderId}>
                  <td className="mono">{po.PoNumber}</td>
                  <td>{fmtDate(po.OrderDate)}</td>
                  <td>{po.Supplier}</td>
                  <td>{po.ShipToLocation}</td>
                  <td style={{ textAlign: 'center' }}>{po.LineCount}</td>
                  <td>{fmt(Number(po.TotalOrderedValue))}</td>
                  <td><Badge status={po.Status} /></td>
                  <td style={{ minWidth: 140 }}><ProgressBar pct={Number(po.FulfilmentPct)} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT APP
// ═════════════════════════════════════════════════════════════════════════════
export default function App() {
  const [token,   setToken]   = useState<string>(() => localStorage.getItem('ashcol_token') ?? '')
  const [user,    setUser]    = useState<User | null>(() => { try { return JSON.parse(localStorage.getItem('ashcol_user') ?? 'null') } catch { return null } })
  const [page,    setPage]    = useState<Page>('dashboard')
  const [health,  setHealth]  = useState<HealthData | null>(null)

  const api = useMemo(() => makeApi(token), [token])

  useEffect(() => {
    if (token) api<HealthData>('/api/health').then(r => setHealth(r.data)).catch(() => {})
  }, [token])

  function handleLogin(newToken: string, newUser: User) {
    localStorage.setItem('ashcol_token', newToken)
    localStorage.setItem('ashcol_user', JSON.stringify(newUser))
    setToken(newToken)
    setUser(newUser)
    setPage('dashboard')
  }

  function handleLogout() {
    localStorage.removeItem('ashcol_token')
    localStorage.removeItem('ashcol_user')
    setToken(''); setUser(null)
  }

  if (!token || !user) return <LoginPage onLogin={handleLogin} />

  const pageComponent: Record<Page, React.ReactNode> = {
    'dashboard':       <DashboardPage api={api} health={health} />,
    'products':        <ProductsPage api={api} />,
    'sales-orders':    <SalesOrdersPage api={api} />,
    'invoices':        <InvoicesPage api={api} />,
    'purchase-orders': <PurchaseOrdersPage api={api} />,
  }

  return (
    <div className="layout">
      <Sidebar page={page} setPage={setPage} user={user} onLogout={handleLogout} />
      {pageComponent[page]}
    </div>
  )
}

import { useEffect, useMemo, useState } from 'react'

type ApiEnvelope<T> = {
  data: T | null
  error: { message: string; hint?: string } | null
  meta: Record<string, unknown>
}

type HealthData = { ok: boolean; database?: string; serverVersion?: string }

type LookupCategory = { CategoryId: number; Name: string }
type LookupSupplier = { SupplierId: number; Name: string }
type LookupLocation = { LocationId: number; Code: string; Name: string; LocationType: string }
type LookupData = { categories: LookupCategory[]; suppliers: LookupSupplier[]; locations: LookupLocation[] }

type Product = {
  ProductId: number
  Sku: string
  Name: string
  UnitOfMeasure: string
  UnitCost: number
  ListPrice: number
  ReorderLevel: number
  CategoryName: string
  SupplierName: string | null
}

type ProductListMeta = {
  page: number
  pageSize: number
  total: number
  totalPages: number
  sortBy: string
  sortDir: 'asc' | 'desc'
}

type ProductDetails = Product & {
  Description?: string | null
  stockByLocation: Array<{
    LocationId: number
    Code: string
    Name: string
    LocationType: string
    QuantityOnHand: number
  }>
}

type ProductDraft = {
  sku: string
  name: string
  categoryId: string
  supplierId: string
  unitOfMeasure: string
  unitCost: string
  listPrice: string
  reorderLevel: string
  description: string
}

type AdjustmentDraft = {
  productId: string
  locationId: string
  quantityDelta: string
  note: string
}

const EMPTY_PRODUCT: ProductDraft = {
  sku: '',
  name: '',
  categoryId: '',
  supplierId: '',
  unitOfMeasure: 'PCS',
  unitCost: '0',
  listPrice: '0',
  reorderLevel: '0',
  description: '',
}

const EMPTY_ADJUSTMENT: AdjustmentDraft = {
  productId: '',
  locationId: '',
  quantityDelta: '',
  note: '',
}

async function apiFetch<T>(url: string, init?: RequestInit) {
  const response = await fetch(url, init)
  const payload = (await response.json().catch(() => ({}))) as Partial<ApiEnvelope<T>>
  if (!response.ok) {
    throw new Error(payload.error?.message || response.statusText || 'Request failed')
  }
  return payload as ApiEnvelope<T>
}

export default function App() {
  const [health, setHealth] = useState<HealthData | null>(null)
  const [healthLoading, setHealthLoading] = useState(true)

  const [lookups, setLookups] = useState<LookupData>({ categories: [], suppliers: [], locations: [] })
  const [products, setProducts] = useState<Product[]>([])
  const [listMeta, setListMeta] = useState<ProductListMeta>({
    page: 1,
    pageSize: 10,
    total: 0,
    totalPages: 1,
    sortBy: 'Sku',
    sortDir: 'asc',
  })
  const [listLoading, setListLoading] = useState(false)
  const [apiError, setApiError] = useState<string | null>(null)

  const [searchInput, setSearchInput] = useState('')
  const [query, setQuery] = useState({
    q: '',
    categoryId: '',
    supplierId: '',
    sortBy: 'sku',
    sortDir: 'asc',
    page: 1,
  })

  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [selectedProduct, setSelectedProduct] = useState<ProductDetails | null>(null)
  const [detailsLoading, setDetailsLoading] = useState(false)

  const [productDraft, setProductDraft] = useState<ProductDraft>(EMPTY_PRODUCT)
  const [productSaving, setProductSaving] = useState(false)
  const [adjustmentDraft, setAdjustmentDraft] = useState<AdjustmentDraft>(EMPTY_ADJUSTMENT)
  const [adjustmentSaving, setAdjustmentSaving] = useState(false)
  const [actionMessage, setActionMessage] = useState<string | null>(null)

  const startIndex = useMemo(() => {
    if (listMeta.total === 0) return 0
    return (listMeta.page - 1) * listMeta.pageSize + 1
  }, [listMeta.page, listMeta.pageSize, listMeta.total])

  const endIndex = useMemo(
    () => Math.min(listMeta.total, listMeta.page * listMeta.pageSize),
    [listMeta.page, listMeta.pageSize, listMeta.total],
  )

  async function loadHealth() {
    setHealthLoading(true)
    try {
      const res = await apiFetch<HealthData>('/api/health')
      setHealth(res.data)
      setApiError(null)
    } catch (error) {
      setHealth({ ok: false })
      setApiError(error instanceof Error ? error.message : String(error))
    } finally {
      setHealthLoading(false)
    }
  }

  async function loadLookups() {
    const res = await apiFetch<LookupData>('/api/lookups')
    setLookups(res.data || { categories: [], suppliers: [], locations: [] })
  }

  async function loadProducts(nextQuery = query) {
    setListLoading(true)
    try {
      const params = new URLSearchParams({
        page: String(nextQuery.page),
        pageSize: '10',
        sortBy: nextQuery.sortBy,
        sortDir: nextQuery.sortDir,
      })
      if (nextQuery.q) params.set('q', nextQuery.q)
      if (nextQuery.categoryId) params.set('categoryId', nextQuery.categoryId)
      if (nextQuery.supplierId) params.set('supplierId', nextQuery.supplierId)
      const res = await apiFetch<Product[]>(`/api/products?${params.toString()}`)
      const meta = (res.meta || {}) as Partial<ProductListMeta>
      setProducts(res.data || [])
      setListMeta({
        page: Number(meta.page || nextQuery.page || 1),
        pageSize: Number(meta.pageSize || 10),
        total: Number(meta.total || 0),
        totalPages: Number(meta.totalPages || 1),
        sortBy: String(meta.sortBy || 'Sku'),
        sortDir: String(meta.sortDir || 'asc') as 'asc' | 'desc',
      })
      setApiError(null)
    } catch (error) {
      setApiError(error instanceof Error ? error.message : String(error))
    } finally {
      setListLoading(false)
    }
  }

  async function loadProductDetails(productId: number) {
    setSelectedId(productId)
    setDetailsLoading(true)
    try {
      const res = await apiFetch<ProductDetails>(`/api/products/${productId}`)
      setSelectedProduct(res.data)
      setApiError(null)
    } catch (error) {
      setSelectedProduct(null)
      setApiError(error instanceof Error ? error.message : String(error))
    } finally {
      setDetailsLoading(false)
    }
  }

  useEffect(() => {
    void loadHealth()
    void loadLookups()
    void loadProducts()
  }, [])

  const submitFilters = () => {
    const next = {
      ...query,
      q: searchInput.trim(),
      page: 1,
    }
    setQuery(next)
    void loadProducts(next)
  }

  const resetFilters = () => {
    const next = {
      q: '',
      categoryId: '',
      supplierId: '',
      sortBy: 'sku',
      sortDir: 'asc',
      page: 1,
    }
    setSearchInput('')
    setQuery(next)
    void loadProducts(next)
  }

  const setSort = (sortBy: string) => {
    const nextDir =
      query.sortBy === sortBy && query.sortDir === 'asc'
        ? 'desc'
        : 'asc'
    const next = { ...query, sortBy, sortDir: nextDir, page: 1 }
    setQuery(next)
    void loadProducts(next)
  }

  const goToPage = (page: number) => {
    const safe = Math.max(1, Math.min(listMeta.totalPages, page))
    const next = { ...query, page: safe }
    setQuery(next)
    void loadProducts(next)
  }

  async function submitProduct(event: React.FormEvent) {
    event.preventDefault()
    setProductSaving(true)
    setActionMessage(null)
    try {
      await apiFetch<{ productId: number }>('/api/products', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          sku: productDraft.sku,
          name: productDraft.name,
          categoryId: Number(productDraft.categoryId),
          supplierId: productDraft.supplierId ? Number(productDraft.supplierId) : null,
          unitOfMeasure: productDraft.unitOfMeasure,
          unitCost: Number(productDraft.unitCost || 0),
          listPrice: Number(productDraft.listPrice || 0),
          reorderLevel: Number(productDraft.reorderLevel || 0),
          description: productDraft.description,
        }),
      })
      setProductDraft(EMPTY_PRODUCT)
      setActionMessage('Product created successfully.')
      void loadProducts()
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : String(error))
    } finally {
      setProductSaving(false)
    }
  }

  async function submitAdjustment(event: React.FormEvent) {
    event.preventDefault()
    setAdjustmentSaving(true)
    setActionMessage(null)
    try {
      await apiFetch<{ movementId: number }>('/api/stock-adjustments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          productId: Number(adjustmentDraft.productId),
          locationId: Number(adjustmentDraft.locationId),
          quantityDelta: Number(adjustmentDraft.quantityDelta),
          note: adjustmentDraft.note,
        }),
      })
      setAdjustmentDraft(EMPTY_ADJUSTMENT)
      setActionMessage('Stock adjustment saved.')
      void loadProducts()
      if (selectedId) {
        void loadProductDetails(selectedId)
      }
    } catch (error) {
      setActionMessage(error instanceof Error ? error.message : String(error))
    } finally {
      setAdjustmentSaving(false)
    }
  }

  return (
    <div className="app">
      <header className="hero card">
        <p className="eyebrow">SQL Server + Express API</p>
        <h1>Inventory Dashboard</h1>
        <p className="muted">
          Feature-first MVP: browse, filter, inspect product details, add products, and post stock adjustments.
        </p>
      </header>

      <section className="card">
        <h2>Health / Status</h2>
        {healthLoading && <p className="muted">Checking API and database...</p>}
        {!healthLoading && health?.ok && (
          <ul className="health-list">
            <li>Connected to <strong>{health.database}</strong></li>
            <li>{health.serverVersion}</li>
          </ul>
        )}
        {!healthLoading && !health?.ok && <p className="error">API unavailable: {apiError || 'Unknown error'}</p>}
      </section>

      <section className="card">
        <div className="section-head">
          <h2>Products</h2>
          <button className="btn ghost" onClick={() => void loadProducts()} disabled={listLoading}>Refresh</button>
        </div>

        <div className="filters">
          <label>
            Search
            <input value={searchInput} onChange={(e) => setSearchInput(e.target.value)} placeholder="SKU or Name" />
          </label>
          <label>
            Category
            <select
              value={query.categoryId}
              onChange={(e) => setQuery((s) => ({ ...s, categoryId: e.target.value, page: 1 }))}
            >
              <option value="">All</option>
              {lookups.categories.map((c) => (
                <option key={c.CategoryId} value={c.CategoryId}>{c.Name}</option>
              ))}
            </select>
          </label>
          <label>
            Supplier
            <select
              value={query.supplierId}
              onChange={(e) => setQuery((s) => ({ ...s, supplierId: e.target.value, page: 1 }))}
            >
              <option value="">All</option>
              {lookups.suppliers.map((s) => (
                <option key={s.SupplierId} value={s.SupplierId}>{s.Name}</option>
              ))}
            </select>
          </label>
          <div className="filter-actions">
            <button className="btn" onClick={submitFilters} disabled={listLoading}>Apply</button>
            <button className="btn ghost" onClick={resetFilters} disabled={listLoading}>Reset</button>
          </div>
        </div>

        {apiError && <p className="error">{apiError}</p>}

        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th><button className="head-btn" onClick={() => setSort('sku')}>SKU</button></th>
                <th><button className="head-btn" onClick={() => setSort('name')}>Name</button></th>
                <th><button className="head-btn" onClick={() => setSort('category')}>Category</button></th>
                <th>UOM</th>
                <th><button className="head-btn" onClick={() => setSort('price')}>List Price</button></th>
                <th><button className="head-btn" onClick={() => setSort('supplier')}>Supplier</button></th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {listLoading && (
                <tr><td colSpan={7} className="muted">Loading products...</td></tr>
              )}
              {!listLoading && products.length === 0 && (
                <tr><td colSpan={7} className="muted">No products match your filters.</td></tr>
              )}
              {!listLoading && products.map((p) => (
                <tr key={p.ProductId}>
                  <td className="mono">{p.Sku}</td>
                  <td>{p.Name}</td>
                  <td>{p.CategoryName}</td>
                  <td>{p.UnitOfMeasure}</td>
                  <td>{Number(p.ListPrice).toFixed(2)}</td>
                  <td>{p.SupplierName || '—'}</td>
                  <td>
                    <button className="btn small" onClick={() => void loadProductDetails(p.ProductId)}>
                      Details
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="pagination">
          <span className="muted">Showing {startIndex}-{endIndex} of {listMeta.total}</span>
          <div className="pager-buttons">
            <button className="btn ghost small" onClick={() => goToPage(listMeta.page - 1)} disabled={listMeta.page <= 1 || listLoading}>Prev</button>
            <span>Page {listMeta.page} / {listMeta.totalPages}</span>
            <button className="btn ghost small" onClick={() => goToPage(listMeta.page + 1)} disabled={listMeta.page >= listMeta.totalPages || listLoading}>Next</button>
          </div>
        </div>
      </section>

      <section className="grid-2">
        <article className="card">
          <h2>Inventory actions</h2>
          {actionMessage && <p className={actionMessage.includes('success') || actionMessage.includes('saved') ? 'success' : 'error'}>{actionMessage}</p>}

          <h3>Add product</h3>
          <form className="form" onSubmit={submitProduct}>
            <label>SKU<input required value={productDraft.sku} onChange={(e) => setProductDraft((s) => ({ ...s, sku: e.target.value }))} /></label>
            <label>Name<input required value={productDraft.name} onChange={(e) => setProductDraft((s) => ({ ...s, name: e.target.value }))} /></label>
            <label>Category
              <select required value={productDraft.categoryId} onChange={(e) => setProductDraft((s) => ({ ...s, categoryId: e.target.value }))}>
                <option value="">Select category</option>
                {lookups.categories.map((c) => <option key={c.CategoryId} value={c.CategoryId}>{c.Name}</option>)}
              </select>
            </label>
            <label>Supplier
              <select value={productDraft.supplierId} onChange={(e) => setProductDraft((s) => ({ ...s, supplierId: e.target.value }))}>
                <option value="">None</option>
                {lookups.suppliers.map((s) => <option key={s.SupplierId} value={s.SupplierId}>{s.Name}</option>)}
              </select>
            </label>
            <label>UOM<input value={productDraft.unitOfMeasure} onChange={(e) => setProductDraft((s) => ({ ...s, unitOfMeasure: e.target.value }))} /></label>
            <label>Unit cost<input type="number" step="0.0001" min="0" value={productDraft.unitCost} onChange={(e) => setProductDraft((s) => ({ ...s, unitCost: e.target.value }))} /></label>
            <label>List price<input type="number" step="0.0001" min="0" value={productDraft.listPrice} onChange={(e) => setProductDraft((s) => ({ ...s, listPrice: e.target.value }))} /></label>
            <label>Reorder level<input type="number" min="0" value={productDraft.reorderLevel} onChange={(e) => setProductDraft((s) => ({ ...s, reorderLevel: e.target.value }))} /></label>
            <label>Description<textarea rows={2} value={productDraft.description} onChange={(e) => setProductDraft((s) => ({ ...s, description: e.target.value }))} /></label>
            <button className="btn" disabled={productSaving}>{productSaving ? 'Saving...' : 'Create product'}</button>
          </form>

          <h3>Stock adjustment</h3>
          <form className="form" onSubmit={submitAdjustment}>
            <label>Product
              <select required value={adjustmentDraft.productId} onChange={(e) => setAdjustmentDraft((s) => ({ ...s, productId: e.target.value }))}>
                <option value="">Select product</option>
                {products.map((p) => <option key={p.ProductId} value={p.ProductId}>{p.Sku} - {p.Name}</option>)}
              </select>
            </label>
            <label>Location
              <select required value={adjustmentDraft.locationId} onChange={(e) => setAdjustmentDraft((s) => ({ ...s, locationId: e.target.value }))}>
                <option value="">Select location</option>
                {lookups.locations.map((l) => <option key={l.LocationId} value={l.LocationId}>{l.Code} - {l.Name}</option>)}
              </select>
            </label>
            <label>Quantity delta
              <input
                required
                type="number"
                value={adjustmentDraft.quantityDelta}
                onChange={(e) => setAdjustmentDraft((s) => ({ ...s, quantityDelta: e.target.value }))}
                placeholder="Positive or negative"
              />
            </label>
            <label>Note<textarea rows={2} value={adjustmentDraft.note} onChange={(e) => setAdjustmentDraft((s) => ({ ...s, note: e.target.value }))} /></label>
            <button className="btn" disabled={adjustmentSaving}>{adjustmentSaving ? 'Saving...' : 'Post adjustment'}</button>
          </form>
        </article>

        <article className="card">
          <h2>Product details</h2>
          {!selectedId && <p className="muted">Choose a product from the table to inspect stock by location.</p>}
          {detailsLoading && <p className="muted">Loading details...</p>}
          {selectedId && !detailsLoading && !selectedProduct && <p className="error">Product details unavailable.</p>}
          {selectedProduct && (
            <>
              <h3>{selectedProduct.Name}</h3>
              <p className="muted">{selectedProduct.Sku} • {selectedProduct.CategoryName}</p>
              <p className="muted">{selectedProduct.Description || 'No description provided.'}</p>
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th>Location</th>
                      <th>Type</th>
                      <th>On hand</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedProduct.stockByLocation.map((row) => (
                      <tr key={row.LocationId}>
                        <td>{row.Code} - {row.Name}</td>
                        <td>{row.LocationType}</td>
                        <td>{row.QuantityOnHand}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </article>
      </section>
    </div>
  )
}

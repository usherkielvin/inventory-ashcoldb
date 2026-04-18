import { useEffect, useState } from 'react'

type Health = { ok: boolean; database?: string; serverVersion?: string; error?: string }

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

export default function App() {
  const [health, setHealth] = useState<Health | null>(null)
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    async function load() {
      setLoading(true)
      setError(null)
      try {
        const hRes = await fetch('/api/health')
        const hJson = (await hRes.json()) as Health
        if (cancelled) return
        setHealth(hJson)

        if (!hJson.ok) {
          setError(hJson.error || 'Database connection failed')
          setProducts([])
          return
        }

        const pRes = await fetch('/api/products')
        if (!pRes.ok) {
          const err = await pRes.json().catch(() => ({}))
          throw new Error((err as { error?: string }).error || pRes.statusText)
        }
        const pJson = (await pRes.json()) as { data: Product[] }
        if (cancelled) return
        setProducts(pJson.data || [])
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e))
          setProducts([])
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div>
      <header style={{ marginBottom: '1.5rem' }}>
        <p style={{ margin: 0, fontSize: '0.75rem', letterSpacing: '0.08em', color: '#10b981', fontWeight: 700 }}>
          SQL SERVER + EXPRESS API
        </p>
        <h1 style={{ margin: '0.35rem 0 0', fontSize: '1.5rem', fontWeight: 800 }}>Active product catalog</h1>
        <p style={{ margin: '0.5rem 0 0', color: '#94a3b8', fontSize: '0.9rem' }}>
          Data from <code style={{ color: '#7dd3fc' }}>dbo.vw_ActiveProductCatalog</code> in{' '}
          <code style={{ color: '#7dd3fc' }}>AshcolInventory</code>. Start the API on port 3001 and run{' '}
          <code style={{ color: '#7dd3fc' }}>npm run dev</code> here (Vite proxies <code>/api</code>).
        </p>
      </header>

      <section
        style={{
          background: '#111a2e',
          border: '1px solid #243049',
          borderRadius: '12px',
          padding: '1rem 1.1rem',
          marginBottom: '1.25rem',
        }}
      >
        <h2 style={{ margin: '0 0 0.5rem', fontSize: '0.85rem', color: '#94a3b8' }}>API / database health</h2>
        {loading && <p style={{ margin: 0, color: '#94a3b8' }}>Checking…</p>}
        {!loading && health?.ok && (
          <ul style={{ margin: 0, paddingLeft: '1.1rem', color: '#cbd5e1', fontSize: '0.9rem' }}>
            <li>
              Connected to <strong>{health.database}</strong>
            </li>
            {health.serverVersion && <li style={{ marginTop: '0.25rem' }}>{health.serverVersion}</li>}
          </ul>
        )}
        {!loading && !health?.ok && (
          <p style={{ margin: 0, color: '#f87171' }}>{health?.error || error || 'API unreachable'}</p>
        )}
      </section>

      {error && health?.ok === true && (
        <p style={{ color: '#f87171', marginBottom: '1rem' }}>{error}</p>
      )}

      {!loading && health?.ok && (
        <div style={{ overflowX: 'auto', border: '1px solid #243049', borderRadius: '12px' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.85rem' }}>
            <thead>
              <tr style={{ background: '#162036', textAlign: 'left' }}>
                <th style={{ padding: '0.65rem 0.75rem' }}>SKU</th>
                <th style={{ padding: '0.65rem 0.75rem' }}>Name</th>
                <th style={{ padding: '0.65rem 0.75rem' }}>Category</th>
                <th style={{ padding: '0.65rem 0.75rem' }}>UOM</th>
                <th style={{ padding: '0.65rem 0.75rem' }}>List price</th>
                <th style={{ padding: '0.65rem 0.75rem' }}>Supplier</th>
              </tr>
            </thead>
            <tbody>
              {products.length === 0 && (
                <tr>
                  <td colSpan={6} style={{ padding: '1rem 0.75rem', color: '#94a3b8' }}>
                    No rows (run seeds in SSMS or check view).
                  </td>
                </tr>
              )}
              {products.map((p) => (
                <tr key={p.ProductId} style={{ borderTop: '1px solid #243049' }}>
                  <td style={{ padding: '0.55rem 0.75rem', fontFamily: 'ui-monospace, monospace' }}>{p.Sku}</td>
                  <td style={{ padding: '0.55rem 0.75rem' }}>{p.Name}</td>
                  <td style={{ padding: '0.55rem 0.75rem', color: '#cbd5e1' }}>{p.CategoryName}</td>
                  <td style={{ padding: '0.55rem 0.75rem' }}>{p.UnitOfMeasure}</td>
                  <td style={{ padding: '0.55rem 0.75rem' }}>{Number(p.ListPrice).toFixed(2)}</td>
                  <td style={{ padding: '0.55rem 0.75rem', color: '#94a3b8' }}>{p.SupplierName ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

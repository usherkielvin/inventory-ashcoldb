/**
 * API contract smoke tests.
 * Requires API running (e.g. from web/: npm run dev)
 */
const baseUrl = process.env.API_BASE_URL || 'http://localhost:3001'

function assert(condition, message) {
  if (!condition) throw new Error(message)
}

async function request(path, init) {
  const res = await fetch(`${baseUrl}${path}`, init)
  const json = await res.json().catch(() => ({}))
  return { status: res.status, ok: res.ok, body: json }
}

function assertEnvelope(body, label) {
  assert(body && typeof body === 'object', `${label}: body should be an object`)
  assert('data' in body, `${label}: missing data`)
  assert('error' in body, `${label}: missing error`)
  assert('meta' in body, `${label}: missing meta`)
}

async function run() {
  console.log(`Testing API contracts at ${baseUrl}`)

  const health = await request('/api/health')
  assert(health.ok, `/api/health returned ${health.status}`)
  assertEnvelope(health.body, 'health')
  assert(health.body.data?.ok === true, 'health.data.ok should be true')
  console.log('OK /api/health')

  const lookups = await request('/api/lookups')
  assert(lookups.ok, `/api/lookups returned ${lookups.status}`)
  assertEnvelope(lookups.body, 'lookups')
  assert(Array.isArray(lookups.body.data?.categories), 'lookups.categories should be array')
  assert(Array.isArray(lookups.body.data?.suppliers), 'lookups.suppliers should be array')
  assert(Array.isArray(lookups.body.data?.locations), 'lookups.locations should be array')
  console.log('OK /api/lookups')

  const products = await request('/api/products?page=1&pageSize=5&sortBy=sku&sortDir=asc')
  assert(products.ok, `/api/products returned ${products.status}`)
  assertEnvelope(products.body, 'products')
  assert(Array.isArray(products.body.data), 'products.data should be array')
  assert(typeof products.body.meta?.page === 'number', 'products.meta.page should be number')
  console.log('OK /api/products')

  if (products.body.data.length > 0) {
    const firstId = products.body.data[0].ProductId
    const details = await request(`/api/products/${firstId}`)
    assert(details.ok, `/api/products/${firstId} returned ${details.status}`)
    assertEnvelope(details.body, 'product details')
    assert(Array.isArray(details.body.data?.stockByLocation), 'stockByLocation should be array')
    console.log('OK /api/products/:productId')
  } else {
    console.log('SKIP /api/products/:productId (no products found)')
  }

  const invalidCreate = await request('/api/products', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  })
  assert(invalidCreate.status === 400, 'invalid create product should return 400')
  assertEnvelope(invalidCreate.body, 'invalid create product')
  console.log('OK POST /api/products validation')

  const invalidAdjustment = await request('/api/stock-adjustments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ productId: 1, locationId: 1, quantityDelta: 0 }),
  })
  assert(invalidAdjustment.status === 400, 'invalid stock adjustment should return 400')
  assertEnvelope(invalidAdjustment.body, 'invalid stock adjustment')
  console.log('OK POST /api/stock-adjustments validation')

  console.log('All API contract checks passed.')
}

run().catch((error) => {
  console.error('FAILED:', error.message || error)
  process.exit(1)
})

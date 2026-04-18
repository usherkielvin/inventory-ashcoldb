/** Shared mssql config for Express and `npm run test:sql`. Load `dotenv` before calling `buildSqlConfig()`. */

import { buildConnectionString } from '@tediousjs/connection-string'

/** Split `host\instance` or use SQL_INSTANCE for named instances. */
export function parseHostAndInstance(serverEnv, instanceEnv) {
  const inst = String(instanceEnv || '').trim()
  if (inst) {
    const host = String(serverEnv || 'localhost').trim().replace(/^\.\\/, 'localhost\\')
    const h = host.includes('\\') ? host.split('\\')[0] : host
    return { host: h === '.' ? 'localhost' : h, instanceName: inst }
  }
  const s = String(serverEnv || 'localhost').trim()
  const idx = s.indexOf('\\')
  if (idx > 0) {
    const host = s.slice(0, idx)
    return {
      host: host === '.' ? 'localhost' : host,
      instanceName: s.slice(idx + 1),
    }
  }
  return { host: s === '.' ? 'localhost' : s, instanceName: undefined }
}

function odbcDriverName() {
  return (
    String(process.env.SQL_ODBC_DRIVER || '').trim() ||
    'ODBC Driver 18 for SQL Server'
  )
}

/**
 * `mssql/msnodesqlv8` defaults to "SQL Server Native Client 11.0", which is often not installed.
 * Build an explicit ODBC connection string (Driver 17/18) instead.
 */
function buildMsv8OdbcConnectionString({
  serverSpec,
  database,
  useWindows,
  user,
  password,
  encrypt,
  trustServerCertificate,
}) {
  const base = {
    Driver: odbcDriverName(),
    Server: serverSpec,
    Database: database,
    Encrypt: encrypt ? 'yes' : 'no',
    TrustServerCertificate: trustServerCertificate ? 'yes' : 'no',
  }
  if (useWindows) {
    return buildConnectionString({
      ...base,
      Trusted_Connection: 'yes',
    })
  }
  return buildConnectionString({
    ...base,
    Uid: user,
    Pwd: password ?? '',
  })
}

/**
 * Build mssql pool config from process.env.
 * - **SQL_SERVER_FULL** (optional): same value as SSMS “Server name”, e.g. `localhost\SQLEXPRESS01`.
 *   Ignores SQL_SERVER / SQL_INSTANCE / SQL_PORT. Named instances need **SQL Server Browser** unless you use TCP + SQL_PORT.
 * - Windows: SQL_USE_WINDOWS_AUTH=true, optional SQL_SERVER + SQL_INSTANCE or host\instance.
 * - TCP: set SQL_PORT to IPAll port (Configuration Manager). Prefer 127.0.0.1 + port to avoid IPv6 issues.
 * - SQL login: SQL_USE_WINDOWS_AUTH=false + SQL_USER + SQL_PASSWORD.
 */
export function buildSqlConfig() {
  const useWindows = ['true', '1', 'yes'].includes(
    String(process.env.SQL_USE_WINDOWS_AUTH || '').toLowerCase(),
  )

  let fullServer = String(process.env.SQL_SERVER_FULL || '').trim()
  // .env often ends up with `localhost\\instance` (two chars); SQL expects one backslash.
  if (fullServer) {
    fullServer = fullServer.replace(/\\{2,}/g, '\\')
  }
  if (fullServer) {
    const encrypt = process.env.SQL_ENCRYPT !== 'false'
    const trustServerCertificate =
      process.env.SQL_TRUST_SERVER_CERTIFICATE === 'true'
    const options = {
      encrypt,
      trustServerCertificate,
      enableArithAbort: true,
    }
    if (useWindows) {
      options.trustedConnection = true
    }
    const connectionTimeout = Number(
      process.env.SQL_CONNECTION_TIMEOUT_MS || 60000,
    )
    const database = process.env.SQL_DATABASE || 'AshcolInventory'
    const config = {
      server: fullServer,
      database,
      connectionTimeout,
      requestTimeout: connectionTimeout,
      options,
      driver: 'msnodesqlv8',
      connectionString: buildMsv8OdbcConnectionString({
        serverSpec: fullServer,
        database,
        useWindows,
        user: process.env.SQL_USER,
        password: process.env.SQL_PASSWORD,
        encrypt,
        trustServerCertificate,
      }),
    }
    if (!useWindows) {
      config.user = process.env.SQL_USER
      config.password = process.env.SQL_PASSWORD ?? ''
      if (!config.user) {
        throw new Error(
          'Set SQL_USER and SQL_PASSWORD in web/server/.env, or set SQL_USE_WINDOWS_AUTH=true for Windows Authentication',
        )
      }
    }
    return config
  }

  const portRaw = process.env.SQL_PORT
  const port =
    portRaw !== undefined && String(portRaw).trim() !== ''
      ? Number(portRaw)
      : undefined

  const { host, instanceName } = parseHostAndInstance(
    process.env.SQL_SERVER,
    process.env.SQL_INSTANCE,
  )

  const encrypt = process.env.SQL_ENCRYPT !== 'false'
  const trustServerCertificate =
    process.env.SQL_TRUST_SERVER_CERTIFICATE === 'true'

  const options = {
    encrypt,
    trustServerCertificate,
    enableArithAbort: true,
  }

  if (useWindows) {
    options.trustedConnection = true
  }

  if (instanceName && (!port || Number.isNaN(port) || port <= 0)) {
    options.instanceName = instanceName
  }

  const connectionTimeout = Number(process.env.SQL_CONNECTION_TIMEOUT_MS || 60000)

  let serverHost = host
  // Tedious (SQL auth path) can hit IPv6 `::1` issues for `localhost`; keep `localhost` for Windows/ODBC (SSPI).
  if (
    !useWindows &&
    port &&
    !Number.isNaN(port) &&
    port > 0 &&
    /^localhost$/i.test(serverHost) &&
    process.env.SQL_PREFER_IPV6 !== 'true'
  ) {
    serverHost = '127.0.0.1'
  }

  const database = process.env.SQL_DATABASE || 'AshcolInventory'

  const config = {
    server: serverHost,
    database,
    connectionTimeout,
    requestTimeout: connectionTimeout,
    options,
  }

  if (port !== undefined && !Number.isNaN(port) && port > 0) {
    config.port = port
    delete config.options.instanceName
  }

  config.driver = 'msnodesqlv8'

  const hasTcpPort = port !== undefined && !Number.isNaN(port) && port > 0
  const serverSpec = hasTcpPort
    ? `${serverHost},${port}`
    : config.options.instanceName
      ? `${serverHost}\\${config.options.instanceName}`
      : serverHost

  config.connectionString = buildMsv8OdbcConnectionString({
    serverSpec,
    database,
    useWindows,
    user: process.env.SQL_USER,
    password: process.env.SQL_PASSWORD,
    encrypt,
    trustServerCertificate,
  })

  if (!useWindows) {
    config.user = process.env.SQL_USER
    config.password = process.env.SQL_PASSWORD ?? ''
    if (!config.user) {
      throw new Error(
        'Set SQL_USER and SQL_PASSWORD in web/server/.env, or set SQL_USE_WINDOWS_AUTH=true for Windows Authentication',
      )
    }
  }

  return config
}

import { createRequire } from 'module'

const require = createRequire(import.meta.url)

function useWindowsAuthFromEnv() {
  return ['true', '1', 'yes'].includes(
    String(process.env.SQL_USE_WINDOWS_AUTH || '').toLowerCase(),
  )
}

/** Tedious (default `mssql`) cannot do Windows/Trusted auth; use MSNodeSQLv8 in that case. */
export function getMssql() {
  if (useWindowsAuthFromEnv()) {
    return require('mssql/msnodesqlv8')
  }
  return require('mssql')
}

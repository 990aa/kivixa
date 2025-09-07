// core/db/index.ts

import { IDatabaseAdapter } from './repository';
import { BetterSqlite3Adapter } from './adapters/better-sqlite3';
import { Sqlite3Adapter } from './adapters/sqlite3';

export * from './types';
export * from './repository';

// Environment detection (simplified)
// In a real app, you might check for process.versions.electron or other environment-specific variables.
const isElectron = true; // Placeholder for environment detection

export function createDbAdapter(dbPath: string): IDatabaseAdapter {
  if (isElectron) {
    return new BetterSqlite3Adapter(dbPath);
  } else {
    return new Sqlite3Adapter(dbPath);
  }
}

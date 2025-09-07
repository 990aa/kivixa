// apps/web/lib/db.ts

import { createDbAdapter, IDatabaseAdapter } from '../../../core/db';
import path from 'path';

let dbInstance: IDatabaseAdapter | null = null;

export function getDb(): IDatabaseAdapter {
  if (!dbInstance) {
    // Determine the database path.
    // In a real Electron setup, the main process would set this env var.
    // For web-only dev, it falls back to a local file.
    const dbPath = process.env.KIVIXA_DB_PATH || path.join(process.cwd(), 'dev.sqlite');
    console.log(`Connecting to database at: ${dbPath}`);
    dbInstance = createDbAdapter(dbPath);
  }
  return dbInstance;
}

// Bootstrap script for kivixa.db (Node.js + TypeScript)
// Usage: npx ts-node data/bootstrap.ts
import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';

const DB_PATH = path.resolve(__dirname, '../kivixa.db');
const SCHEMA_PATH = path.resolve(__dirname, 'schema.sql');

function openOrCreateDb() {
  const db = new Database(DB_PATH);
  // Set high-performance pragmas
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  db.pragma('synchronous = NORMAL');
  // Cache size: -16000 = 16MB (negative = KB units, in-memory)
  db.pragma('cache_size = -16000');
  return db;
}

function runSchema(db: Database.Database) {
  const schema = fs.readFileSync(SCHEMA_PATH, 'utf8');
  db.exec(schema);
}

function main() {
  const db = openOrCreateDb();
  runSchema(db);
  db.close();
  console.log('kivixa.db is ready. Schema and indices applied.');
}

if (require.main === module) {
  main();
}

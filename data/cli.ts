// Simple CLI for kivixa.db schema/migrations (Node.js + TypeScript)
// Usage: npx ts-node data/cli.ts [init|migrate]
import Database from 'better-sqlite3';
import * as fs from 'fs';
import * as path from 'path';

const DB_PATH = path.resolve(__dirname, '../kivixa.db');
const SCHEMA_PATH = path.resolve(__dirname, 'schema.sql');

function openOrCreateDb() {
  const db = new Database(DB_PATH);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  db.pragma('synchronous = NORMAL');
  db.pragma('cache_size = -16000');
  return db;
}

function runSchema(db: Database.Database) {
  const schema = fs.readFileSync(SCHEMA_PATH, 'utf8');
  db.exec(schema);
}

function migrate(db: Database.Database) {
  // For now, just run schema (idempotent).
  runSchema(db);
}

function main() {
  const cmd = process.argv[2] || 'init';
  const db = openOrCreateDb();
  if (cmd === 'init') {
    runSchema(db);
    console.log('Database initialized.');
  } else if (cmd === 'migrate') {
    migrate(db);
    console.log('Migrations applied.');
  } else {
    console.log('Usage: npx ts-node data/cli.ts [init|migrate]');
  }
  db.close();
}

if (require.main === module) {
  main();
}

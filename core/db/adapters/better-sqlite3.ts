// core/db/adapters/better-sqlite3.ts

import Database from 'better-sqlite3';
import { IDatabaseAdapter, IRepository, IDocumentRepository, IPageRepository, ILayerRepository, IStrokeRepository, IPageThumbnailRepository, IOutlineRepository, ICommentRepository, ILinkRepository, ITemplateRepository, IFavoriteRepository, IUserSettingsRepository, IAssetRepository } from '../repository';
import * as T from '../types';

class GenericRepository<T> implements IRepository<T> {
    constructor(protected db: Database.Database, protected table: string) {}

    async create(item: Omit<T, 'id' | 'created_at' | 'updated_at'>): Promise<T> {
        const columns = Object.keys(item).join(', ');
        const placeholders = Object.keys(item).map(() => '?').join(', ');
        const values = Object.values(item);

        const stmt = this.db.prepare(`INSERT INTO ${this.table} (${columns}) VALUES (${placeholders}) RETURNING *`);
        return stmt.get(...values) as T;
    }

    async read(id: number): Promise<T | null> {
        const stmt = this.db.prepare(`SELECT * FROM ${this.table} WHERE id = ?`);
        return (stmt.get(id) as T) || null;
    }

    async update(id: number, item: Partial<Omit<T, 'id' | 'created_at' | 'updated_at'>>): Promise<T> {
        const columns = Object.keys(item).map(key => `${key} = ?`).join(', ');
        const values = Object.values(item);

        const stmt = this.db.prepare(`UPDATE ${this.table} SET ${columns}, updated_at = CURRENT_TIMESTAMP WHERE id = ? RETURNING *`);
        return stmt.get(...values, id) as T;
    }

    async delete(id: number): Promise<boolean> {
        const stmt = this.db.prepare(`DELETE FROM ${this.table} WHERE id = ?`);
        const result = stmt.run(id);
        return result.changes > 0;
    }

    async find(criteria: Partial<T>): Promise<T[]> {
        const whereClauses = Object.keys(criteria).map(key => `${key} = ?`).join(' AND ');
        const values = Object.values(criteria);
        const query = `SELECT * FROM ${this.table}${whereClauses ? ` WHERE ${whereClauses}` : ''}`;
        const stmt = this.db.prepare(query);
        return stmt.all(...values) as T[];
    }
}

class DocumentRepository extends GenericRepository<T.Document> implements IDocumentRepository {
    constructor(db: Database.Database) {
        super(db, 'documents');
    }

    async createMany(items: Omit<T.Document, 'id' | 'created_at' | 'updated_at'>[]): Promise<T.Document[]> {
        const insert = this.db.transaction((docs) => {
            const stmt = this.db.prepare(`INSERT INTO ${this.table} (notebook_id, title) VALUES (?, ?)`);
            const results = [];
            for (const doc of docs) {
                results.push(stmt.run(doc.notebook_id, doc.title));
            }
            return results;
        });
        // This is a simplified return, RETURNING * is not standard in batch inserts for better-sqlite3
        // A more complex implementation would be needed to return the created items.
        insert(items);
        return []; // Placeholder
    }
}

class AssetRepository extends GenericRepository<T.Asset> implements IAssetRepository {
    constructor(db: Database.Database) {
        super(db, 'assets');
    }

    async findByHash(hash: string): Promise<T.Asset | null> {
        const stmt = this.db.prepare(`SELECT * FROM ${this.table} WHERE hash = ?`);
        return (stmt.get(hash) as T.Asset) || null;
    }
}


export class BetterSqlite3Adapter implements IDatabaseAdapter {
    private db: Database.Database;

    documents: IDocumentRepository;
    pages: IPageRepository;
    layers: ILayerRepository;
    strokes: IStrokeRepository;
    pageThumbnails: IPageThumbnailRepository;
    outlines: IOutlineRepository;
    comments: ICommentRepository;
    links: ILinkRepository;
    templates: ITemplateRepository;
    favorites: IFavoriteRepository;
    userSettings: IUserSettingsRepository;
    assets: IAssetRepository;

    constructor(dbPath: string) {
        this.db = new Database(dbPath);
        this.db.pragma('journal_mode = WAL');
        this.db.pragma('foreign_keys = ON');

        this.documents = new DocumentRepository(this.db);
        this.pages = new GenericRepository<T.Page>(this.db, 'pages') as IPageRepository; // Simplified
        this.layers = new GenericRepository<T.Layer>(this.db, 'layers') as ILayerRepository; // Simplified
        this.strokes = new GenericRepository<T.Stroke>(this.db, 'strokes') as IStrokeRepository; // Simplified
        this.pageThumbnails = new GenericRepository<T.PageThumbnail>(this.db, 'page_thumbnails') as IPageThumbnailRepository; // Simplified
        this.outlines = new GenericRepository<T.Outline>(this.db, 'outlines') as IOutlineRepository; // Simplified
        this.comments = new GenericRepository<T.Comment>(this.db, 'comments') as ICommentRepository; // Simplified
        this.links = new GenericRepository<T.Link>(this.db, 'links') as ILinkRepository; // Simplified
        this.templates = new GenericRepository<T.Template>(this.db, 'templates') as ITemplateRepository; // Simplified
        this.favorites = new GenericRepository<T.Favorite>(this.db, 'favorites') as IFavoriteRepository; // Simplified
        this.userSettings = new GenericRepository<T.UserSettings>(this.db, 'user_settings') as IUserSettingsRepository;
        this.assets = new AssetRepository(this.db);
    }

    async transaction<T>(fn: () => Promise<T>): Promise<T> {
        // better-sqlite3 transactions are synchronous
        const transaction = this.db.transaction(fn);
        return transaction();
    }

    async close(): Promise<void> {
        this.db.close();
    }
}

// core/db/adapters/sqlite3.ts

import { verbose } from 'sqlite3';
import { IDatabaseAdapter, IRepository, IDocumentRepository, IPageRepository, ILayerRepository, IStrokeRepository, IPageThumbnailRepository, IOutlineRepository, ICommentRepository, ILinkRepository, ITemplateRepository, IFavoriteRepository, IUserSettingsRepository, IAssetRepository } from '../repository';
import * as T from '../types';

const sqlite3 = verbose();

class GenericRepository<T> implements IRepository<T> {
    constructor(protected db: sqlite3.Database, protected table: string) {}

    create(item: Omit<T, 'id' | 'created_at' | 'updated_at'>): Promise<T> {
        return new Promise((resolve, reject) => {
            const columns = Object.keys(item).join(', ');
            const placeholders = Object.keys(item).map(() => '?').join(', ');
            const values = Object.values(item);

            const sql = `INSERT INTO ${this.table} (${columns}) VALUES (${placeholders}) RETURNING *`;

            this.db.get(sql, values, (err, row: T) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            });
        });
    }

    read(id: number): Promise<T | null> {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM ${this.table} WHERE id = ?`;
            this.db.get(sql, [id], (err, row: T) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row || null);
                }
            });
        });
    }

    update(id: number, item: Partial<Omit<T, 'id' | 'created_at' | 'updated_at'>>): Promise<T> {
        return new Promise((resolve, reject) => {
            const columns = Object.keys(item).map(key => `${key} = ?`).join(', ');
            const values = Object.values(item);
            const sql = `UPDATE ${this.table} SET ${columns}, updated_at = CURRENT_TIMESTAMP WHERE id = ? RETURNING *`;

            this.db.get(sql, [...values, id], (err, row: T) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row);
                }
            });
        });
    }

    delete(id: number): Promise<boolean> {
        return new Promise((resolve, reject) => {
            const sql = `DELETE FROM ${this.table} WHERE id = ?`;
            this.db.run(sql, [id], function(err) {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.changes > 0);
                }
            });
        });
    }

    find(criteria: Partial<T>): Promise<T[]> {
        return new Promise((resolve, reject) => {
            const whereClauses = Object.keys(criteria).map(key => `${key} = ?`).join(' AND ');
            const values = Object.values(criteria);
            const sql = `SELECT * FROM ${this.table}${whereClauses ? ` WHERE ${whereClauses}` : ''}`;

            this.db.all(sql, values, (err, rows: T[]) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(rows);
                }
            });
        });
    }
}

class AssetRepository extends GenericRepository<T.Asset> implements IAssetRepository {
    constructor(db: sqlite3.Database) {
        super(db, 'assets');
    }

    findByHash(hash: string): Promise<T.Asset | null> {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM ${this.table} WHERE hash = ?`;
            this.db.get(sql, [hash], (err, row: T.Asset) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(row || null);
                }
            });
        });
    }
}


export class Sqlite3Adapter implements IDatabaseAdapter {
    private db: sqlite3.Database;

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
        this.db = new sqlite3.Database(dbPath);
        this.db.run('PRAGMA foreign_keys = ON');

        this.documents = new GenericRepository<T.Document>(this.db, 'documents') as IDocumentRepository;
        this.pages = new GenericRepository<T.Page>(this.db, 'pages') as IPageRepository;
        this.layers = new GenericRepository<T.Layer>(this.db, 'layers') as ILayerRepository;
        this.strokes = new GenericRepository<T.Stroke>(this.db, 'strokes') as IStrokeRepository;
        this.pageThumbnails = new GenericRepository<T.PageThumbnail>(this.db, 'page_thumbnails') as IPageThumbnailRepository;
        this.outlines = new GenericRepository<T.Outline>(this.db, 'outlines') as IOutlineRepository;
        this.comments = new GenericRepository<T.Comment>(this.db, 'comments') as ICommentRepository;
        this.links = new GenericRepository<T.Link>(this.db, 'links') as ILinkRepository;
        this.templates = new GenericRepository<T.Template>(this.db, 'templates') as ITemplateRepository;
        this.favorites = new GenericRepository<T.Favorite>(this.db, 'favorites') as IFavoriteRepository;
        this.userSettings = new GenericRepository<T.UserSettings>(this.db, 'user_settings') as IUserSettingsRepository;
        this.assets = new AssetRepository(this.db);
    }

    transaction<T>(fn: () => Promise<T>): Promise<T> {
        return new Promise((resolve, reject) => {
            this.db.serialize(() => {
                this.db.run('BEGIN TRANSACTION');
                fn().then(result => {
                    this.db.run('COMMIT');
                    resolve(result);
                }).catch(err => {
                    this.db.run('ROLLBACK');
                    reject(err);
                });
            });
        });
    }

    close(): Promise<void> {
        return new Promise((resolve, reject) => {
            this.db.close(err => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }
}

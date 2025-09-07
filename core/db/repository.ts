// core/db/repository.ts

import {
  Document,
  Page,
  Layer,
  Stroke,
  PageThumbnail,
  Outline,
  Comment,
  Link,
  Template,
  Favorite,
  UserSettings,
  Asset,
} from './types';

export interface IRepository<T> {
  create(item: Omit<T, 'id' | 'created_at' | 'updated_at'>): Promise<T>;
  read(id: number): Promise<T | null>;
  update(id: number, item: Partial<Omit<T, 'id' | 'created_at' | 'updated_at'>>): Promise<T>;
  delete(id: number): Promise<boolean>;
  find(criteria: Partial<T>): Promise<T[]>;
}

export interface IDocumentRepository extends IRepository<Document> {
  createMany(items: Omit<Document, 'id' | 'created_at' | 'updated_at'>[]): Promise<Document[]>;
}

export interface IPageRepository extends IRepository<Page> {
    createMany(items: Omit<Page, 'id' | 'created_at' | 'updated_at'>[]): Promise<Page[]>;
}

export interface ILayerRepository extends IRepository<Layer> {
    createMany(items: Omit<Layer, 'id' | 'created_at' | 'updated_at'>[]): Promise<Layer[]>;
}

export interface IStrokeRepository extends IRepository<Stroke> {
    createMany(items: Omit<Stroke, 'id' | 'created_at' | 'updated_at'>[]): Promise<Stroke[]>;
}

export interface IPageThumbnailRepository extends IRepository<PageThumbnail> {
    createMany(items: Omit<PageThumbnail, 'id' | 'created_at' | 'updated_at'>[]): Promise<PageThumbnail[]>;
}

export interface IOutlineRepository extends IRepository<Outline> {
    createMany(items: Omit<Outline, 'id' | 'created_at' | 'updated_at'>[]): Promise<Outline[]>;
}

export interface ICommentRepository extends IRepository<Comment> {
    createMany(items: Omit<Comment, 'id' | 'created_at' | 'updated_at'>[]): Promise<Comment[]>;
}

export interface ILinkRepository extends IRepository<Link> {
    createMany(items: Omit<Link, 'id' | 'created_at' | 'updated_at'>[]): Promise<Link[]>;
}

export interface ITemplateRepository extends IRepository<Template> {
    createMany(items: Omit<Template, 'id' | 'created_at' | 'updated_at'>[]): Promise<Template[]>;
}

export interface IFavoriteRepository extends IRepository<Favorite> {
    createMany(items: Omit<Favorite, 'id' | 'created_at' | 'updated_at'>[]): Promise<Favorite[]>;
}

export interface IUserSettingsRepository extends IRepository<UserSettings> {}

export interface IAssetRepository extends IRepository<Asset> {
    findByHash(hash: string): Promise<Asset | null>;
}

export interface IDatabaseAdapter {
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

  transaction<T>(fn: () => Promise<T>): Promise<T>;
  close(): Promise<void>;
}

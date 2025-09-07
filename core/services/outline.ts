// core/services/outline.ts

import { IDatabaseAdapter, Outline } from '../db';

export class OutlineService {
  private db: IDatabaseAdapter;

  constructor(dbAdapter: IDatabaseAdapter) {
    this.db = dbAdapter;
  }

  async addOutline(
    documentId: number,
    pageId: number | null,
    parentId: number | null,
    title: string,
    entryOrder: number
  ): Promise<Outline> {
    return this.db.outlines.create({
      document_id: documentId,
      page_id: pageId,
      parent_id: parentId,
      title,
      entry_order: entryOrder,
    });
  }

  async updateOutline(id: number, title: string, entryOrder: number): Promise<Outline> {
    return this.db.outlines.update(id, { title, entry_order: entryOrder });
  }

  async deleteOutline(id: number): Promise<boolean> {
    return this.db.outlines.delete(id);
  }

  async getOutlinesForDocument(documentId: number): Promise<Outline[]> {
    return this.db.outlines.find({ document_id: documentId, orderBy: { created_at: 'DESC' } });
  }

  async getOutlinesForPage(documentId: number, pageId: number): Promise<Outline[]> {
    return this.db.outlines.find({ document_id: documentId, page_id: pageId, orderBy: { created_at: 'DESC' } });
  }
}

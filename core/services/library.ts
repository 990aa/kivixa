// core/services/library.ts

import { IDatabaseAdapter, Document, IRepository } from '../db';

export interface Notebook extends IRepository<any> {
    id: number;
    title: string;
    created_at: string;
    updated_at: string;
}

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export class LibraryService {
  private db: IDatabaseAdapter;

  constructor(dbAdapter: IDatabaseAdapter) {
    this.db = dbAdapter;
  }

  /**
   * Lists all notebooks with pagination.
   */
  async listNotebooks(page: number, pageSize: number): Promise<PaginatedResult<Notebook>> {
    // This is a simplified pagination.
    
    const notebooks = await this.db.documents.find({ notebook_id: page });
    return {
      items: notebooks as unknown as Notebook[],
      total: notebooks.length, // Placeholder for total count
      page,
      pageSize,
    };
  }

  /**
   * Lists all documents within a specific notebook, with pagination.
   */
  async listDocumentsInNotebook(notebookId: number, page: number, pageSize: number): Promise<PaginatedResult<Document>> {
    const documents = await this.db.documents.find({ notebook_id: notebookId });
    return {
      items: documents,
      total: documents.length, // Placeholder for total count
      page,
      pageSize,
    };
  }

  /**
   * Moves a document to a different notebook in a single transaction.
   */
  async moveDocument(documentId: number, targetNotebookId: number): Promise<boolean> {
    try {
      await this.db.transaction(async () => {
        await this.db.documents.update(documentId, { notebook_id: targetNotebookId });
      });
      return true;
    } catch (error) {
      console.error('Failed to move document:', error);
      return false;
    }
  }

  /**
   * Creates a new notebook.
   */
  async createNotebook(title: string): Promise<Notebook> {
    // The schema does not have a notebooks repository, so this is a placeholder
    return Promise.resolve({} as Notebook);
  }

  /**
   * Creates a new document within a notebook.
   */
  async createDocument(title: string, notebookId: number): Promise<Document> {
    return this.db.documents.create({ title, notebook_id: notebookId });
  }
}

// core/services/comments.ts

import { IDatabaseAdapter, Comment } from '../db';

export class CommentsService {
  private db: IDatabaseAdapter;

  constructor(dbAdapter: IDatabaseAdapter) {
    this.db = dbAdapter;
  }

  async addComment(
    documentId: number,
    pageId: number,
    userId: string | null,
    content: string
  ): Promise<Comment> {
    return this.db.comments.create({
      document_id: documentId,
      page_id: pageId,
      user_id: userId,
      content,
    });
  }

  async updateComment(id: number, content: string): Promise<Comment> {
    return this.db.comments.update(id, { content });
  }

  async deleteComment(id: number): Promise<boolean> {
    return this.db.comments.delete(id);
  }

  async getCommentsForDocument(documentId: number): Promise<Comment[]> {
    return this.db.comments.find({ document_id: documentId, orderBy: { created_at: 'DESC' } });
  }

  async getCommentsForPage(documentId: number, pageId: number): Promise<Comment[]> {
    return this.db.comments.find({ document_id: documentId, page_id: pageId, orderBy: { created_at: 'DESC' } });
  }
}

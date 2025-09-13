# Outline & Comment Parity Checklist

This document shows the requirements for generating document outlines and handling comments, mapping features to the responsible services and database tables.

## Feature Checklist

| Feature | Description | Backend Services | Database Tables | UI Review |
| --- | --- | --- | --- | :---: |
| **Outline from PDF Text** | For imported PDFs with a text layer, automatically generate an outline based on the document's table of contents or heading structure. | `OutlineCommentsService`, `PDFTextSearch` | `document_outlines`, `outline_items` | ☐ |
| **Outline from Scanned Pages** | For imported PDFs (scans) or images without a text layer, generate an outline using page thumbnails. Each thumbnail represents a top-level outline item. | `ScannedPagesOutlineService`, `TiledThumbnailsService` | `document_outlines`, `outline_items` | ☐ |
| **User-Created Comments** | Users can add their own notes or comments to an outline item. These comments are attached to the page or a specific region. | `OutlineCommentAdmin`, `OutlineCommentsService` | `comments`, `comment_attachments` | ☐ |
| **Batch Operations (Tiled Mode)** | In a tiled thumbnail view, users can select multiple pages (outline items) and perform batch operations, such as deleting, tagging, or exporting. | `TiledThumbnailsService`, `OutlineCommentAdmin`, `ExportManager` | `outline_items`, `tags` | ☐ |
| **Comment Editing/Deletion** | Users can edit or delete comments they have created. | `OutlineCommentAdmin` | `comments` | ☐ |
| **Outline Item Renaming** | Users can rename outline items, whether they were generated automatically or created manually. | `OutlineCommentAdmin` | `outline_items` | ☐ |

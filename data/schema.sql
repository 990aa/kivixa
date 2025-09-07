-- kivixa Normalized SQLite Schema
-- Core entities: notebooks, documents, pages, layers, strokes, text_blocks, images, shapes, assets, outlines, comments, links, templates, favorites, audio_clips, user_settings, ai_providers, ai_keys, page_thumbnails, redo_log, job_queue, minimap_tiles

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS notebooks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notebooks_created_at ON notebooks(created_at);
CREATE INDEX IF NOT EXISTS idx_notebooks_updated_at ON notebooks(updated_at);

CREATE TABLE IF NOT EXISTS documents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  notebook_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_documents_notebook_id ON documents(notebook_id);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at);
CREATE INDEX IF NOT EXISTS idx_documents_updated_at ON documents(updated_at);

CREATE TABLE IF NOT EXISTS pages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id INTEGER NOT NULL,
  page_number INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_pages_document_id ON pages(document_id);
CREATE INDEX IF NOT EXISTS idx_pages_created_at ON pages(created_at);
CREATE INDEX IF NOT EXISTS idx_pages_updated_at ON pages(updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pages_doc_page ON pages(document_id, page_number);

CREATE TABLE IF NOT EXISTS layers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  page_id INTEGER NOT NULL,
  z_index INTEGER NOT NULL,
  type TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_layers_page_id ON layers(page_id);
CREATE INDEX IF NOT EXISTS idx_layers_created_at ON layers(created_at);
CREATE INDEX IF NOT EXISTS idx_layers_updated_at ON layers(updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_layers_page_z ON layers(page_id, z_index);

CREATE TABLE IF NOT EXISTS strokes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  layer_id INTEGER NOT NULL,
  chunk_index INTEGER NOT NULL,
  data BLOB NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (layer_id) REFERENCES layers(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_strokes_layer_id ON strokes(layer_id);
CREATE INDEX IF NOT EXISTS idx_strokes_created_at ON strokes(created_at);
CREATE INDEX IF NOT EXISTS idx_strokes_updated_at ON strokes(updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_strokes_layer_chunk ON strokes(layer_id, chunk_index);

CREATE TABLE IF NOT EXISTS text_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  layer_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  style TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (layer_id) REFERENCES layers(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_text_blocks_layer_id ON text_blocks(layer_id);
CREATE INDEX IF NOT EXISTS idx_text_blocks_created_at ON text_blocks(created_at);
CREATE INDEX IF NOT EXISTS idx_text_blocks_updated_at ON text_blocks(updated_at);

CREATE TABLE IF NOT EXISTS images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  layer_id INTEGER NOT NULL,
  asset_id INTEGER,
  data BLOB,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (layer_id) REFERENCES layers(id) ON DELETE CASCADE,
  FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_images_layer_id ON images(layer_id);
CREATE INDEX IF NOT EXISTS idx_images_asset_id ON images(asset_id);
CREATE INDEX IF NOT EXISTS idx_images_created_at ON images(created_at);
CREATE INDEX IF NOT EXISTS idx_images_updated_at ON images(updated_at);

CREATE TABLE IF NOT EXISTS shapes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  layer_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  data TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (layer_id) REFERENCES layers(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_shapes_layer_id ON shapes(layer_id);
CREATE INDEX IF NOT EXISTS idx_shapes_created_at ON shapes(created_at);
CREATE INDEX IF NOT EXISTS idx_shapes_updated_at ON shapes(updated_at);

CREATE TABLE IF NOT EXISTS assets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  filename TEXT NOT NULL,
  mime_type TEXT,
  size INTEGER,
  hash TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_assets_created_at ON assets(created_at);
CREATE INDEX IF NOT EXISTS idx_assets_updated_at ON assets(updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_assets_hash ON assets(hash);

CREATE TABLE IF NOT EXISTS outlines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  page_id INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_outlines_document_id ON outlines(document_id);
CREATE INDEX IF NOT EXISTS idx_outlines_page_id ON outlines(page_id);
CREATE INDEX IF NOT EXISTS idx_outlines_created_at ON outlines(created_at);
CREATE INDEX IF NOT EXISTS idx_outlines_updated_at ON outlines(updated_at);

CREATE TABLE IF NOT EXISTS comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  page_id INTEGER NOT NULL,
  user_id TEXT,
  content TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_comments_page_id ON comments(page_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at);
CREATE INDEX IF NOT EXISTS idx_comments_updated_at ON comments(updated_at);

CREATE TABLE IF NOT EXISTS links (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_page_id INTEGER NOT NULL,
  to_page_id INTEGER NOT NULL,
  type TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (from_page_id) REFERENCES pages(id) ON DELETE CASCADE,
  FOREIGN KEY (to_page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_links_from_page_id ON links(from_page_id);
CREATE INDEX IF NOT EXISTS idx_links_to_page_id ON links(to_page_id);
CREATE INDEX IF NOT EXISTS idx_links_created_at ON links(created_at);
CREATE INDEX IF NOT EXISTS idx_links_updated_at ON links(updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_links_from_to ON links(from_page_id, to_page_id);

CREATE TABLE IF NOT EXISTS templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  data BLOB,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_templates_created_at ON templates(created_at);
CREATE INDEX IF NOT EXISTS idx_templates_updated_at ON templates(updated_at);

CREATE TABLE IF NOT EXISTS favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  document_id INTEGER,
  page_id INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_document_id ON favorites(document_id);
CREATE INDEX IF NOT EXISTS idx_favorites_page_id ON favorites(page_id);
CREATE INDEX IF NOT EXISTS idx_favorites_created_at ON favorites(created_at);
CREATE INDEX IF NOT EXISTS idx_favorites_updated_at ON favorites(updated_at);

CREATE TABLE IF NOT EXISTS audio_clips (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  page_id INTEGER NOT NULL,
  asset_id INTEGER,
  data BLOB,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE,
  FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_audio_clips_page_id ON audio_clips(page_id);
CREATE INDEX IF NOT EXISTS idx_audio_clips_asset_id ON audio_clips(asset_id);
CREATE INDEX IF NOT EXISTS idx_audio_clips_created_at ON audio_clips(created_at);
CREATE INDEX IF NOT EXISTS idx_audio_clips_updated_at ON audio_clips(updated_at);

CREATE TABLE IF NOT EXISTS user_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  settings_json TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_created_at ON user_settings(created_at);
CREATE INDEX IF NOT EXISTS idx_user_settings_updated_at ON user_settings(updated_at);

CREATE TABLE IF NOT EXISTS ai_providers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  config_json TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_ai_providers_created_at ON ai_providers(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_providers_updated_at ON ai_providers(updated_at);

CREATE TABLE IF NOT EXISTS ai_keys (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider_id INTEGER NOT NULL,
  encrypted_key BLOB NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (provider_id) REFERENCES ai_providers(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_ai_keys_provider_id ON ai_keys(provider_id);
CREATE INDEX IF NOT EXISTS idx_ai_keys_created_at ON ai_keys(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_keys_updated_at ON ai_keys(updated_at);

CREATE TABLE IF NOT EXISTS page_thumbnails (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  page_id INTEGER NOT NULL,
  data BLOB,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_page_thumbnails_page_id ON page_thumbnails(page_id);
CREATE INDEX IF NOT EXISTS idx_page_thumbnails_created_at ON page_thumbnails(created_at);
CREATE INDEX IF NOT EXISTS idx_page_thumbnails_updated_at ON page_thumbnails(updated_at);

CREATE TABLE IF NOT EXISTS redo_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id INTEGER,
  page_id INTEGER,
  action TEXT NOT NULL,
  data TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_redo_log_document_id ON redo_log(document_id);
CREATE INDEX IF NOT EXISTS idx_redo_log_page_id ON redo_log(page_id);
CREATE INDEX IF NOT EXISTS idx_redo_log_created_at ON redo_log(created_at);
CREATE INDEX IF NOT EXISTS idx_redo_log_updated_at ON redo_log(updated_at);

CREATE TABLE IF NOT EXISTS job_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  status TEXT NOT NULL,
  payload TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_job_queue_type ON job_queue(type);
CREATE INDEX IF NOT EXISTS idx_job_queue_status ON job_queue(status);
CREATE INDEX IF NOT EXISTS idx_job_queue_created_at ON job_queue(created_at);
CREATE INDEX IF NOT EXISTS idx_job_queue_updated_at ON job_queue(updated_at);

CREATE TABLE IF NOT EXISTS minimap_tiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  page_id INTEGER NOT NULL,
  tile_x INTEGER NOT NULL,
  tile_y INTEGER NOT NULL,
  data BLOB,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_minimap_tiles_page_id ON minimap_tiles(page_id);
CREATE INDEX IF NOT EXISTS idx_minimap_tiles_tile_xy ON minimap_tiles(page_id, tile_x, tile_y);
CREATE INDEX IF NOT EXISTS idx_minimap_tiles_created_at ON minimap_tiles(created_at);
CREATE INDEX IF NOT EXISTS idx_minimap_tiles_updated_at ON minimap_tiles(updated_at);

// Dart migration for initial schema: notebooks, documents, pages, layers, strokes (chunked), text_blocks, images, shapes, assets, outlines, comments, links, templates, favorites, audio_clips, user_settings, ai_providers, ai_keys, page_thumbnails, redo_log, job_queue, minimap_tiles

final String migration001 = '''
CREATE TABLE notebooks (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	title TEXT NOT NULL,
	created_at INTEGER NOT NULL,
	updated_at INTEGER NOT NULL
);

CREATE TABLE documents (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	notebook_id INTEGER NOT NULL REFERENCES notebooks(id) ON DELETE CASCADE,
	title TEXT NOT NULL,
	created_at INTEGER NOT NULL,
	updated_at INTEGER NOT NULL
);

CREATE TABLE pages (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
	page_index INTEGER NOT NULL,
	created_at INTEGER NOT NULL,
	updated_at INTEGER NOT NULL
);

CREATE TABLE layers (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	layer_index INTEGER NOT NULL,
	type TEXT NOT NULL,
	visible INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE strokes (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	layer_id INTEGER NOT NULL REFERENCES layers(id) ON DELETE CASCADE,
	stroke_id TEXT NOT NULL,
	chunk_index INTEGER NOT NULL,
	data BLOB NOT NULL,
	ts INTEGER NOT NULL,
	UNIQUE(stroke_id, chunk_index)
);

CREATE TABLE text_blocks (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	layer_id INTEGER NOT NULL REFERENCES layers(id) ON DELETE CASCADE,
	content TEXT NOT NULL,
	style TEXT,
	position TEXT,
	created_at INTEGER NOT NULL,
	updated_at INTEGER NOT NULL
);

CREATE TABLE images (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	layer_id INTEGER NOT NULL REFERENCES layers(id) ON DELETE CASCADE,
	asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
	position TEXT,
	created_at INTEGER NOT NULL
);

CREATE TABLE shapes (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	layer_id INTEGER NOT NULL REFERENCES layers(id) ON DELETE CASCADE,
	type TEXT NOT NULL,
	data TEXT NOT NULL,
	created_at INTEGER NOT NULL
);

CREATE TABLE assets (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	path TEXT NOT NULL,
	size INTEGER NOT NULL,
	hash TEXT NOT NULL,
	mime TEXT NOT NULL,
	created_at INTEGER NOT NULL,
	UNIQUE(hash)
);

CREATE TABLE outlines (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
	data TEXT NOT NULL
);

CREATE TABLE comments (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	content TEXT NOT NULL,
	author TEXT,
	created_at INTEGER NOT NULL
);

CREATE TABLE links (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	from_page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	to_page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	type TEXT NOT NULL
);

CREATE TABLE templates (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL,
	data TEXT NOT NULL,
	created_at INTEGER NOT NULL
);

CREATE TABLE favorites (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	user_id TEXT,
	entity_type TEXT NOT NULL,
	entity_id INTEGER NOT NULL,
	created_at INTEGER NOT NULL
);

CREATE TABLE audio_clips (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
	start_time INTEGER,
	end_time INTEGER,
	created_at INTEGER NOT NULL
);

CREATE TABLE user_settings (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	user_id TEXT,
	key TEXT NOT NULL,
	value TEXT,
	updated_at INTEGER NOT NULL,
	UNIQUE(user_id, key)
);

CREATE TABLE ai_providers (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL,
	config TEXT NOT NULL
);

CREATE TABLE ai_keys (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	provider_id INTEGER NOT NULL REFERENCES ai_providers(id) ON DELETE CASCADE,
	encrypted_key BLOB NOT NULL,
	created_at INTEGER NOT NULL
);

CREATE TABLE page_thumbnails (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
	created_at INTEGER NOT NULL
);

CREATE TABLE redo_log (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	entity_type TEXT NOT NULL,
	entity_id INTEGER NOT NULL,
	action TEXT NOT NULL,
	data TEXT,
	ts INTEGER NOT NULL
);

CREATE TABLE job_queue (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	job_type TEXT NOT NULL,
	payload TEXT NOT NULL,
	status TEXT NOT NULL,
	created_at INTEGER NOT NULL,
	updated_at INTEGER NOT NULL
);

CREATE TABLE minimap_tiles (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	page_id INTEGER NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
	tile_index INTEGER NOT NULL,
	asset_id INTEGER NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
	created_at INTEGER NOT NULL,
	UNIQUE(page_id, tile_index)
);

-- Indices for fast lookup
CREATE INDEX idx_documents_notebook_id ON documents(notebook_id);
CREATE INDEX idx_pages_document_id ON pages(document_id);
CREATE INDEX idx_layers_page_id ON layers(page_id);
CREATE INDEX idx_strokes_layer_id ON strokes(layer_id);
CREATE INDEX idx_text_blocks_layer_id ON text_blocks(layer_id);
CREATE INDEX idx_images_layer_id ON images(layer_id);
CREATE INDEX idx_shapes_layer_id ON shapes(layer_id);
CREATE INDEX idx_assets_hash ON assets(hash);
CREATE INDEX idx_comments_page_id ON comments(page_id);
CREATE INDEX idx_links_from_page_id ON links(from_page_id);
CREATE INDEX idx_links_to_page_id ON links(to_page_id);
CREATE INDEX idx_audio_clips_page_id ON audio_clips(page_id);
CREATE INDEX idx_page_thumbnails_page_id ON page_thumbnails(page_id);
CREATE INDEX idx_minimap_tiles_page_id ON minimap_tiles(page_id);
''';

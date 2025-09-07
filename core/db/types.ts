// core/db/types.ts

export interface Document {
  id: number;
  notebook_id: number;
  title: string;
  created_at: string;
  updated_at: string;
}

export interface Page {
  id: number;
  document_id: number;
  page_number: number;
  created_at: string;
  updated_at: string;
}

export interface Layer {
  id: number;
  page_id: number;
  z_index: number;
  type: string;
  created_at: string;
  updated_at: string;
}

export interface Stroke {
  id: number;
  layer_id: number;
  chunk_index: number;
  data: Buffer;
  created_at: string;
  updated_at: string;
}

export interface PageThumbnail {
  id: number;
  page_id: number;
  data: Buffer;
  created_at: string;
  updated_at: string;
}

export interface Outline {
  id: number;
  document_id: number;
  title: string;
  page_id?: number;
  created_at: string;
  updated_at: string;
}

export interface Comment {
  id: number;
  page_id: number;
  user_id?: string;
  content: string;
  created_at: string;
  updated_at: string;
}

export interface Link {
  id: number;
  from_page_id: number;
  to_page_id: number;
  type?: string;
  created_at: string;
  updated_at: string;
}

export interface Template {
  id: number;
  name: string;
  data: Buffer;
  created_at: string;
  updated_at: string;
}

export interface Favorite {
  id: number;
  user_id?: string;
  document_id?: number;
  page_id?: number;
  created_at: string;
  updated_at: string;
}

export interface UserSettings {
  id: number;
  user_id?: string;
  settings_json: string;
  created_at: string;
  updated_at: string;
}

export interface Asset {
    id: number;
    filename: string;
    mime_type?: string;
    size?: number;
    hash?: string;
    created_at: string;
    updated_at: string;
}

export interface SplitLayout {
    id: number;
    user_id: string;
    orientation: 'horizontal' | 'vertical';
    divider_position: number;
    pane1_document_id?: number;
    pane2_document_id?: number;
    created_at: string;
    updated_at: string;
}
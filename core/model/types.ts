// core/model/types.ts

// Represents the geometric properties of an element
export interface Bounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

// Base type for any element that can be on a page
export interface PageElement {
  id: string; // Using string UUIDs for in-memory representation
  layerId: number;
  bounds: Bounds;
  rotation: number;
}

export interface Stroke extends PageElement {
  type: 'stroke';
  points: { x: number; y: number; pressure: number }[];
  color: string;
  strokeWidth: number;
}

export interface TextBlock extends PageElement {
  type: 'text';
  content: string;
  fontSize: number;
  fontFamily: string;
}

export type LayerContent = Stroke | TextBlock;

// Represents a layer on a page
export interface Layer {
  id: number;
  zIndex: number;
  isVisible: boolean;
  name?: string;
  elements: Map<string, LayerContent>;
}

// Represents a single page in a document
export interface Page {
  id: number;
  pageNumber: number;
  layers: Map<number, Layer>;
  backgroundColor: string;
}

// Represents a full document
export interface Document {
  id: number;
  title: string;
  pages: Map<number, Page>;
}

// Represents the user's current selection
export interface Selection {
  pageId: number;
  elementIds: string[];
}

// Represents a hyperlink between pages or to external resources
export interface Link {
  id: number;
  from: { pageId: number; elementId?: string; area?: Bounds };
  to: { pageId: number; elementId?: string } | { url: string };
}

// Represents a reusable template
export interface Template {
  id: number;
  name: string;
  elements: PageElement[];
}

// Represents a tool (e.g., pen, eraser)
export interface Tool {
  type: 'pen' | 'eraser' | 'highlighter' | 'selector';
  color?: string;
  strokeWidth?: number;
}

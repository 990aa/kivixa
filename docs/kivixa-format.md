# Kivixa Native Document Format

This document outlines the native file format for Kivixa documents. A Kivixa document is a folder containing a `kivixa.json` file and an `assets` directory.

## Directory Structure

A Kivixa document is stored as a directory with the following structure:

```
MyNote/
├── kivixa.json
└── assets/
    ├── image1.png
    ├── audio_recording.mp3
    └── source.pdf
```

- **`kivixa.json`**: A JSON file containing the document's structure, content, and metadata.
- **`assets/`**: A directory for storing all binary assets like images, audio files, source PDFs, and other attachments.

## `kivixa.json` Schema

The `kivixa.json` file has the following top-level structure:

```json
{
  "version": "1.0",
  "metadata": { ... },
  "template": { ... },
  "pages": [ ... ],
  "linkGraph": { ... },
  "attachments": [ ... ]
}
```

### Root Object

| Field         | Type     | Description                                                                   |
| ------------- | -------- | ----------------------------------------------------------------------------- |
| `version`     | `string` | The version of the Kivixa file format. Used for migration purposes.           |
| `metadata`    | `object` | Contains metadata for the document. See [Metadata Object](#metadata-object).  |
| `template`    | `object` | Information about the template used. See [Template Object](#template-object). |
| `pages`       | `array`  | An array of [Page Objects](#page-object).                                     |
| `linkGraph`   | `object` | Defines links between pages and elements. See [Link Graph](#link-graph).      |
| `attachments` | `array`  | A list of attachments. See [Attachment Object](#attachment-object).           |

### Metadata Object

| Field        | Type     | Description                                          |
| ------------ | -------- | ---------------------------------------------------- |
| `title`      | `string` | The title of the document.                           |
| `createdAt`  | `string` | ISO 8601 timestamp of when the document was created. |
| `modifiedAt` | `string` | ISO 8601 timestamp of the last modification.         |
| `author`     | `string` | The author of the document.                          |
| `custom`     | `object` | A key-value store for any custom metadata.           |

### Template Object

| Field    | Type     | Description                                                                     |
| -------- | -------- | ------------------------------------------------------------------------------- |
| `name`   | `string` | The name of the template (e.g., "Cornell Notes", "Blank").                      |
| `source` | `string` | A reference to the template file or a unique identifier for built-in templates. |
| `custom` | `object` | A key-value store for any custom template properties.                           |

### Page Object

Each page object has the following structure:

```json
{
  "id": "page-1",
  "title": "My First Page",
  "layers": [ ... ],
  "metadata": {
    "createdAt": "2025-09-06T10:00:00Z",
    "modifiedAt": "2025-09-06T11:00:00Z"
  }
}
```

| Field      | Type     | Description                                 |
| ---------- | -------- | ------------------------------------------- |
| `id`       | `string` | A unique identifier for the page.           |
| `title`    | `string` | The title of the page.                      |
| `layers`   | `array`  | An array of [Layer Objects](#layer-object). |
| `metadata` | `object` | Page-specific metadata.                     |

### Layer Object

A layer object is a discriminated union, identified by the `type` field.

**Common Properties:**

| Field      | Type     | Description                                |
| ---------- | -------- | ------------------------------------------ |
| `id`       | `string` | A unique identifier for the layer element. |
| `type`     | `string` | The type of the layer.                     |
| `x`        | `number` | The x-coordinate of the element.           |
| `y`        | `number` | The y-coordinate of the element.           |
| `width`    | `number` | The width of the element.                  |
| `height`   | `number` | The height of the element.                 |
| `rotation` | `number` | The rotation of the element in degrees.    |

**Layer Types:**

- **`ink`**: For handwritten notes and drawings.
  ```json
  {
    "type": "ink",
    "points": [ { "x": 0, "y": 0, "p": 1.0 }, ... ],
    "stroke": { "color": "#000000", "width": 2 }
  }
  ```
- **`shape`**: For geometric shapes.
  ```json
  {
    "type": "shape",
    "shapeType": "rectangle", // "ellipse", "line", "polygon"
    "fill": { "color": "#FFFFFF" },
    "stroke": { "color": "#000000", "width": 1 }
  }
  ```
- **`text`**: For typed text.
  ```json
  {
    "type": "text",
    "text": "Hello, World!",
    "font": { "family": "Arial", "size": 16 },
    "color": "#000000"
  }
  ```
- **`media`**: For images, videos, etc.
  ```json
  {
    "type": "media",
    "src": "assets/image1.png",
    "mimeType": "image/png"
  }
  ```

### Link Graph

The `linkGraph` object defines connections between pages or elements.

```json
{
  "nodes": [{ "id": "page-1" }, { "id": "layer-abc" }],
  "edges": [
    { "from": "page-1", "to": "layer-abc", "type": "contains" },
    { "from": "layer-abc", "to": "page-2", "type": "link" }
  ]
}
```

### Attachment Object

| Field      | Type     | Description                                    |
| ---------- | -------- | ---------------------------------------------- |
| `id`       | `string` | A unique identifier for the attachment.        |
| `type`     | `string` | The type of attachment (e.g., "audio", "pdf"). |
| `src`      | `string` | The path to the attachment file in `assets/`.  |
| `mimeType` | `string` | The MIME type of the attachment.               |
| `metadata` | `object` | Attachment-specific metadata.                  |

## Versioning and Migration

The `version` field in the root of `kivixa.json` will be used to manage different versions of the file format. When a new version is introduced, Kivixa will provide utilities to migrate older documents to the new format. This ensures backward compatibility and allows the format to evolve.

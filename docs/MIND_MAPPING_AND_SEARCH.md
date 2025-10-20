# Mind Mapping & Search Functionality

## Overview
This document describes the mind mapping capabilities and full-text search functionality added to Kivixa, inspired by NoteMind's features.

## Mind Mapping Implementation

### Architecture

#### 1. MindMapNode Model (`lib/models/mind_map_node.dart`)
The `MindMapNode` class represents a node in the mind map with the following properties:
- `id`: Unique identifier (auto-generated UUID)
- `text`: Node content
- `position`: Offset for node placement
- `color`: Visual color of the node
- `childIds`: List of child node IDs
- `fontSize`: Text size
- `isCollapsed`: Collapse state for hiding children

**Key Features:**
- JSON serialization/deserialization
- `copyWith()` method for immutable updates
- Static methods for list serialization
- Color stored using `toARGB32()` for compatibility

#### 2. MindMapEdge Model
The `MindMapEdge` class represents connections between nodes:
- `id`: Unique identifier
- `fromNodeId`: Source node ID
- `toNodeId`: Target node ID
- `color`: Edge color
- `strokeWidth`: Line thickness
- `label`: Optional edge label

### Visualization

#### MindMapCanvas Widget (`lib/widgets/mind_map_canvas.dart`)
A stateful widget that renders mind maps using the `graphview` package.

**Features:**
- **InteractiveViewer**: Pan and zoom (0.1x to 5x scale)
- **Buchheim-Walker Algorithm**: Automatic tree layout
- **Node Interactions**:
  - Tap: Select node
  - Long press: Edit node
  - Drag: Reposition node
- **Collapse/Expand**: Toggle child node visibility

**Layout Configuration:**
```dart
BuchheimWalkerConfiguration()
  ..siblingSeparation = 100
  ..levelSeparation = 150
  ..subtreeSeparation = 150
  ..orientation = ORIENTATION_TOP_BOTTOM
```

**Node Rendering:**
- Rounded rectangle containers
- Color-coded borders and backgrounds
- Collapse/expand icons for parent nodes
- Shadow effects for depth
- Responsive text with overflow handling

#### MindMapViewer Widget
A simplified read-only version of `MindMapCanvas` for viewing mind maps without edit capabilities.

### Integration with Database

Mind map data can be stored in the database as canvas elements:
```dart
// Serialize nodes and edges
final nodesJson = MindMapNode.serializeNodes(nodes);
final edgesJson = MindMapEdge.serializeEdges(edges);

// Store as canvas element
final element = CanvasElementsCompanion.insert(
  noteId: noteId,
  type: 'mindmap',
  dataJson: jsonEncode({
    'nodes': nodesJson,
    'edges': edgesJson,
  }),
  // ... other properties
);
```

## Search Functionality

### FTS5 Full-Text Search

#### Database Enhancement (`lib/database/database.dart`)

**1. FTS5 Virtual Table:**
```sql
CREATE VIRTUAL TABLE notes_fts USING fts5(
  title,
  content,
  content='notes',
  content_rowid='id'
);
```

**2. Automatic Indexing Triggers:**
- **INSERT Trigger**: Indexes new notes automatically
- **UPDATE Trigger**: Updates index when notes change
- **DELETE Trigger**: Removes entries from index

**3. Search Methods:**

**Basic Search (LIKE):**
```dart
Future<List<Note>> searchNotes(String query)
```
- Uses SQL LIKE operator
- Searches both title and content
- Good for simple substring matching

**Full-Text Search (FTS5):**
```dart
Future<List<Note>> searchNotesFullText(String query)
```
- Uses FTS5 MATCH operator
- Ranked results by relevance
- Faster for large datasets
- Supports advanced search syntax

**4. Initialization:**
```dart
await database.initializeFTS5();
```
- Creates FTS5 table
- Sets up triggers
- Rebuilds index if empty

### Search UI

#### NotesSearchDelegate (`lib/widgets/search_delegate.dart`)
A `SearchDelegate` implementation providing a rich search experience.

**Features:**

**1. Search Bar:**
- Custom search field label
- Clear button when query is entered
- Back button to exit search

**2. Search Results:**
- Loading indicator during search
- Empty state with icon and message
- List of matching notes with:
  - Note icon avatar
  - Highlighted matching text (yellow background)
  - Content preview (max 100 characters)
  - Last modified date (relative: "Today", "Yesterday", "X days ago")
  - Sync status icon

**3. Search Suggestions:**
- Shows recent notes when query is empty
- Live search results as you type
- Taps close search and return selected note

**4. Text Highlighting:**
```dart
Widget _highlightText(String text, String query)
```
- Finds all occurrences of query in text
- Wraps matches in yellow background
- Bold font weight for matches
- Case-insensitive matching

**5. Error Handling:**
- Automatic fallback to basic search if FTS5 fails
- Error messages displayed in UI
- Try-catch blocks for robustness

### Usage Example

```dart
// Show search delegate
final selectedNote = await context.showNotesSearch(
  databaseService: databaseService,
  useFullTextSearch: true, // Use FTS5
);

if (selectedNote != null) {
  // Navigate to note or perform action
  print('Selected: ${selectedNote.title}');
}
```

### Extension Method
```dart
extension SearchExtension on BuildContext {
  Future<Note?> showNotesSearch({
    required DatabaseService databaseService,
    bool useFullTextSearch = true,
  })
}
```

## Performance Considerations

### Mind Mapping
1. **Layout Caching**: GraphView caches layout calculations
2. **Lazy Rendering**: Only visible nodes are rendered
3. **Collapse Feature**: Reduces complexity for large graphs
4. **InteractiveViewer**: Hardware-accelerated transformations

### Search
1. **FTS5 Indexing**: O(log n) search complexity
2. **Trigger-based Updates**: Real-time index maintenance
3. **Ranked Results**: Most relevant results first
4. **Lazy Loading**: Can be extended with pagination

## Dependencies

### Added to `pubspec.yaml`:
```yaml
dependencies:
  graphview: ^1.2.0  # Mind map visualization
  uuid: ^4.5.1       # Node ID generation
```

### Existing Dependencies Used:
- `drift`: Database with FTS5 support
- `flutter`: Core widgets and painting

## Testing

### Mind Mapping Tests
```dart
test('MindMapNode serialization', () {
  final node = MindMapNode(text: 'Test', color: Colors.blue);
  final json = node.toJson();
  final deserialized = MindMapNode.fromJson(json);
  expect(deserialized.text, equals('Test'));
});
```

### Search Tests
```dart
test('FTS5 search returns ranked results', () async {
  await db.initializeFTS5();
  final results = await db.searchNotesFullText('flutter');
  expect(results.length, greaterThan(0));
});
```

## Future Enhancements

### Mind Mapping
1. **Auto-layout Options**: Radial, hierarchical, force-directed
2. **Custom Node Shapes**: Circle, diamond, hexagon
3. **Rich Media Nodes**: Images, links, attachments
4. **Export Formats**: PNG, SVG, PDF of mind maps
5. **Collaborative Editing**: Real-time multi-user editing

### Search
1. **Advanced Filters**: Date range, tags, author
2. **Faceted Search**: Group by category, date, etc.
3. **Search History**: Recently searched terms
4. **Fuzzy Matching**: Spell correction and suggestions
5. **Search Analytics**: Popular searches, no-result queries

## Related Files

### Core Implementation
- `lib/models/mind_map_node.dart` - Node and edge models
- `lib/widgets/mind_map_canvas.dart` - Visualization widget
- `lib/database/database.dart` - FTS5 database schema
- `lib/widgets/search_delegate.dart` - Search UI
- `lib/services/database_service.dart` - Database operations

### Documentation
- `docs/INFINITE_CANVAS_IMPLEMENTATION.md` - Canvas foundation
- `docs/TEXT_PHOTO_IMPORT_EXPORT.md` - Import/export features
- `docs/SHAPES_AND_STORAGE.md` - Shapes and SQLite storage
- `docs/MIND_MAPPING_AND_SEARCH.md` - This document

## API Reference

### MindMapNode
```dart
class MindMapNode {
  MindMapNode({
    String? id,
    required String text,
    Offset position = Offset.zero,
    Color color = Colors.blue,
    List<String>? childIds,
    double fontSize = 16.0,
    bool isCollapsed = false,
  });
  
  MindMapNode copyWith({...});
  Map<String, dynamic> toJson();
  factory MindMapNode.fromJson(Map<String, dynamic> json);
  static String serializeNodes(List<MindMapNode> nodes);
  static List<MindMapNode> deserializeNodes(String json);
}
```

### MindMapCanvas
```dart
class MindMapCanvas extends StatefulWidget {
  const MindMapCanvas({
    required List<MindMapNode> nodes,
    required List<MindMapEdge> edges,
    Function(MindMapNode)? onNodeTap,
    Function(MindMapNode)? onNodeLongPress,
    Function(MindMapNode, Offset)? onNodeDrag,
    bool enableEdit = true,
  });
}
```

### NotesSearchDelegate
```dart
class NotesSearchDelegate extends SearchDelegate<Note?> {
  NotesSearchDelegate({
    required DatabaseService databaseService,
    bool useFullTextSearch = true,
  });
}
```

### Database Methods
```dart
class AppDatabase {
  Future<List<Note>> searchNotes(String query);
  Future<List<Note>> searchNotesFullText(String query);
  Future<void> initializeFTS5();
  Future<void> createFTS5Table();
  Future<void> setupFTS5Triggers();
  Future<void> rebuildFTS5Index();
}
```
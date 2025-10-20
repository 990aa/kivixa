import 'package:flutter/material.dart';
import '../database/tag_repository.dart';
import '../database/document_repository.dart';
import '../models/drawing_document.dart';
import '../models/tag.dart';

/// Filter and search panel for document organization
///
/// Features:
/// - Text search by name
/// - Document type filtering (canvas, image, pdf)
/// - Tag filtering with custom colors
/// - Sort options (8 choices)
/// - Favorites-only toggle
class SearchFilterPanel extends StatefulWidget {
  final Function(SearchFilterCriteria) onFilterChanged;
  final SearchFilterCriteria? initialCriteria;

  const SearchFilterPanel({
    super.key,
    required this.onFilterChanged,
    this.initialCriteria,
  });

  @override
  State<SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<SearchFilterPanel> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  List<DocumentType> _selectedTypes = [];
  final List<Tag> _selectedTags = [];
  bool _favoritesOnly = false;
  DocumentSortBy _sortBy = DocumentSortBy.dateModifiedDesc;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Apply initial criteria if provided
    if (widget.initialCriteria != null) {
      _searchQuery = widget.initialCriteria!.searchQuery ?? '';
      _searchController.text = _searchQuery;
      _selectedTypes = widget.initialCriteria!.types ?? [];
      _favoritesOnly = widget.initialCriteria!.favoritesOnly;
      _sortBy = widget.initialCriteria!.sortBy;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
          ),

          const SizedBox(height: 24),

          // Type filters
          Text(
            'Document Type',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DocumentType.values.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getTypeIcon(type), size: 16),
                    const SizedBox(width: 4),
                    Text(_getTypeLabel(type)),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Tag filters
          Text(
            'Tags',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTagFilters(),

          const SizedBox(height: 24),

          // Sort options
          Text(
            'Sort By',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<DocumentSortBy>(
            initialValue: _sortBy,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: DocumentSortBy.values.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(_getSortOptionLabel(option)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
                _applyFilters();
              }
            },
          ),

          const SizedBox(height: 16),

          // Favorites filter
          CheckboxListTile(
            title: const Text('Favorites Only'),
            subtitle: const Text('Show only starred documents'),
            value: _favoritesOnly,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() => _favoritesOnly = value ?? false);
              _applyFilters();
            },
          ),

          const SizedBox(height: 16),

          // Clear all filters button
          if (_hasActiveFilters())
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All Filters'),
                onPressed: _clearAllFilters,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagFilters() {
    return FutureBuilder<List<Tag>>(
      future: _loadAllTags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error loading tags: ${snapshot.error}');
        }

        final allTags = snapshot.data ?? [];

        if (allTags.isEmpty) {
          return const Text(
            'No tags available',
            style: TextStyle(color: Colors.grey),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTags.map((tag) {
            final isSelected = _selectedTags.any((t) => t.id == tag.id);
            return FilterChip(
              label: Text(tag.name),
              backgroundColor: tag.color.withValues(alpha: 0.2),
              selectedColor: tag.color.withValues(alpha: 0.5),
              checkmarkColor: Colors.white,
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.removeWhere((t) => t.id == tag.id);
                  }
                });
                _applyFilters();
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Tag>> _loadAllTags() async {
    final tagRepo = TagRepository();
    return await tagRepo.getAllTags();
  }

  void _applyFilters() {
    widget.onFilterChanged(
      SearchFilterCriteria(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        types: _selectedTypes.isEmpty ? null : _selectedTypes,
        tagIds: _selectedTags.isEmpty
            ? null
            : _selectedTags.map((t) => t.id!).toList(),
        favoritesOnly: _favoritesOnly,
        sortBy: _sortBy,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedTypes.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _favoritesOnly ||
        _sortBy != DocumentSortBy.dateModifiedDesc;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedTypes.clear();
      _selectedTags.clear();
      _favoritesOnly = false;
      _sortBy = DocumentSortBy.dateModifiedDesc;
    });
    _applyFilters();
  }

  IconData _getTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.canvas:
        return Icons.brush;
      case DocumentType.image:
        return Icons.image;
      case DocumentType.pdf:
        return Icons.picture_as_pdf;
    }
  }

  String _getTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.canvas:
        return 'Canvas';
      case DocumentType.image:
        return 'Image';
      case DocumentType.pdf:
        return 'PDF';
    }
  }

  String _getSortOptionLabel(DocumentSortBy option) {
    switch (option) {
      case DocumentSortBy.nameAsc:
        return 'Name (A-Z)';
      case DocumentSortBy.nameDesc:
        return 'Name (Z-A)';
      case DocumentSortBy.dateCreatedAsc:
        return 'Created (Oldest)';
      case DocumentSortBy.dateCreatedDesc:
        return 'Created (Newest)';
      case DocumentSortBy.dateModifiedAsc:
        return 'Modified (Oldest)';
      case DocumentSortBy.dateModifiedDesc:
        return 'Modified (Newest)';
      case DocumentSortBy.sizeAsc:
        return 'Size (Smallest)';
      case DocumentSortBy.sizeDesc:
        return 'Size (Largest)';
    }
  }
}

/// Search and filter criteria for documents
class SearchFilterCriteria {
  final String? searchQuery;
  final List<DocumentType>? types;
  final List<int>? tagIds;
  final bool favoritesOnly;
  final DocumentSortBy sortBy;

  SearchFilterCriteria({
    this.searchQuery,
    this.types,
    this.tagIds,
    this.favoritesOnly = false,
    this.sortBy = DocumentSortBy.dateModifiedDesc,
  });

  /// Check if any filters are active
  bool get hasActiveFilters {
    return searchQuery != null ||
        (types != null && types!.isNotEmpty) ||
        (tagIds != null && tagIds!.isNotEmpty) ||
        favoritesOnly ||
        sortBy != DocumentSortBy.dateModifiedDesc;
  }

  /// Create copy with updated values
  SearchFilterCriteria copyWith({
    String? searchQuery,
    List<DocumentType>? types,
    List<int>? tagIds,
    bool? favoritesOnly,
    DocumentSortBy? sortBy,
  }) {
    return SearchFilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      types: types ?? this.types,
      tagIds: tagIds ?? this.tagIds,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

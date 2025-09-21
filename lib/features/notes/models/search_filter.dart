import 'package:flutter/material.dart';

class SearchFilter {
  final DateTimeRange? dateRange;
  final List<String> tags;
  final String? folderId;
  final SortOption sortOption;

  SearchFilter({
    this.dateRange,
    this.tags = const [],
    this.folderId,
    this.sortOption = SortOption.name,
  });

  SearchFilter copyWith({
    DateTimeRange? dateRange,
    List<String>? tags,
    String? folderId,
    SortOption? sortOption,
  }) {
    return SearchFilter(
      dateRange: dateRange ?? this.dateRange,
      tags: tags ?? this.tags,
      folderId: folderId ?? this.folderId,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

enum SortOption { name, date, size, type }

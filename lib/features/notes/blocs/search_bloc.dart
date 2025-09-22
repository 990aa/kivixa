import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/models/search_filter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged, transformer: _debounce());
    on<SearchSubmitted>(_onSearchSubmitted);
    on<ClearSearchHistory>(_onClearSearchHistory);
    on<RemoveSearchHistoryItem>(_onRemoveSearchHistoryItem);
  }

  EventTransformer<T> _debounce<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 300))
        .asyncExpand(mapper);
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }
    emit(SearchLoading());
    try {
      // Simulate network/database call
      await Future.delayed(const Duration(milliseconds: 500));
      final suggestions = [
        '${event.query} suggestion 1',
        '${event.query} suggestion 2',
      ];
      final history = await _getSearchHistory();
      emit(
        SearchLoaded(
          results: [],
          suggestions: suggestions,
          history: history,
          filter: SearchFilter(),
        ),
      );
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onSearchSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    await _addToSearchHistory(event.query);
    emit(SearchLoading());
    try {
      // Simulate network/database call
      await Future.delayed(const Duration(milliseconds: 500));
      final results = [
        'Result for ${event.query} 1',
        'Result for ${event.query} 2',
      ];
      final history = await _getSearchHistory();
      emit(
        SearchLoaded(
          results: results,
          suggestions: [],
          history: history,
          filter: SearchFilter(),
        ),
      );
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    final prefs = await _prefs;
    await prefs.remove('search_history');
    emit(
      SearchLoaded(
        results: [],
        suggestions: [],
        history: [],
        filter: SearchFilter(),
      ),
    );
  }

  Future<void> _addToSearchHistory(String query) async {
    final prefs = await _prefs;
    final history = prefs.getStringList('search_history') ?? [];
    if (!history.contains(query)) {
      history.insert(0, query);
      await prefs.setStringList('search_history', history);
    }
  }

  Future<List<String>> _getSearchHistory() async {
    final prefs = await _prefs;
    return prefs.getStringList('search_history') ?? [];
  }
}

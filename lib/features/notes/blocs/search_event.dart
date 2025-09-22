part of 'search_bloc.dart';

@immutable
abstract class SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class SearchHistoryUpdated extends SearchEvent {
  final List<String> history;
  SearchHistoryUpdated(this.history);
}

class FilterChanged extends SearchEvent {
  final SearchFilter filter;
  FilterChanged(this.filter);
}

class SearchSubmitted extends SearchEvent {
  final String query;
  SearchSubmitted(this.query);
}

class ClearSearchHistory extends SearchEvent {}

class RemoveSearchHistoryItem extends SearchEvent {
  final String item;
  RemoveSearchHistoryItem(this.item);
}
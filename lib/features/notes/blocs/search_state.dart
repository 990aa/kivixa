part of 'search_bloc.dart';

@immutable
abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<dynamic> results;
  final List<String> suggestions;
  final List<String> history;
  final SearchFilter filter;

  SearchLoaded({
    required this.results,
    required this.suggestions,
    required this.history,
    required this.filter,
  });
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

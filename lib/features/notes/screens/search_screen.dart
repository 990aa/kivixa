import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:kivixa/features/notes/blocs/search_bloc.dart';
import 'package:kivixa/features/notes/widgets/search_results_list.dart';
import 'package:kivixa/features/notes/widgets/search_suggestions.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              const SearchAppBar(),
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state is SearchLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is SearchLoaded) {
                      return state.results.isEmpty
                          ? SearchSuggestions(suggestions: state.suggestions, history: state.history)
                          : SearchResultsList(results: state.results);
                    }
                    if (state is SearchError) {
                      return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                    }
                    return const Center(child: Text('Search for something', style: TextStyle(color: Colors.white)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchAppBar extends StatefulWidget {
  const SearchAppBar({super.key});

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100,
      borderRadius: 20,
      blur: 10,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.1),
          const Color(0xFFFFFFFF).withOpacity(0.05),
        ],
        stops: const [0.1, 1],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.5),
          const Color(0xFFFFFFFF).withOpacity(0.5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: IconButton(
              icon: const Icon(Icons.mic, color: Colors.white),
              onPressed: () {
                // TODO: Implement voice search
              },
            ),
            border: InputBorder.none,
          ),
          onChanged: (query) {
            context.read<SearchBloc>().add(SearchQueryChanged(query));
          },
          onSubmitted: (query) {
            context.read<SearchBloc>().add(SearchSubmitted(query));
          },
        ),
      ),
    );
  }
}

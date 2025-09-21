import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchResultsList extends StatelessWidget {
  final List<dynamic> results;

  const SearchResultsList({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ListTile(
                  title: Text(results[index], style: const TextStyle(color: Colors.white)),
                  // TODO: Implement highlighted search terms
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

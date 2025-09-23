import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:kivixa/features/notes/blocs/search_bloc.dart';
import 'package:kivixa/features/notes/models/search_filter.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          NeumorphicButton(
            onPressed: () async {
              final searchBloc = context.read<SearchBloc>();
              final currentState = searchBloc.state;
              if (currentState is SearchLoaded) {
                final newDateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: currentState.filter.dateRange,
                );
                if (newDateRange != null) {
                  final newFilter =
                      currentState.filter.copyWith(dateRange: newDateRange);
                  searchBloc.add(FilterChanged(newFilter));
                }
              }
            },
            style: NeumorphicStyle(
              shape: NeumorphicShape.concave,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
              depth: 8,
              lightSource: LightSource.topLeft,
              color: Colors.grey[850],
            ),
            child: const Text(
              'Date Range',
              style: TextStyle(color: Colors.white),
            ),
          ),
          NeumorphicButton(
            onPressed: () {
              // TODO: Implement tag filter
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tag filter not implemented yet')),
              );
            },
            style: NeumorphicStyle(
              shape: NeumorphicShape.concave,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
              depth: 8,
              lightSource: LightSource.topLeft,
              color: Colors.grey[850],
            ),
            child: const Text('Tags', style: TextStyle(color: Colors.white)),
          ),
          NeumorphicButton(
            onPressed: () {
              // TODO: Implement folder filter
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Folder filter not implemented yet')),
              );
            },
            style: NeumorphicStyle(
              shape: NeumorphicShape.concave,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
              depth: 8,
              lightSource: LightSource.topLeft,
              color: Colors.grey[850],
            ),
            child: const Text('Folder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

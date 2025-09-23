import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:kivixa/features/notes/blocs/search_bloc.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
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
              _showTagFilterDialog(context);
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
              _showFolderFilterDialog(context);
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

  void _showTagFilterDialog(BuildContext context) {
    final searchBloc = context.read<SearchBloc>();
    final currentState = searchBloc.state;
    if (currentState is SearchLoaded) {
      final availableTags = ['flutter', 'dart', 'kivixa', 'notes'];
      final selectedTags = currentState.filter.tags.toList();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Filter by Tags'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  spacing: 8.0,
                  children: availableTags.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newFilter =
                      currentState.filter.copyWith(tags: selectedTags);
                  searchBloc.add(FilterChanged(newFilter));
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showFolderFilterDialog(BuildContext context) {
    final searchBloc = context.read<SearchBloc>();
    final currentState = searchBloc.state;
    if (currentState is SearchLoaded) {
      // In a real app, you would get this from a FoldersBloc or similar
      final availableFolders = [
        Folder(id: '1', name: 'Personal'),
        Folder(id: '2', name: 'Work'),
        Folder(id: '3', name: 'Ideas'),
      ];
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Filter by Folder'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableFolders.length,
                itemBuilder: (context, index) {
                  final folder = availableFolders[index];
                  return ListTile(
                    title: Text(folder.name),
                    onTap: () {
                      final newFilter =
                          currentState.filter.copyWith(folderId: folder.id);
                      searchBloc.add(FilterChanged(newFilter));
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }
}

import 'package:flutter_neumorphic/flutter_neumorphic.dart';

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
            onPressed: () {
              // TODO: Implement date range picker
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

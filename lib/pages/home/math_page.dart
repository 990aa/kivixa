import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/pages/home/math/algebra_tab.dart';
import 'package:kivixa/pages/home/math/calculus_tab.dart';
import 'package:kivixa/pages/home/math/discrete_tab.dart';
import 'package:kivixa/pages/home/math/general_tab.dart';
import 'package:kivixa/pages/home/math/graphing_tab.dart';
import 'package:kivixa/pages/home/math/statistics_tab.dart';
import 'package:kivixa/pages/home/math/tools_tab.dart';

/// Main Math page with 7 tabs for different math domains.
/// Uses native Rust backend via flutter_rust_bridge for high-performance
/// offline calculations.
class MathPage extends StatefulWidget {
  const MathPage({super.key});

  @override
  State<MathPage> createState() => _MathPageState();
}

class _MathPageState extends State<MathPage> with TickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _MathTab(
      label: 'General',
      icon: Icons.calculate,
      cupertinoIcon: CupertinoIcons.function,
    ),
    _MathTab(
      label: 'Algebra',
      icon: Icons.grid_on,
      cupertinoIcon: CupertinoIcons.square_grid_3x2,
    ),
    _MathTab(
      label: 'Calculus',
      icon: Icons.show_chart,
      cupertinoIcon: CupertinoIcons.graph_square,
    ),
    _MathTab(
      label: 'Statistics',
      icon: Icons.bar_chart,
      cupertinoIcon: CupertinoIcons.chart_bar_fill,
    ),
    _MathTab(
      label: 'Discrete',
      icon: Icons.scatter_plot,
      cupertinoIcon: CupertinoIcons.circle_grid_hex,
    ),
    _MathTab(
      label: 'Graphing',
      icon: Icons.timeline,
      cupertinoIcon: CupertinoIcons.waveform_path,
    ),
    _MathTab(
      label: 'Tools',
      icon: Icons.build,
      cupertinoIcon: CupertinoIcons.wrench,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Math'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((tab) {
            return Tab(
              icon: isMobile ? Icon(tab.icon, size: 20) : null,
              text: isMobile ? null : tab.label,
              iconMargin: EdgeInsets.zero,
            );
          }).toList(),
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          dividerColor: Colors.transparent,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: _showHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MathGeneralTab(),
          MathAlgebraTab(),
          MathCalculusTab(),
          MathStatisticsTab(),
          MathDiscreteTab(),
          MathGraphingTab(),
          MathToolsTab(),
        ],
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _HistorySheet(),
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
    );
  }
}

class _MathTab {
  final String label;
  final IconData icon;
  final IconData cupertinoIcon;

  const _MathTab({
    required this.label,
    required this.icon,
    required this.cupertinoIcon,
  });
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calculation History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Clear history',
                    onPressed: () {
                      // TODO: Clear history
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 0, // TODO: Load from history
                itemBuilder: (context, index) {
                  return const ListTile(title: Text('Placeholder'));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

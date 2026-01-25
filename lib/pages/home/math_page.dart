import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/pages/home/math/algebra_tab.dart';
import 'package:kivixa/pages/home/math/calculus_tab.dart';
import 'package:kivixa/pages/home/math/discrete_tab.dart';
import 'package:kivixa/pages/home/math/formulae_tab.dart';
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
      label: 'Formulae',
      icon: Icons.functions,
      cupertinoIcon: CupertinoIcons.textformat_alt,
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
          MathFormulaeTab(),
          MathToolsTab(),
        ],
      ),
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

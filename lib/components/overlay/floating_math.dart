import 'package:flutter/material.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/pages/home/math/general_tab.dart';
import 'package:kivixa/pages/home/math/algebra_tab.dart';
import 'package:kivixa/pages/home/math/calculus_tab.dart';
import 'package:kivixa/pages/home/math/statistics_tab.dart';
import 'package:kivixa/pages/home/math/discrete_tab.dart';
import 'package:kivixa/pages/home/math/graphing_tab.dart';
import 'package:kivixa/pages/home/math/tools_tab.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// Floating math widget that shows in the overlay.
/// Contains all math tabs: General, Algebra, Calculus, Statistics, Discrete, Graphing, Tools
class FloatingMathWindow extends StatefulWidget {
  const FloatingMathWindow({super.key});

  @override
  State<FloatingMathWindow> createState() => _FloatingMathWindowState();
}

class _FloatingMathWindowState extends State<FloatingMathWindow>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _currentTab = 0;

  final _tabs = const [
    Tab(text: 'General'),
    Tab(text: 'Algebra'),
    Tab(text: 'Calculus'),
    Tab(text: 'Stats'),
    Tab(text: 'Discrete'),
    Tab(text: 'Graph'),
    Tab(text: 'Tools'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;
    final rect =
        controller.getToolWindowRect('math') ??
        const Rect.fromLTWH(100, 100, 600, 700);

    return FloatingWindow(
      rect: rect,
      onRectChanged: (newRect) =>
          controller.updateToolWindowRect('math', newRect),
      onClose: () => controller.closeToolWindow('math'),
      title: 'Math',
      icon: Icons.calculate,
      minWidth: 400,
      minHeight: 500,
      child: Column(
        children: [
          // Tab bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _tabs,
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
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
          ),
        ],
      ),
    );
  }
}

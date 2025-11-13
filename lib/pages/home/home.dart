import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/navbar/responsive_navbar.dart';
import 'package:kivixa/components/settings/update_manager.dart';
import 'package:kivixa/components/theming/dynamic_material_app.dart';
import 'package:kivixa/pages/home/browse.dart';
import 'package:kivixa/pages/home/calendar.dart';
import 'package:kivixa/pages/home/settings.dart';
import 'package:kivixa/pages/home/whiteboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.subpage, required this.path});

  final String subpage;
  final String? path;

  @override
  State<HomePage> createState() => _HomePageState();

  static const browseSubpage = 'browse';
  static const calendarSubpage = 'calendar';
  static const whiteboardSubpage = 'whiteboard';
  static const settingsSubpage = 'settings';
  static const List<String> subpages = [
    browseSubpage,
    calendarSubpage,
    whiteboardSubpage,
    settingsSubpage,
  ];
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    DynamicMaterialApp.addFullscreenListener(_setState);
    super.initState();
    _showDialogs();
  }

  void _showDialogs() async {
    await null; // initState must be completed before using context
    if (!mounted) return;
    UpdateManager.showUpdateDialog(context);
  }

  void _setState() {
    if (mounted) setState(() {});
  }

  Widget get body {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (widget.subpage) {
        HomePage.browseSubpage => BrowsePage(path: widget.path),
        HomePage.calendarSubpage => const CalendarPage(),
        HomePage.whiteboardSubpage => const Whiteboard(),
        HomePage.settingsSubpage => const SettingsPage(),
        _ => BrowsePage(path: null),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // hide navbar in fullscreen whiteboard
    if (widget.subpage == HomePage.whiteboardSubpage &&
        DynamicMaterialApp.isFullscreen) {
      return body;
    }

    return ResponsiveNavbar(
      selectedIndex: HomePage.subpages.indexOf(widget.subpage),
      body: body,
    );
  }

  @override
  void dispose() {
    DynamicMaterialApp.removeFullscreenListener(_setState);

    super.dispose();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/theming/adaptive_icon.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/home/home.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

// workaround to assign strings as enum values
abstract class RoutePaths {
  static const home = '$prefixOfHome/:subpage';
  static const edit = '/edit';
  static const markdown = '/markdown';
  static const textFile = '/textfile';
  static const login = '/login';
  static const logs = '/logs';

  static const prefixOfHome = '/home';

  static String editFilePath(String filePath) {
    return '$edit?path=${Uri.encodeQueryComponent(filePath)}';
  }

  static String editImportPdf(String filePath, String pdfPath) {
    return '$edit'
        '?path=${Uri.encodeQueryComponent(filePath)}'
        '&pdfPath=${Uri.encodeQueryComponent(pdfPath)}';
  }

  static String markdownFilePath(String filePath) {
    return '$markdown?path=${Uri.encodeQueryComponent(filePath)}';
  }

  static String textFilePath(String filePath) {
    return '$textFile?path=${Uri.encodeQueryComponent(filePath)}';
  }
}

abstract class HomeRoutes {
  static String browseFilePath(String filePath) {
    return '${getRoute(0)}?path=${Uri.encodeQueryComponent(filePath)}';
  }

  static final PathFunction _homeFunction = pathToFunction(RoutePaths.home);

  static List<_Route> get _routes => <_Route>[
    _Route(
      routePath: _homeFunction({'subpage': HomePage.browseSubpage}),
      label: t.home.tabs.browse,
      icon: const AdaptiveIcon(
        icon: Icons.folder,
        cupertinoIcon: CupertinoIcons.folder_fill,
      ),
    ),
    _Route(
      routePath: _homeFunction({'subpage': HomePage.calendarSubpage}),
      label: t.home.tabs.calendar,
      icon: const AdaptiveIcon(
        icon: Icons.calendar_month,
        cupertinoIcon: CupertinoIcons.calendar,
      ),
    ),
    _Route(
      routePath: _homeFunction({'subpage': HomePage.whiteboardSubpage}),
      label: t.home.tabs.whiteboard,
      icon: const AdaptiveIcon(
        icon: Icons.draw,
        cupertinoIcon: CupertinoIcons.pencil_outline,
      ),
    ),
    _Route(
      routePath: _homeFunction({'subpage': HomePage.projectsSubpage}),
      label: 'Projects',
      icon: const AdaptiveIcon(
        icon: Icons.work,
        cupertinoIcon: CupertinoIcons.briefcase_fill,
      ),
    ),
    _Route(
      routePath: _homeFunction({'subpage': HomePage.settingsSubpage}),
      label: t.home.tabs.settings,
      icon: const AdaptiveIcon(
        icon: Icons.settings,
        cupertinoIcon: CupertinoIcons.settings_solid,
      ),
    ),
  ];

  static String getRoute(int index) {
    return _routes[index].routePath;
  }

  static List<NavigationDestination> get navigationDestinations =>
      _routes.map((e) => e.toNavigationDestination()).toList(growable: false);
  static List<NavigationRailDestination> get navigationRailDestinations =>
      _routes
          .map((e) => e.toNavigationRailDestination())
          .toList(growable: false);
}

class _Route {
  final String routePath;
  final String label;
  final Widget icon;

  _Route({required this.routePath, required this.label, required this.icon});

  NavigationDestination toNavigationDestination() =>
      NavigationDestination(label: label, icon: icon);
  NavigationRailDestination toNavigationRailDestination() =>
      NavigationRailDestination(label: Text(label), icon: icon);
}

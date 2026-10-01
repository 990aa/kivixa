import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/navbar/horizontal_navbar.dart';
import 'package:kivixa/components/navbar/vertical_navbar.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:stow_codecs/stow_codecs.dart';

class ResponsiveNavbar extends StatefulWidget {
  const ResponsiveNavbar({
    super.key,
    required this.body,
    this.selectedIndex = 0,
  });

  final Widget body;
  final int selectedIndex;

  @override
  State<ResponsiveNavbar> createState() => _ResponsiveNavbarState();

  static var isLargeScreen = true;
}

class _ResponsiveNavbarState extends State<ResponsiveNavbar> {
  @override
  void initState() {
    stows.layoutSize.addListener(onChange);
    super.initState();
  }

  void onChange() {
    setState(() {});
  }

  void onDestinationSelected(int index) {
    if (index == widget.selectedIndex) return;

    context.go(HomeRoutes.getRoute(index));
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveNavbar.isLargeScreen = switch (stows.layoutSize.value) {
      LayoutSize.auto => MediaQuery.sizeOf(context).width >= 600,
      LayoutSize.phone => false,
      LayoutSize.tablet => true,
    };

    if (ResponsiveNavbar.isLargeScreen) {
      return Scaffold(
        body: Row(
          children: [
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: VerticalNavbar(
                  destinations: HomeRoutes.navigationRailDestinations,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                ),
              ),
            ),
            Expanded(child: widget.body),
          ],
        ),
      );
    } // else mobile

    return Scaffold(
      body: widget.body,
      bottomNavigationBar: HorizontalNavbar(
        destinations: HomeRoutes.navigationDestinations,
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }

  @override
  void dispose() {
    stows.layoutSize.removeListener(onChange);
    super.dispose();
  }
}

enum LayoutSize {
  auto,
  phone,
  tablet;

  static const codec = EnumCodec(values);
}

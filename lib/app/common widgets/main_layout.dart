import 'package:flutter/material.dart';
import '../Utilities/responsive.dart';
import 'sidebar_widget.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed Sidebar - stays the same across all pages
          if (!Responsive.isMobile(context)) const SidebarWidget(),

          // Content Area - changes based on navigation
          Expanded(child: child),
        ],
      ),
      // Mobile drawer
      drawer: Responsive.isMobile(context)
          ? const Drawer(child: SidebarWidget())
          : null,
    );
  }
}

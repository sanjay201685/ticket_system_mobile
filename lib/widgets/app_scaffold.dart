import 'package:flutter/material.dart';
import 'app_drawer.dart';

/// A reusable scaffold widget that includes AppBar and Drawer on all pages
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;
  final Color? backgroundColor;
  final FloatingActionButton? floatingActionButton;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showDrawer = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: actions,
      ),
      drawer: showDrawer ? const AppDrawer() : null,
      backgroundColor: backgroundColor,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

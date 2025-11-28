import 'package:flutter/material.dart';
import 'package:ticket_system/utils/route_loader.dart';

/// Example of using automatic route loading (Node.js style)
void main() {
  runApp(const AutoRouteApp());
}

class AutoRouteApp extends StatelessWidget {
  const AutoRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket System - Auto Routes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Automatic route generation
      onGenerateRoute: (settings) {
        final route = RouteLoader.loadRoute(settings.name ?? '/');
        if (route != null) {
          return MaterialPageRoute(
            builder: (context) => route,
            settings: settings,
          );
        }
        return null;
      },
      // Fallback route
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => RouteLoader.loadRoute('/')!,
        );
      },
    );
  }
}



















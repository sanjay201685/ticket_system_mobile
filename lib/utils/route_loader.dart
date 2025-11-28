import 'package:flutter/material.dart';
import 'package:ticket_system/screens/login_screen.dart';
import 'package:ticket_system/screens/home_screen.dart';

/// Automatic route loader - similar to Node.js Express routing
class RouteLoader {
  static final Map<String, Widget Function()> _routes = {
    '/': () => const LoginScreen(),
    '/login': () => const LoginScreen(),
    '/home': () => const HomeScreen(),
    '/dashboard': () => const HomeScreen(), // Alias
  };

  /// Automatically load route based on path
  static Widget? loadRoute(String path) {
    // Remove query parameters and fragments
    final cleanPath = path.split('?')[0].split('#')[0];
    
    // Direct match
    if (_routes.containsKey(cleanPath)) {
      return _routes[cleanPath]!();
    }
    
    // Pattern matching (like Express.js)
    for (final route in _routes.keys) {
      if (_matchesPattern(route, cleanPath)) {
        return _routes[route]!();
      }
    }
    
    // Default fallback
    return _routes['/']!();
  }

  /// Check if path matches route pattern
  static bool _matchesPattern(String pattern, String path) {
    // Simple pattern matching (you can extend this)
    if (pattern.contains('*')) {
      final regexPattern = pattern.replaceAll('*', '.*');
      return RegExp('^$regexPattern\$').hasMatch(path);
    }
    return false;
  }

  /// Get all available routes
  static List<String> get availableRoutes => _routes.keys.toList();

  /// Register a new route dynamically
  static void registerRoute(String path, Widget Function() builder) {
    _routes[path] = builder;
  }
}



















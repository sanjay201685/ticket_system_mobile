import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ticket_system/screens/login_screen.dart';
import 'package:ticket_system/screens/home_screen.dart';

/// File-based auto routing - scans lib/pages directory for automatic route generation
/// Similar to Next.js or Nuxt.js file-based routing
class FileRouter {
  static final Map<String, Widget Function()> _routes = {};
  static bool _initialized = false;

  /// Initialize file-based routing
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Scan lib/pages directory for Dart files
    final pagesDir = Directory('lib/pages');
    if (await pagesDir.exists()) {
      await _scanDirectory(pagesDir);
    }
    
    _initialized = true;
  }

  /// Scan directory for page files
  static Future<void> _scanDirectory(Directory dir) async {
    final entities = await dir.list().toList();
    
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _processPageFile(entity);
      } else if (entity is Directory) {
        await _scanDirectory(entity);
      }
    }
  }

  /// Process individual page file
  static Future<void> _processPageFile(File file) async {
    final relativePath = path.relative(file.path, from: 'lib/pages');
    final routePath = _filePathToRoute(relativePath);
    
    // Register route (in real implementation, you'd use reflection or code generation)
    print('Auto-discovered route: $routePath -> ${file.path}');
    
    // Example: Register based on file name
    if (relativePath.contains('login')) {
      _routes[routePath] = () => const LoginScreen();
    } else if (relativePath.contains('home')) {
      _routes[routePath] = () => const HomeScreen();
    }
  }

  /// Convert file path to route path
  static String _filePathToRoute(String filePath) {
    // Remove .dart extension
    String route = filePath.replaceAll('.dart', '');
    
    // Convert to URL format
    route = route.replaceAll('\\', '/');
    
    // Handle index files
    if (route.endsWith('/index')) {
      route = route.substring(0, route.length - 6);
    }
    
    // Ensure starts with /
    if (!route.startsWith('/')) {
      route = '/$route';
    }
    
    return route;
  }

  /// Get route for path
  static Widget? getRoute(String path) {
    return _routes[path]?.call();
  }

  /// Get all registered routes
  static Map<String, Widget Function()> get routes => Map.unmodifiable(_routes);
}

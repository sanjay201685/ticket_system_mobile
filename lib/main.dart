import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ticket_system/screens/login_screen.dart';
import 'package:ticket_system/screens/dashboard_screen.dart';
import 'package:ticket_system/services/auth_service.dart';
import 'package:ticket_system/providers/master_provider.dart';
import 'package:ticket_system/providers/purchase_request_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => MasterProvider()),
        ChangeNotifierProvider(create: (context) => PurchaseRequestProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check authentication status when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authService.isAuthenticated) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}


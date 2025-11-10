import 'package:auto_route/auto_route.dart';
import 'package:ticket_system/screens/login_screen.dart';
import 'package:ticket_system/screens/home_screen.dart';

// Auto-generated routes will be created here
// Run: flutter packages pub run build_runner build
@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    // Automatic route detection based on file structure
    AutoRoute(
      page: LoginRoute.page,
      path: '/login',
      initial: true,
    ),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
    ),
  ];
}

// Auto-generated route classes (will be created by build_runner)
@RoutePage()
class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}

@RoutePage()
class HomeRoute extends StatelessWidget {
  const HomeRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}














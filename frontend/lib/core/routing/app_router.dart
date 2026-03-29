import 'package:flutter/material.dart';

import '../../app_controller.dart';
import '../../app_scope.dart';
import '../../data/models/user.dart';
import '../../features/auth/login_screen.dart';
import '../../features/client/client_home_screen.dart';
import '../../features/franchisee/franchisee_home_screen.dart';
import '../../features/production/production_home_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AppController controller,
  ) {
    final name = settings.name ?? RouteNames.login;
    final isLoggedIn = controller.session != null;

    if (!isLoggedIn && name != RouteNames.login) {
      return _page(const LoginScreen());
    }

    switch (name) {
      case RouteNames.login:
        return _page(
          isLoggedIn ? const _RoleGateScreen() : const LoginScreen(),
        );
      case RouteNames.roleGate:
        return _page(const _RoleGateScreen());
      case RouteNames.client:
        return _page(
          controller.currentUser?.role == UserRole.client
              ? const ClientHomeScreen()
              : const _RoleGateScreen(),
        );
      case RouteNames.franchisee:
        return _page(
          controller.currentUser?.role == UserRole.franchisee
              ? const FranchiseeHomeScreen()
              : const _RoleGateScreen(),
        );
      case RouteNames.production:
        return _page(
          controller.currentUser?.role == UserRole.production
              ? const ProductionHomeScreen()
              : const _RoleGateScreen(),
        );
      default:
        return _page(const LoginScreen());
    }
  }

  static String homeForRole(UserRole role) {
    switch (role) {
      case UserRole.client:
        return RouteNames.client;
      case UserRole.franchisee:
        return RouteNames.franchisee;
      case UserRole.production:
        return RouteNames.production;
    }
  }

  static MaterialPageRoute<dynamic> _page(Widget child) {
    return MaterialPageRoute<dynamic>(builder: (_) => child);
  }
}

class _RoleGateScreen extends StatelessWidget {
  const _RoleGateScreen();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.login,
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homeForRole(user.role),
        (route) => false,
      );
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_scope.dart';
import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/theme/app_theme.dart';

class AvishuAppBootstrap extends StatefulWidget {
  const AvishuAppBootstrap({super.key});

  @override
  State<AvishuAppBootstrap> createState() => _AvishuAppBootstrapState();
}

class _AvishuAppBootstrapState extends State<AvishuAppBootstrap> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(config: AppConfig.fromEnvironment());
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'AVISHU',
            theme: buildAppTheme(),
            initialRoute: RouteNames.login,
            onGenerateRoute: (settings) =>
                AppRouter.onGenerateRoute(settings, _controller),
          );
        },
      ),
    );
  }
}

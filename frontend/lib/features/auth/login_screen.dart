import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_button.dart';
import 'demo_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();

  static const _presets = [
    ('Клиент', 'client@avishu.app'),
    ('Франчайзи', 'franchisee@avishu.app'),
    ('Производство', 'production@avishu.app'),
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'client@avishu.app');
    _passwordController = TextEditingController(text: 'demo123');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = AppScope.of(context);
    final success = await controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.roleGate,
      (route) => false,
    );
  }

  void _applyPreset(String email) {
    _emailController.text = email;
    _passwordController.text = 'demo123';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: DemoBanner(
                  visible: controller.isUsingMock,
                  message: controller.modeMessage ?? 'Включен демо-режим',
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AVISHU',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: const Color(0xFFF5E39B),
                              letterSpacing: 2.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Суперапп',
                            style: theme.textTheme.displayLarge,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Премиальный рабочий поток для клиента, франчайзи и производства. Построен строго по контракту.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                          ),
                          const SizedBox(height: 28),
                          GlassPanel(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'БЫСТРЫЙ ВЫБОР РОЛИ',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.78),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _presets.map((preset) {
                                      final isSelected =
                                          _emailController.text.trim() == preset.$2;
                                      return _RolePresetChip(
                                        label: preset.$1,
                                        selected: isSelected,
                                        onTap: () => _applyPreset(preset.$2),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 22),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Почта',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Введите почту';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Пароль',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Введите пароль';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Без бэка включите демо-режим и войдите как client@avishu.app, franchisee@avishu.app или production@avishu.app. Пароль: demo123.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.62),
                                    ),
                                  ),
                                  if (controller.authError != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      controller.authError!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFFE8B4B4),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  PrimaryButton(
                                    label: controller.isAuthenticating
                                        ? 'Вход...'
                                        : 'Войти',
                                    onPressed: controller.isAuthenticating
                                        ? null
                                        : _submit,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePresetChip extends StatelessWidget {
  const _RolePresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF5E39B)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFF5E39B)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.black : Colors.white,
                fontSize: 11,
              ),
        ),
      ),
    );
  }
}

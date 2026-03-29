import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/routing/route_names.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLeaving = false;
  late String _selectedAccessKey;

  static const _clientPreset = ('Клиент', 'client@avishu.com');
  static const _franchisePreset = ('Франчайзи', 'franchisee@avishu.com');
  static const _workerManualAccess = '__production_worker__';
  static const _productionPresets = [
    ('Менеджер', 'production.manager@avishu.com'),
    ('Сотрудник', _workerManualAccess),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccessKey = _clientPreset.$2;
    _emailController = TextEditingController(text: _clientPreset.$2);
    _passwordController = TextEditingController(text: 'demo123');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = AppScope.of(context);
    final success = await controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted || !success) {
      return;
    }

    setState(() => _isLeaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 140));

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushNamedAndRemoveUntil(RouteNames.roleGate, (route) => false);
  }

  void _applyPreset(String accessKey) {
    _selectedAccessKey = accessKey;
    if (accessKey == _workerManualAccess) {
      _emailController.text = '1@gmail.com';
      _passwordController.text = 'demo123';
    } else {
      _emailController.text = accessKey;
      _passwordController.text = 'demo123';
    }
    setState(() {});
  }

  Future<void> _showRegisterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RegisterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final selectedAccessKey = _selectedAccessKey;
    final isProductionWorkerLogin = selectedAccessKey == _workerManualAccess;
    final showRegisterAction =
        selectedAccessKey == _clientPreset.$2 && !controller.isUsingMock;
    final canSubmit = !isProductionWorkerLogin ||
        (_emailController.text.trim().isNotEmpty &&
            _passwordController.text.trim().isNotEmpty);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 420;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _isLeaving ? 0 : 1,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? double.infinity : 520,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AVISHU',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: 2.8,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Вход в систему',
                                    style: isCompact
                                        ? theme.textTheme.headlineLarge
                                        : theme.textTheme.displayMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Продажи, франшиза и производство в одном приложении.',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isCompact ? 16 : 24),
                            GlassPanel(
                              padding: EdgeInsets.fromLTRB(
                                isCompact ? 18 : 24,
                                isCompact ? 18 : 24,
                                isCompact ? 18 : 24,
                                isCompact ? 18 : 24,
                              ),
                              borderRadius: isCompact ? 18 : 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ДОСТУП',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _RoleGroup(
                                    title: 'Клиент',
                                    subtitle: 'Заказ и статус',
                                    presets: const [_clientPreset],
                                    selectedEmail: selectedAccessKey,
                                    onSelect: _applyPreset,
                                  ),
                                  const SizedBox(height: 18),
                                  _RoleGroup(
                                    title: 'Франчайзи',
                                    subtitle: 'Подтверждение',
                                    presets: const [_franchisePreset],
                                    selectedEmail: selectedAccessKey,
                                    onSelect: _applyPreset,
                                  ),
                                  const SizedBox(height: 18),
                                  _RoleGroup(
                                    title: 'Производство',
                                    subtitle: 'Менеджер и сотрудник',
                                    presets: _productionPresets,
                                    selectedEmail: selectedAccessKey,
                                    onSelect: _applyPreset,
                                  ),
                                  const SizedBox(height: 18),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: _RoleShowcase(
                                      key: ValueKey(selectedAccessKey),
                                      email: selectedAccessKey,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    _selectedRoleTitle(selectedAccessKey),
                                    style: theme.textTheme.headlineLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isProductionWorkerLogin
                                        ? 'Введите личные данные швеи.'
                                        : 'Один шаг до входа.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isProductionWorkerLogin) ...[
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Почта швеи',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Пароль',
                                      ),
                                    ),
                                  ],
                                  if (controller.authError != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      child: Text(
                                        _presentableAuthError(
                                            controller.authError!),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  _LoginActionButton(
                                    label: controller.isAuthenticating
                                        ? 'Вход...'
                                        : 'Войти',
                                    onPressed: controller.isAuthenticating ||
                                            !canSubmit
                                        ? null
                                        : _submit,
                                  ),
                                  if (showRegisterAction) ...[
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: PrimaryButton(
                                        label: 'Регистрация клиента',
                                        isGhost: true,
                                        isExpanded: false,
                                        minHeight: 38,
                                        fontSize: 10,
                                        onPressed: controller.isAuthenticating
                                            ? null
                                            : () => _showRegisterSheet(context),
                                      ),
                                    ),
                                  ],
                                ],
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
      ),
    );
  }
}

class _RoleShowcase extends StatelessWidget {
  const _RoleShowcase({
    super.key,
    required this.email,
  });

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 420;

    final description = switch (email) {
      'franchisee@avishu.com' => 'Подтверждение заказов.',
      'production.manager@avishu.com' => 'Очередь и назначения.',
      _LoginScreenState._workerManualAccess => 'Личные задачи швеи.',
      _ => 'Заказ и отслеживание.',
    };

    final title = switch (email) {
      'franchisee@avishu.com' => 'Франчайзи',
      'production.manager@avishu.com' => 'Менеджер цеха',
      _LoginScreenState._workerManualAccess => 'Сотрудник',
      _ => 'Клиент',
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: selected ? 1 : 0.98,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: selected ? 1 : 0.86,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleGroup extends StatelessWidget {
  const _RoleGroup({
    required this.title,
    required this.subtitle,
    required this.presets,
    required this.selectedEmail,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<(String, String)> presets;
  final String selectedEmail;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: isCompact ? 12 : 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            return _RolePresetChip(
              label: preset.$1,
              selected: selectedEmail == preset.$2,
              onTap: () => onSelect(preset.$2),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LoginActionButton extends StatefulWidget {
  const _LoginActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_LoginActionButton> createState() => _LoginActionButtonState();
}

class _LoginActionButtonState extends State<_LoginActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onPressed == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: PrimaryButton(
          label: widget.label,
          minHeight: 64,
          fontSize: 14,
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

String _selectedRoleTitle(String email) {
  switch (email) {
    case 'franchisee@avishu.com':
      return 'Франчайзи';
    case 'production.manager@avishu.com':
      return 'Менеджер цеха';
    case _LoginScreenState._workerManualAccess:
      return 'Сотрудник';
    default:
      return 'Клиент';
  }
}

String _presentableAuthError(String error) {
  final lower = error.toLowerCase();

  if (lower.contains('connection refused') ||
      lower.contains('socketexception') ||
      lower.contains('failed host lookup')) {
    return 'Нет соединения с сервером.';
  }

  if (lower.contains('401') ||
      lower.contains('invalid login') ||
      lower.contains('invalid credentials') ||
      lower.contains('невер')) {
    return 'Неверные данные для входа.';
  }

  return 'Не удалось выполнить вход.';
}

class _RegisterSheet extends StatefulWidget {
  const _RegisterSheet();

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = AppScope.of(context);
    final success = await controller.registerClient(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pop();
    Navigator.of(context)
        .pushNamedAndRemoveUntil(RouteNames.roleGate, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassPanel(
        backgroundColor: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'РЕГИСТРАЦИЯ КЛИЕНТА',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Создайте личный аккаунт клиента.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Имя'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Почта'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите почту';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
                validator: (value) {
                  if (value == null || value.trim().length < 6) {
                    return 'Минимум 6 символов';
                  }
                  return null;
                },
              ),
              if (controller.registerError != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.registerError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(
                label: controller.isRegistering
                    ? 'Создание...'
                    : 'Создать аккаунт',
                onPressed: controller.isRegistering ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app_controller.dart';
import '../../app_scope.dart';
import '../../core/utils/display_text.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/role_shell_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/models/user.dart';
import '../auth/demo_banner.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final user = controller.currentUser;

    if (user == null) {
      return const _SessionFallbackScreen();
    }

    return RoleShellScaffold(
      user: user,
      roleTitle: 'Клиент',
      currentIndex: _currentTab,
      onTabSelected: (index) => setState(() => _currentTab = index),
      onLogout: () {
        controller.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      banner: DemoBanner(
        visible: controller.isUsingMock,
        message: controller.modeMessage ?? 'Включен демо-режим',
      ),
      headerAction: _HeaderRefreshButton(
        onTap: () => controller.refreshForCurrentRole(),
      ),
      child: _buildTab(context, controller, user),
    );
  }

  Widget _buildTab(
    BuildContext context,
    AppController controller,
    User user,
  ) {
    switch (_currentTab) {
      case 1:
        return _ProfileTab(
          fullName: user.fullName,
          email: user.email,
          role: user.role.value,
          franchiseId: user.franchiseId ?? '-',
          createdAt: user.createdAt,
        );
      case 2:
        return _SettingsTab(
          isUsingMock: controller.isUsingMock,
          modeMessage: controller.modeMessage,
          apiBaseUrl: controller.config.apiBaseUrl,
          syncIntervalSeconds: controller.config.syncIntervalSeconds,
        );
      default:
        return _HomeTab(controller: controller);
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final orders = controller.clientOrders;
    final latestStatus = orders.isEmpty ? 'placed' : orders.first.status;

    return RefreshIndicator(
      color: const Color(0xFFF5E39B),
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _ClientSummaryCard(
            productsCount: controller.products.length,
            ordersCount: orders.length,
            latestStatus: latestStatus,
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Товары',
            trailing: Text(
              '${controller.products.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFF5E39B),
                  ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.isProductsLoading && controller.products.isEmpty)
            const SizedBox(
              height: 220,
              child: LoadingStateView(message: 'Загрузка товаров'),
            )
          else if (controller.clientError != null && controller.products.isEmpty)
            SizedBox(
              height: 220,
              child: ErrorStateView(
                message: controller.clientError!,
                onRetry: () => controller.refreshForCurrentRole(),
              ),
            )
          else if (controller.products.isEmpty)
            const SizedBox(
              height: 220,
              child: EmptyStateView(
                title: 'Товаров пока нет',
                description: 'Товары появятся здесь, как только станут доступны.',
              ),
            )
          else
            ...controller.products.map<Widget>(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ProductCard(product: product),
              ),
            ),
          const SizedBox(height: 12),
          SectionHeader(
            title: 'Мои заказы',
            trailing: Text(
              '${orders.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFF5E39B),
                  ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.isClientOrdersLoading && orders.isEmpty)
            const SizedBox(
              height: 220,
              child: LoadingStateView(message: 'Загрузка заказов'),
            )
          else if (controller.clientError != null && orders.isEmpty)
            SizedBox(
              height: 220,
              child: ErrorStateView(
                message: controller.clientError!,
                onRetry: () => controller.refreshForCurrentRole(),
              ),
            )
          else if (orders.isEmpty)
            const SizedBox(
              height: 220,
              child: EmptyStateView(
                title: 'Заказов пока нет',
                description: 'Создайте первый заказ, чтобы запустить демо-сценарий.',
              ),
            )
          else
            ...orders.map<Widget>(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _OrderCard(order: order),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientSummaryCard extends StatelessWidget {
  const _ClientSummaryCard({
    required this.productsCount,
    required this.ordersCount,
    required this.latestStatus,
  });

  final int productsCount;
  final int ordersCount;
  final String latestStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'СТУДИЯ ЗАКАЗА',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFFF5E39B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Создайте заказ и наблюдайте, как статус проходит по цепочке франшизы в реальном времени.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$productsCount',
                  label: 'Товары',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: '$ordersCount',
                  label: 'Заказы',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: statusLabel(latestStatus).toUpperCase(),
                  label: 'Статус',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.64),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${product.price} ${product.currency}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFF5E39B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatusChip(status: product.availabilityType),
              const SizedBox(width: 10),
              Text(
                '${product.defaultReadyDays} дн.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: controller.createOrderProductId == product.id
                ? 'Создание...'
                : 'Создать заказ',
            onPressed: controller.createOrderProductId == product.id
                ? null
                : () => _showCreateOrderSheet(context, product),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateOrderSheet(BuildContext context, Product product) async {
    final outerContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateOrderSheet(product: product, outerContext: outerContext);
      },
    );
  }
}

class _CreateOrderSheet extends StatefulWidget {
  const _CreateOrderSheet({
    required this.product,
    required this.outerContext,
  });

  final Product product;
  final BuildContext outerContext;

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _dateController;
  late final DateTime _now;
  late final DateTime _initialDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _now = DateTime.now();
    _initialDate = _now.add(Duration(days: widget.product.defaultReadyDays));
    _dateController = TextEditingController(
      text: _formatOrderDate(_initialDate),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassPanel(
        backgroundColor: const Color(0xFF141414).withValues(alpha: 0.92),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.title,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'ТИП ЗАКАЗА: ${statusLabel(widget.product.availabilityType).toUpperCase()}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFF5E39B),
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Количество',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Дата готовности',
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: controller.createOrderProductId == widget.product.id
                    ? 'Создание...'
                    : 'Подтвердить заказ',
                onPressed: controller.createOrderProductId == widget.product.id
                    ? null
                    : () => _confirm(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _initialDate,
      firstDate: _now,
      lastDate: _now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      _dateController.text = _formatOrderDate(picked);
    });
  }

  Future<void> _confirm(BuildContext context) async {
    final controller = AppScope.of(context);
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;

    await controller.createOrder(
      product: widget.product,
      quantity: quantity,
      selectedReadyDate: _dateController.text.trim(),
    );

    if (!mounted || !widget.outerContext.mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(widget.outerContext).showSnackBar(
      const SnackBar(content: Text('Заказ создан')),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          _MetaRow(label: 'quantity', value: '${order.quantity}'),
          _MetaRow(label: 'order_type', value: statusLabel(order.orderType)),
          _MetaRow(label: 'tracking_stage', value: statusLabel(order.trackingStage)),
          _MetaRow(label: 'ready_date', value: order.selectedReadyDate),
          _MetaRow(label: 'created_at', value: order.createdAt),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.fullName,
    required this.email,
    required this.role,
    required this.franchiseId,
    required this.createdAt,
  });

  final String fullName;
  final String email;
  final String role;
  final String franchiseId;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ПРОФИЛЬ', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 18),
              _MetaRow(label: 'full_name', value: fullName),
              _MetaRow(label: 'email', value: email),
              _MetaRow(label: 'role', value: roleValueLabel(role)),
              _MetaRow(label: 'franchise_id', value: franchiseId),
              _MetaRow(label: 'created_at', value: createdAt),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.isUsingMock,
    required this.modeMessage,
    required this.apiBaseUrl,
    required this.syncIntervalSeconds,
  });

  final bool isUsingMock;
  final String? modeMessage;
  final String apiBaseUrl;
  final int syncIntervalSeconds;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('НАСТРОЙКИ', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 18),
              _MetaRow(label: 'mode', value: modeLabel(isUsingMock)),
              _MetaRow(label: 'api_base_url', value: apiBaseUrl),
              _MetaRow(
                label: 'sync_interval_seconds',
                value: '$syncIntervalSeconds',
              ),
              if (modeMessage != null) _MetaRow(label: 'message', value: modeMessage!),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Text(
            'Чтобы посмотреть интерфейс без бэка, запустите приложение с USE_MOCK=true и войдите как client@avishu.app, franchisee@avishu.app или production@avishu.app. Пароль: demo123.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
          ),
        ),
      ],
    );
  }
}

class _HeaderRefreshButton extends StatelessWidget {
  const _HeaderRefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFF5E39B),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              fieldLabel(label).toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionFallbackScreen extends StatelessWidget {
  const _SessionFallbackScreen();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });

    return const Scaffold(
      body: LoadingStateView(message: 'Восстановление сессии'),
    );
  }
}

String _formatOrderDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

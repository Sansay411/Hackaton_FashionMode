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
import '../../data/models/user.dart';
import '../auth/demo_banner.dart';

class FranchiseeHomeScreen extends StatefulWidget {
  const FranchiseeHomeScreen({super.key});

  @override
  State<FranchiseeHomeScreen> createState() => _FranchiseeHomeScreenState();
}

class _FranchiseeHomeScreenState extends State<FranchiseeHomeScreen> {
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
      roleTitle: 'Франчайзи',
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
        return _ProfileTab(user: user);
      case 2:
        return _SettingsTab(controller: controller);
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
    final orders = controller.franchiseeOrders;
    final placedCount = orders.where((item) => item.status == 'placed').length;
    final activeCount = orders
        .where((item) => item.status == 'accepted' || item.status == 'in_production')
        .length;

    return RefreshIndicator(
      color: const Color(0xFFF5E39B),
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _QueueSummaryCard(
            totalOrders: orders.length,
            placedCount: placedCount,
            activeCount: activeCount,
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Новые заказы',
            trailing: Text(
              '${orders.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFF5E39B),
                  ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.isFranchiseeOrdersLoading && orders.isEmpty)
            const SizedBox(
              height: 240,
              child: LoadingStateView(message: 'Загрузка заказов'),
            )
          else if (controller.franchiseeError != null && orders.isEmpty)
            SizedBox(
              height: 240,
              child: ErrorStateView(
                message: controller.franchiseeError!,
                onRetry: () => controller.refreshForCurrentRole(),
              ),
            )
          else if (orders.isEmpty)
            const SizedBox(
              height: 240,
              child: EmptyStateView(
                title: 'Заказов пока нет',
                description: 'Новые клиентские заказы появятся здесь.',
              ),
            )
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _FranchiseOrderCard(order: order),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueSummaryCard extends StatelessWidget {
  const _QueueSummaryCard({
    required this.totalOrders,
    required this.placedCount,
    required this.activeCount,
  });

  final int totalOrders;
  final int placedCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ОЧЕРЕДЬ ФРАНШИЗЫ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFF5E39B),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Принимайте клиентские заказы и передавайте их в производство, не меняя контрактную цепочку статусов.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatTile(value: '$totalOrders', label: 'Всего')),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(value: '$placedCount', label: 'Новые')),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(value: '$activeCount', label: 'В работе')),
            ],
          ),
        ],
      ),
    );
  }
}

class _FranchiseOrderCard extends StatelessWidget {
  const _FranchiseOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
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
          _InfoLine(label: 'order_id', value: order.id),
          _InfoLine(label: 'client_id', value: order.clientId),
          _InfoLine(label: 'quantity', value: '${order.quantity}'),
          _InfoLine(label: 'ready_date', value: order.selectedReadyDate),
          _InfoLine(label: 'tracking_stage', value: statusLabel(order.trackingStage)),
          const SizedBox(height: 20),
          if (order.status == 'placed')
            PrimaryButton(
              label: controller.orderActionId == order.id ? 'Обновление...' : 'Принять',
              onPressed: controller.orderActionId == order.id
                  ? null
                  : () => controller.updateOrderStatus(order, 'accepted'),
            )
          else if (order.status == 'accepted')
            PrimaryButton(
              label: controller.orderActionId == order.id
                  ? 'Обновление...'
                  : 'Передать в производство',
              onPressed: controller.orderActionId == order.id
                  ? null
                  : () => controller.updateOrderStatus(order, 'in_production'),
            )
          else
            Text(
              order.status == 'ready'
                  ? 'Заказ завершен и готов для клиента.'
                  : 'Заказ уже находится в производстве.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.64),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});

  final User user;

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
              _InfoLine(label: 'full_name', value: user.fullName),
              _InfoLine(label: 'email', value: user.email),
              _InfoLine(label: 'role', value: roleValueLabel(user.role.value)),
              _InfoLine(label: 'franchise_id', value: user.franchiseId ?? '-'),
              _InfoLine(label: 'created_at', value: user.createdAt),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.controller});

  final AppController controller;

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
              _InfoLine(
                label: 'mode',
                value: modeLabel(controller.isUsingMock),
              ),
              _InfoLine(label: 'api_base_url', value: controller.config.apiBaseUrl),
              _InfoLine(
                label: 'sync_interval_seconds',
                value: '${controller.config.syncIntervalSeconds}',
              ),
              if (controller.modeMessage != null)
                _InfoLine(label: 'message', value: controller.modeMessage!),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Text(
            'Без бэка используйте USE_MOCK=true и войдите как franchisee@avishu.app с паролем demo123. Клиент и производство доступны на том же экране входа.',
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
          Expanded(child: Text(value)),
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

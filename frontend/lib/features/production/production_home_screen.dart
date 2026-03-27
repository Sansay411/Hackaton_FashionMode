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
import '../../data/models/production_task.dart';
import '../../data/models/user.dart';
import '../auth/demo_banner.dart';

class ProductionHomeScreen extends StatefulWidget {
  const ProductionHomeScreen({super.key});

  @override
  State<ProductionHomeScreen> createState() => _ProductionHomeScreenState();
}

class _ProductionHomeScreenState extends State<ProductionHomeScreen> {
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
      roleTitle: 'Производство',
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
    final tasks = controller.productionTasks;
    final activeCount = tasks.where((item) => item.status == 'active').length;
    final completedCount =
        tasks.where((item) => item.status == 'completed').length;

    return RefreshIndicator(
      color: const Color(0xFFF5E39B),
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          _ProductionSummaryCard(
            totalTasks: tasks.length,
            activeCount: activeCount,
            completedCount: completedCount,
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Очередь производства',
            trailing: Text(
              '${tasks.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFF5E39B),
                  ),
            ),
          ),
          const SizedBox(height: 14),
          if (controller.isProductionTasksLoading && tasks.isEmpty)
            const SizedBox(
              height: 260,
              child: LoadingStateView(message: 'Загрузка задач'),
            )
          else if (controller.productionError != null && tasks.isEmpty)
            SizedBox(
              height: 260,
              child: ErrorStateView(
                message: controller.productionError!,
                onRetry: () => controller.refreshForCurrentRole(),
              ),
            )
          else if (tasks.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyStateView(
                title: 'Задач пока нет',
                description: 'Новые производственные задачи появятся здесь.',
              ),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TaskCard(task: task),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductionSummaryCard extends StatelessWidget {
  const _ProductionSummaryCard({
    required this.totalTasks,
    required this.activeCount,
    required this.completedCount,
  });

  final int totalTasks;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      backgroundColor: Colors.white.withValues(alpha: 0.09),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ПРОИЗВОДСТВО',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFF5E39B),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Крупные контрастные действия вынесены на первый план для быстрого демо на производстве.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatTile(value: '$totalTasks', label: 'Всего')),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(value: '$activeCount', label: 'Активно')),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(value: '$completedCount', label: 'Готово'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final ProductionTask task;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final isBusy = controller.taskActionId == task.id;
    final canComplete = task.status == 'active';

    return GlassPanel(
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              StatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 14),
          _Line(label: 'task_id', value: task.id),
          _Line(label: 'order_id', value: task.orderId),
          _Line(label: 'operation_stage', value: statusLabel(task.operationStage)),
          _Line(label: 'created_at', value: task.createdAt),
          const SizedBox(height: 24),
          PrimaryButton(
            label: task.status == 'completed'
                ? 'Завершено'
                : task.status == 'queued'
                    ? 'Ожидание франчайзи'
                    : isBusy
                        ? 'Завершение...'
                        : 'Завершить задачу',
            minHeight: 72,
            fontSize: 15,
            onPressed:
                canComplete && !isBusy ? () => controller.completeTask(task) : null,
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
              _Line(label: 'full_name', value: user.fullName),
              _Line(label: 'email', value: user.email),
              _Line(label: 'role', value: roleValueLabel(user.role.value)),
              _Line(label: 'franchise_id', value: user.franchiseId ?? '-'),
              _Line(label: 'created_at', value: user.createdAt),
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
              _Line(
                label: 'mode',
                value: modeLabel(controller.isUsingMock),
              ),
              _Line(label: 'api_base_url', value: controller.config.apiBaseUrl),
              _Line(
                label: 'sync_interval_seconds',
                value: '${controller.config.syncIntervalSeconds}',
              ),
              if (controller.modeMessage != null)
                _Line(label: 'message', value: controller.modeMessage!),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Text(
            'Без бэка используйте USE_MOCK=true и войдите как production@avishu.app с паролем demo123. Так вся демо-цепочка доступна локально.',
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

class _Line extends StatelessWidget {
  const _Line({
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
            width: 126,
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

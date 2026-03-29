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

class FranchiseeHomeScreen extends StatefulWidget {
  const FranchiseeHomeScreen({super.key});

  @override
  State<FranchiseeHomeScreen> createState() => _FranchiseeHomeScreenState();
}

class _FranchiseeHomeScreenState extends State<FranchiseeHomeScreen> {
  int _currentTab = 0;

  static const _tabs = [
    RoleShellTabItem(icon: Icons.home_rounded, label: 'Главная'),
    RoleShellTabItem(icon: Icons.person_outline_rounded, label: 'Профиль'),
    RoleShellTabItem(icon: Icons.tune_rounded, label: 'Настройки'),
  ];

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
      isOnline: controller.isRealtimeConnected,
      currentIndex: _currentTab,
      onTabSelected: (index) => setState(() => _currentTab = index),
      tabs: _tabs,
      onLogout: () {
        controller.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      headerAction: _HeaderRefreshButton(
        onTap: () => controller.refreshForCurrentRole(),
      ),
      child: switch (_currentTab) {
        1 => _ProfileTab(controller: controller, user: user),
        2 => _SettingsTab(controller: controller),
        _ => _HomeTab(controller: controller),
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final orders = controller.franchiseeOrders;
    final productsById = {
      for (final product in controller.products) product.id: product,
    };
    final isCompact = MediaQuery.sizeOf(context).width < 390;
    final colorScheme = Theme.of(context).colorScheme;
    final placed = orders.where((item) => item.status == 'placed').toList();
    final paid = orders.where((item) => item.status == 'paid').toList();
    final accepted = orders.where((item) => item.status == 'accepted').toList();
    final inProduction =
        orders.where((item) => item.status == 'in_production').toList();
    final ready = orders.where((item) => item.status == 'ready').toList();
    final delivered = orders.where((item) => item.status == 'delivered').toList();
    final monetizedOrders = orders
        .where((item) => _countsAsRevenue(item.status))
        .toList();
    final franchiseRevenue = monetizedOrders.fold<double>(
      0,
      (sum, order) => sum + _orderAmount(order, productsById),
    );
    final planProgress =
        orders.isEmpty ? 0 : ((ready.length / orders.length) * 100).round();

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          TextFormField(
            initialValue: controller.franchiseeOrderSearchQuery,
            textCapitalization: TextCapitalization.characters,
            onFieldSubmitted: (value) => controller.setFranchiseeOrderSearchQuery(value),
            decoration: const InputDecoration(
              labelText: 'Поиск по коду заказа',
              hintText: 'AV-20260329-0001',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          _ControlTowerHero(
            totalOrders: orders.length,
            placedCount: paid.length,
            planProgress: planProgress,
            isCompact: isCompact,
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isCompact ? 1 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: isCompact ? 2.8 : 1.8,
            children: [
              _MetricTile(
                title: 'Новые',
                value: '${placed.length}',
                caption: 'ждут оплату',
              ),
              _MetricTile(
                title: 'Выручка',
                value: formatTenge(franchiseRevenue),
                caption: 'после оплаты',
              ),
              _MetricTile(
                title: 'Оплачено',
                value: '${paid.length}',
                caption: 'можно подтвердить',
              ),
              _MetricTile(
                title: 'В цехе',
                value: '${inProduction.length}',
                caption: 'в работе',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (monetizedOrders.isNotEmpty)
            GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ДЕНЬГИ ФРАНЧАЙЗИ',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatTenge(franchiseRevenue),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Оплачено: ${paid.length}  ·  Подтверждено: ${accepted.length}  ·  Завершено: ${ready.length + delivered.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Очередь заказов',
            trailing: Text(
              '${orders.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          if (controller.isFranchiseeOrdersLoading && orders.isEmpty)
            const SizedBox(
              height: 260,
              child: LoadingStateView(message: 'Загрузка заказов'),
            )
          else if (controller.franchiseeError != null && orders.isEmpty)
            SizedBox(
              height: 260,
              child: ErrorStateView(
                message: controller.franchiseeError!,
                onRetry: () => controller.refreshForCurrentRole(),
              ),
            )
          else if (orders.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyStateView(
                title: 'Новых заказов нет',
                description:
                    'Как только клиент оформит заказ, он сразу появится на этом экране.',
              ),
            )
          else ...[
            _KanbanSection(
              title: 'Ждут оплату',
              subtitle: 'Клиент ещё не оплатил',
              orders: placed,
            ),
            const SizedBox(height: 16),
            _KanbanSection(
              title: 'Оплачено',
              subtitle: 'Можно подтверждать',
              orders: paid,
            ),
            const SizedBox(height: 16),
            _KanbanSection(
              title: 'Приняты',
              subtitle: 'Готовы к передаче в цех',
              orders: accepted,
            ),
            const SizedBox(height: 16),
            _KanbanSection(
              title: 'В производстве',
              subtitle: 'Цех выполняет заказ',
              orders: inProduction,
            ),
            const SizedBox(height: 16),
            _KanbanSection(
              title: 'Готово',
              subtitle: 'Завершенные заказы',
              orders: ready,
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlTowerHero extends StatelessWidget {
  const _ControlTowerHero({
    required this.totalOrders,
    required this.placedCount,
    required this.planProgress,
    required this.isCompact,
  });

  final int totalOrders;
  final int placedCount;
  final int planProgress;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassPanel(
      backgroundColor: colorScheme.primary,
      borderColor: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ОПЕРАЦИОННЫЙ ЦЕНТР',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isCompact ? 'Контроль франшизы' : 'Франшиза под контролем',
            style: (isCompact
                    ? theme.textTheme.headlineLarge
                    : theme.textTheme.displayMedium)
                ?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Оплаченные заказы подтверждаются здесь и уходят в цех.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(
                value: '$totalOrders',
                label: 'всего',
                inverse: true,
              ),
              _MiniStat(
                value: '$placedCount',
                label: 'приём',
                inverse: true,
              ),
              _MiniStat(
                value: '$planProgress%',
                label: 'готово',
                inverse: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KanbanSection extends StatelessWidget {
  const _KanbanSection({
    required this.title,
    required this.subtitle,
    required this.orders,
  });

  final String title;
  final String subtitle;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${orders.length}',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
          if (orders.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Пусто',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _FranchiseOrderCard(order: order),
              ),
            ),
          ],
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
    final isBusy = controller.orderActionId == order.id;
    final colorScheme = theme.colorScheme;
    final productsById = {
      for (final product in controller.products) product.id: product,
    };
    final amount = _orderAmount(order, productsById);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(order.productTitle, style: theme.textTheme.titleLarge),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          _OrderFactStrip(
            items: [
              ('Код заказа', _displayOrderCode(order)),
              ('Сумма', formatTenge(amount)),
              ('Клиент', _shortOrderId(order.clientId)),
              ('Количество', '${order.quantity}'),
              ('Готовность', order.selectedReadyDate),
              ('Этап', statusLabel(order.trackingStage)),
            ],
          ),
          const SizedBox(height: 16),
          if (order.status == 'paid')
            PrimaryButton(
              label: isBusy ? 'Подтверждение...' : 'Подтвердить заказ',
              onPressed: isBusy
                  ? null
                  : () => controller.updateOrderStatus(order, 'accepted'),
            )
          else if (order.status == 'placed')
            Text(
              'Ожидаем оплату со стороны клиента.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else if (order.status == 'accepted')
            PrimaryButton(
              label: isBusy ? 'Передача...' : 'Передать в производство',
              onPressed: isBusy
                  ? null
                  : () => controller.updateOrderStatus(order, 'in_production'),
            )
          else
            Text(
              order.status == 'ready'
                  ? 'Заказ уже готов для выдачи клиенту.'
                  : 'Заказ в работе у производства.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.caption,
  });

  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      backgroundColor: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    this.inverse = false,
  });

  final String value;
  final String label;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inverse
            ? colorScheme.onPrimary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inverse
              ? colorScheme.onPrimary.withValues(alpha: 0.12)
              : colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color:
                      inverse ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: inverse
                      ? colorScheme.onPrimary.withValues(alpha: 0.72)
                      : colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _OrderFactStrip extends StatelessWidget {
  const _OrderFactStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 112,
            maxWidth: 156,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(item.$2, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

String _shortOrderId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return value.substring(0, 8).toUpperCase();
}

String _displayOrderCode(Order order) {
  if (order.orderCode.trim().isNotEmpty) {
    return order.orderCode;
  }
  return _shortOrderId(order.id);
}

bool _countsAsRevenue(String status) {
  return {
    'paid',
    'accepted',
    'in_production',
    'ready',
    'delivered',
    'archived',
  }.contains(status);
}

double _orderAmount(Order order, Map<String, Product> productsById) {
  final product = productsById[order.productId];
  if (product == null) {
    return 0;
  }
  final rawPrice = num.tryParse(product.price.toString()) ?? 0;
  return rawPrice.toDouble() * order.quantity;
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.controller,
    required this.user,
  });

  final AppController controller;
  final User user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ПРОФИЛЬ',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  PrimaryButton(
                    label: controller.isProfileSaving
                        ? 'Сохранение...'
                        : 'Изменить имя',
                    isOutlined: true,
                    isExpanded: false,
                    minHeight: 40,
                    fontSize: 10,
                    onPressed: controller.isProfileSaving
                        ? null
                        : () => _showEditProfileDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _InfoLine(label: 'full_name', value: user.fullName),
              _InfoLine(label: 'email', value: user.email),
              _InfoLine(label: 'role', value: roleValueLabel(user.role.value)),
              _InfoLine(label: 'franchise_id', value: user.franchiseId ?? '-'),
              _InfoLine(label: 'created_at', value: user.createdAt),
              if (controller.profileError != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.profileError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final nameController = TextEditingController(text: user.fullName);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          title: Text(
            'Изменить имя',
            style: Theme.of(dialogContext).textTheme.headlineSmall,
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Имя и фамилия'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      await controller.updateProfile(fullName: nameController.text.trim());
    }
    nameController.dispose();
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'НАСТРОЙКИ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _ControlSwitch(
                title: 'Уведомления',
                value: controller.notificationsEnabled,
                onChanged: controller.setNotificationsEnabled,
              ),
              _ControlSwitch(
                title: 'Компактный режим',
                value: controller.compactModeEnabled,
                onChanged: controller.setCompactModeEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlSwitch extends StatelessWidget {
  const _ControlSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: colorScheme.primary,
          activeTrackColor: colorScheme.primary.withValues(alpha: 0.24),
          onChanged: onChanged,
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Icon(
          Icons.sync_rounded,
          color: colorScheme.onSurface,
          size: 20,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              fieldLabel(label).toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
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

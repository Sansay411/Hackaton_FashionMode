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

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentTab = 0;

  static const _tabs = [
    RoleShellTabItem(icon: Icons.grid_view_rounded, label: 'Каталог'),
    RoleShellTabItem(icon: Icons.shopping_bag_outlined, label: 'Корзина'),
    RoleShellTabItem(icon: Icons.receipt_long_rounded, label: 'Заказы'),
    RoleShellTabItem(icon: Icons.person_outline_rounded, label: 'Аккаунт'),
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
      roleTitle: 'Клиент',
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
        1 => _CartTab(controller: controller),
        2 => _OrdersTab(controller: controller),
        3 => _AccountTab(controller: controller, user: user),
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
    final theme = Theme.of(context);
    final products = controller.products;
    final readyProducts = products
        .where((product) => product.availabilityType == 'in_stock')
        .toList();
    final atelierProducts = products
        .where((product) => product.availabilityType != 'in_stock')
        .toList();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 760;

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: isCompact ? 8 : 16),
        children: [
          _CollectionHero(
            productsCount: controller.products.length,
            ordersCount: controller.clientOrders.length,
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 16 : 24),
          const _ClientDiscoveryBar(),
          const SizedBox(height: 24),
          _ClientQuickStats(controller: controller),
          const SizedBox(height: 32),
          SectionHeader(
            title: 'Каталог',
            trailing: Text(
              'Смотреть все',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _CatalogFilterRow(
            totalCount: products.length,
            readyCount: readyProducts.length,
            atelierCount: atelierProducts.length,
          ),
          const SizedBox(height: 16),
          if (controller.isProductsLoading && controller.products.isEmpty)
            const SizedBox(
              height: 240,
              child: LoadingStateView(message: 'Загрузка каталога'),
            )
          else if (controller.clientError != null &&
              controller.products.isEmpty)
            SizedBox(
              height: 240,
              child: ErrorStateView(
                message: controller.clientError!,
                onRetry: () => controller.refreshForCurrentRole(),
              ),
            )
          else if (controller.products.isEmpty)
            const SizedBox(
              height: 240,
              child: EmptyStateView(
                title: 'Каталог пока пуст',
                description: 'Новые модели появятся здесь автоматически.',
              ),
            )
          else
            isCompact
                ? Column(
                    children: [
                      for (var index = 0;
                          index < controller.products.length;
                          index++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == controller.products.length - 1
                                ? 0
                                : 16,
                          ),
                          child: _ProductCard(
                            product: controller.products[index],
                            visualIndex: index,
                            isCompact: true,
                          ),
                        ),
                    ],
                  )
                : GridView.builder(
                    itemCount: controller.products.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.86,
                    ),
                    itemBuilder: (context, index) {
                      final product = controller.products[index];
                      return _ProductCard(
                        product: product,
                        visualIndex: index,
                        isCompact: false,
                      );
                    },
                  ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({
    required this.controller,
    required this.user,
  });

  final AppController controller;
  final User user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _ProfileTab(controller: controller, user: user, embedded: true),
        const SizedBox(height: 16),
        _SettingsTab(controller: controller, embedded: true),
      ],
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final items = controller.cartItems;
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SectionHeader(
          title: 'Корзина',
          trailing: Text(
            '${controller.cartItemsCount}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const SizedBox(
            height: 240,
            child: EmptyStateView(
              title: 'Корзина пока пуста',
              description: 'Добавьте модель из каталога и оформите заказ.',
            ),
          )
        else ...[
          ...items.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CartItemCard(
                product: entry.product,
                quantity: entry.quantity,
                isCompact: isCompact,
              ),
            ),
          ),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Итого',
                  trailing: Text(
                    formatTenge(controller.cartTotal),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Оформить заказ',
                  onPressed: items.isEmpty
                      ? null
                      : () => _showCreateOrderSheet(
                            context,
                            items.first.product,
                            initialQuantity: items.first.quantity,
                          ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Очистить корзину',
                  isGhost: true,
                  onPressed: controller.clearCart,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showCreateOrderSheet(
    BuildContext context,
    Product product, {
    required int initialQuantity,
  }) async {
    final outerContext = context;
    final controller = AppScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateOrderSheet(
          product: product,
          outerContext: outerContext,
          initialQuantity: initialQuantity,
          onSuccess: controller.clearCart,
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final orders = [...controller.clientOrders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final activeOrders = orders.where(_isActiveOrder).toList();
    final completedOrders =
        orders.where((order) => !_isActiveOrder(order)).toList();
    final spotlightOrder =
        completedOrders.isEmpty ? null : completedOrders.first;
    final historyOrders = spotlightOrder == null
        ? completedOrders
        : completedOrders.skip(1).toList();

    return RefreshIndicator(
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          TextFormField(
            initialValue: controller.clientOrderSearchQuery,
            textCapitalization: TextCapitalization.characters,
            onFieldSubmitted: (value) => controller.setClientOrderSearchQuery(value),
            decoration: const InputDecoration(
              labelText: 'Поиск по коду заказа',
              hintText: 'AV-20260329-0001',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Активные заказы',
            trailing: Text(
              '${activeOrders.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 16),
          if (activeOrders.isEmpty)
            const SizedBox(
              height: 220,
              child: EmptyStateView(
                title: 'Активных заказов нет',
                description: 'После оформления они появятся здесь.',
              ),
            )
          else
            ...activeOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ActiveOrderCard(order: order),
              ),
            ),
          if (spotlightOrder != null) ...[
            const SizedBox(height: 24),
            _ReadyOrderSpotlight(order: spotlightOrder),
          ],
          const SizedBox(height: 24),
          SectionHeader(
            title: 'История',
            trailing: Text(
              '${historyOrders.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 16),
          if (historyOrders.isEmpty)
            const SizedBox(
              height: 200,
              child: EmptyStateView(
                title: 'История пуста',
                description: 'Готовые заказы будут храниться здесь.',
              ),
            )
          else
            ...historyOrders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _OrderCard(order: order),
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.productsCount,
    required this.ordersCount,
    required this.isCompact,
  });

  final int productsCount;
  final int ordersCount;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassPanel(
      backgroundColor: colorScheme.primary,
      borderColor: colorScheme.primary,
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'НОВАЯ КОЛЛЕКЦИЯ',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            isCompact ? 'Женская линия AVISHU' : 'Женская одежда\nAVISHU',
            style: (isCompact
                    ? theme.textTheme.headlineLarge
                    : theme.textTheme.displayMedium)
                ?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          SizedBox(height: isCompact ? 8 : 16),
          Text(
            isCompact
                ? 'Каталог и заказы в одном месте.'
                : 'Каталог, заказ и готовность в одном экране.',
            style: (isCompact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)
                ?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: isCompact ? 14 : 24),
          if (isCompact) ...[
            Row(
              children: [
                Expanded(
                  child: _HeroMiniStat(
                    eyebrow: 'Каталог',
                    value: '$productsCount',
                    caption: 'позиций',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMiniStat(
                    eyebrow: 'Заказы',
                    value: '$ordersCount',
                    caption: 'в кабинете',
                  ),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _FeatureTile(
                    eyebrow: 'Каталог',
                    value: '$productsCount',
                    caption: 'активных позиций',
                    inverse: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FeatureTile(
                    eyebrow: 'Заказы',
                    value: '$ordersCount',
                    caption: 'в личном кабинете',
                    inverse: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.eyebrow,
    required this.value,
    required this.caption,
  });

  final String eyebrow;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientQuickStats extends StatelessWidget {
  const _ClientQuickStats({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final orders = controller.clientOrders;
    final readyCount = orders.where((item) => item.status == 'ready').length;
    final activeCount = orders.where(_isActiveOrder).length;
    final loyalty = _loyaltySummary(orders);
    final isCompact = MediaQuery.sizeOf(context).width < 520;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isCompact ? 1 : 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isCompact ? 2.8 : 1.45,
      children: [
        _FeatureTile(
          eyebrow: 'В корзине',
          value: '${controller.cartItemsCount}',
          caption: 'товаров к оформлению',
        ),
        _FeatureTile(
          eyebrow: 'Активно',
          value: '$activeCount',
          caption: 'заказов в пути',
        ),
        _FeatureTile(
          eyebrow: 'Лояльность',
          value: loyalty.tier,
          caption: '$readyCount готово, ${loyalty.points} баллов',
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.product,
    required this.quantity,
    required this.isCompact,
  });

  final Product product;
  final int quantity;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return GlassPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isCompact ? 90 : 110,
            child: _CatalogVisual(
              title: product.title,
              subtitle:
                  product.availabilityType == 'in_stock' ? 'Готовое' : 'Ателье',
              imageUrl: product.imageUrl,
              index: 0,
              isEditorial: true,
              isCompact: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  formatTenge(product.price),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () =>
                          controller.updateCartQuantity(product.id, quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () =>
                          controller.updateCartQuantity(product.id, quantity + 1),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'Убрать',
                      isGhost: true,
                      isExpanded: false,
                      minHeight: 38,
                      fontSize: 10,
                      onPressed: () =>
                          controller.updateCartQuantity(product.id, 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _ClientDiscoveryBar extends StatelessWidget {
  const _ClientDiscoveryBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 390;
    final height = isCompact ? 48.0 : 54.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Поиск по коллекции',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isCompact ? 10 : 12),
        Container(
          width: height,
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: colorScheme.onPrimary,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _CatalogFilterRow extends StatelessWidget {
  const _CatalogFilterRow({
    required this.totalCount,
    required this.readyCount,
    required this.atelierCount,
  });

  final int totalCount;
  final int readyCount;
  final int atelierCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CatalogFilterChip(label: 'Все', count: totalCount, selected: true),
        _CatalogFilterChip(label: 'Готовое', count: readyCount),
        _CatalogFilterChip(label: 'Ателье', count: atelierCount),
      ],
    );
  }
}

class _CatalogFilterChip extends StatelessWidget {
  const _CatalogFilterChip({
    required this.label,
    required this.count,
    this.selected = false,
  });

  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? colorScheme.primary : colorScheme.outline,
        ),
      ),
      child: Text(
        '$label  $count',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loyalty = _resolvedLoyalty(order);
    final colorScheme = theme.colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      backgroundColor: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'АКТИВНЫЙ ЗАКАЗ',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            order.productTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _clientOrderNextStepMessage(order),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _OrderTimeline(
            status: order.status,
            trackingStage: order.trackingStage,
          ),
          const SizedBox(height: 24),
          _OrderFactStrip(
            items: [
              ('Код заказа', _displayOrderCode(order)),
              ('Количество', '${order.quantity}'),
              ('Готовность', order.selectedReadyDate),
              ('Этап', statusLabel(order.trackingStage)),
            ],
          ),
          if (AppScope.of(context).showOrderHintsEnabled) ...[
            const SizedBox(height: 24),
            _OrderSupportNote(order: order),
          ],
          const SizedBox(height: 24),
          _LoyaltyMeter(progress: loyalty),
          if (order.status == 'placed') ...[
            const SizedBox(height: 24),
            _PayOrderButton(order: order),
          ] else if (order.status == 'paid') ...[
            const SizedBox(height: 16),
            Text(
              'Оплата подтверждена. Ожидается подтверждение франчайзи.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadyOrderSpotlight extends StatelessWidget {
  const _ReadyOrderSpotlight({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      backgroundColor: colorScheme.primary,
      borderColor: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ФИНАЛ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.72),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Заказ готов',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: colorScheme.onPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            order.productTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Открыть',
            backgroundColor: colorScheme.onPrimary,
            foregroundColor: colorScheme.primary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _ReadyOrderScreen(order: order),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.visualIndex,
    required this.isCompact,
  });

  final Product product;
  final int visualIndex;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isInStock = product.availabilityType == 'in_stock';
    final useEditorialView = controller.editorialCardsEnabled;

    if (isCompact) {
      return GlassPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: _CatalogVisual(
                title: product.title,
                subtitle: isInStock ? 'Готовое' : 'Ателье',
                imageUrl: product.imageUrl,
                index: visualIndex,
                isEditorial: false,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatTenge(product.price, currency: product.currency),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: StatusChip(status: product.availabilityType),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'В корзину',
                      minHeight: 44,
                      fontSize: 10,
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.primary,
                      onPressed: () {
                        controller.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.title} добавлен в корзину'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassPanel(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CatalogVisual(
            title: product.title,
            subtitle: isInStock ? 'ГОТОВОЕ ИЗДЕЛИЕ' : 'АТЕЛЬЕ ПРЕДЗАКАЗ',
            imageUrl: product.imageUrl,
            index: visualIndex,
            isEditorial: useEditorialView,
            isCompact: isCompact,
          ),
          SizedBox(height: isCompact ? 12 : 14),
          Text(
            product.title,
            style: theme.textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            product.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            formatTenge(product.price, currency: product.currency),
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusChip(status: product.availabilityType),
              const SizedBox(width: 8),
              Text(
                '${product.defaultReadyDays} дн.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          SizedBox(height: isCompact ? 12 : 14),
          PrimaryButton(
            label: 'В корзину',
            minHeight: isCompact ? 44 : 48,
            fontSize: 11,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
            onPressed: () {
              controller.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.title} добавлен в корзину')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreateOrderSheet extends StatefulWidget {
  const _CreateOrderSheet({
    required this.product,
    required this.outerContext,
    this.initialQuantity = 1,
    this.onSuccess,
  });

  final Product product;
  final BuildContext outerContext;
  final int initialQuantity;
  final VoidCallback? onSuccess;

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _dateController;
  late final DateTime _now;
  late final DateTime _initialDate;

  bool get _requiresDate => widget.product.availabilityType != 'in_stock';

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.initialQuantity.toString());
    _now = DateTime.now();
    _initialDate = _now.add(
      Duration(days: widget.product.defaultReadyDays.clamp(1, 90)),
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: GlassPanel(
        backgroundColor: colorScheme.surface,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.availabilityType == 'in_stock'
                    ? 'ПОКУПКА'
                    : 'ПРЕДЗАКАЗ',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.product.title, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 16),
              Text(
                widget.product.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Количество',
                ),
              ),
              if (_requiresDate) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Дата готовности',
                  ),
                  onTap: _pickDate,
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: controller.createOrderProductId == widget.product.id
                    ? 'Оформление...'
                    : widget.product.availabilityType == 'in_stock'
                        ? 'Подтвердить покупку'
                        : 'Подтвердить предзаказ',
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
    widget.onSuccess?.call();
    ScaffoldMessenger.of(widget.outerContext).showSnackBar(
      const SnackBar(content: Text('Заказ создан. Следующий шаг: оплата.')),
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
                child:
                    Text(order.productTitle, style: theme.textTheme.titleLarge),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          _OrderFactStrip(
            items: [
              ('Код заказа', _displayOrderCode(order)),
              ('Количество', '${order.quantity}'),
              ('Дата', order.selectedReadyDate),
              ('Статус', statusLabel(order.status)),
            ],
            dense: true,
          ),
          const SizedBox(height: 16),
          _OrderTimeline(
            status: order.status,
            trackingStage: order.trackingStage,
            compact: true,
          ),
          const SizedBox(height: 16),
          _MetaRow(label: 'order_type', value: statusLabel(order.orderType)),
          _MetaRow(label: 'created_at', value: order.createdAt),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.controller,
    required this.user,
    this.embedded = false,
  });

  final AppController controller;
  final User user;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final summary = _loyaltySummary(controller.clientOrders);
    final activeOrder =
        controller.clientOrders.where(_isActiveOrder).firstOrNull;
    final colorScheme = Theme.of(context).colorScheme;
    final completedCount = controller.clientOrders
        .where((order) => order.status == 'ready')
        .length;

    final content = [
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
                      : () => _showEditProfileDialog(context, controller, user),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _MetaRow(label: 'full_name', value: user.fullName),
            _MetaRow(label: 'email', value: user.email),
            _MetaRow(
              label: 'role',
              value: '${roleValueLabel(user.role.value)} · ${summary.tier}',
            ),
            _MetaRow(
              label: 'created_at',
              value: 'Заказов: ${controller.clientOrders.length}',
            ),
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
      const SizedBox(height: 16),
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ПРОГРАММА ЛОЯЛЬНОСТИ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _LoyaltyMeter(progress: summary.progress),
            const SizedBox(height: 12),
            _MetaRow(label: 'status', value: summary.tier),
            _MetaRow(label: 'price', value: '${summary.points} баллов'),
            _MetaRow(
              label: 'ready_date',
              value: 'Готово заказов: $completedCount',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'УРОВЕНЬ СЕРВИСА',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            const _ProfileFeatureLine(
              title: 'Персональная история заказов',
              caption: 'Все заказы и изменения собраны в одном месте.',
            ),
            if (activeOrder != null)
              _ProfileFeatureLine(
                title: 'Активный заказ',
                caption: activeOrder.productTitle,
              ),
            const _ProfileFeatureLine(
              title: 'Трекинг готовности',
              caption:
                  'Этапы оформления, пошива и готовности показаны визуально.',
            ),
            const _ProfileFeatureLine(
              title: 'Лояльность клиента',
              caption: 'Прогресс по покупкам и повторным заказам.',
            ),
          ],
        ),
      ),
    ];

    if (embedded) {
      return Column(children: content);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: content,
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    AppController controller,
    User user,
  ) async {
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

    if (shouldSave != true || !context.mounted) {
      nameController.dispose();
      return;
    }

    await controller.updateProfile(fullName: nameController.text.trim());
    nameController.dispose();
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({
    required this.controller,
    this.embedded = false,
  });

  final AppController controller;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'НАСТРОЙКИ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          _PreferenceSwitchCard(
            title: fieldLabel('notifications'),
            subtitle: 'Показывать уведомления о движении заказа.',
            value: controller.notificationsEnabled,
            onChanged: controller.setNotificationsEnabled,
          ),
          _PreferenceSwitchCard(
            title: 'Быстрое открытие корзины',
            subtitle: 'После добавления товар сразу ведёт к оформлению.',
            value: controller.autoOpenCartEnabled,
            onChanged: controller.setAutoOpenCartEnabled,
          ),
          _PreferenceSwitchCard(
            title: fieldLabel('editorial_cards'),
            subtitle: 'Карточки каталога в более журнальной подаче.',
            value: controller.editorialCardsEnabled,
            onChanged: controller.setEditorialCardsEnabled,
          ),
          _PreferenceSwitchCard(
            title: fieldLabel('compact_mode'),
            subtitle: 'Более плотный режим списка и заказов.',
            value: controller.compactModeEnabled,
            onChanged: controller.setCompactModeEnabled,
          ),
          _PreferenceSwitchCard(
            title: 'Подсказки по заказу',
            subtitle: 'Пояснения на активных этапах заказа.',
            value: controller.showOrderHintsEnabled,
            onChanged: controller.setShowOrderHintsEnabled,
          ),
          _PreferenceSwitchCard(
            title: fieldLabel('biometric_lock'),
            subtitle: 'Заготовка под защищённый вход.',
            value: controller.biometricLockEnabled,
            onChanged: controller.setBiometricLockEnabled,
          ),
          _PreferenceSwitchCard(
            title: 'Моментальные обновления',
            subtitle: 'Держать экран синхронизированным без перезагрузки.',
            value: controller.instantUpdatesEnabled,
            onChanged: controller.setInstantUpdatesEnabled,
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [content],
    );
  }
}

class _PreferenceSwitchCard extends StatelessWidget {
  const _PreferenceSwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.24),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfileFeatureLine extends StatelessWidget {
  const _ProfileFeatureLine({
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            caption,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _CatalogVisual extends StatelessWidget {
  const _CatalogVisual({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.index,
    required this.isEditorial,
    required this.isCompact,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final int index;
  final bool isEditorial;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final useDark = isEditorial && !isCompact;

    if (isCompact) {
      return Container(
        height: 104,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ProductImage(url: imageUrl, compact: true),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePill(label: subtitle),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _compactVisualTitle(title),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.02,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _IndexBadge(index: index),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: useDark ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: useDark ? colorScheme.primary : colorScheme.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ProductImage(url: imageUrl, compact: false),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.02),
                  Colors.black.withValues(alpha: 0.48),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImagePill(label: subtitle),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              height: 1.02,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.34),
                            fontSize: 40,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _compactVisualTitle(String title) {
  final parts = title
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) {
    return 'AVISHU';
  }

  return parts.join('\n');
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.url,
    required this.compact,
  });

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (url.isEmpty) {
      return _ProductImageFallback(compact: compact);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        return _ProductImageFallback(compact: compact);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return ColoredBox(
          color: colorScheme.surface,
          child: Center(
            child: SizedBox(
              width: compact ? 18 : 22,
              height: compact ? 18 : 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: compact ? 20 : 28,
          color: colorScheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _ImagePill extends StatelessWidget {
  const _ImagePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 8.5,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        (index + 1).toString().padLeft(2, '0'),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 8.5,
            ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.eyebrow,
    required this.value,
    required this.caption,
    this.inverse = false,
  });

  final String eyebrow;
  final String value;
  final String caption;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inverse
            ? colorScheme.onPrimary.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
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
            eyebrow.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: inverse
                  ? colorScheme.onPrimary.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: inverse ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
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

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({
    required this.status,
    required this.trackingStage,
    this.compact = false,
  });

  final String status;
  final String trackingStage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentStep = switch ((status, trackingStage)) {
      ('archived', _) => 6,
      ('delivered', _) => 6,
      ('ready', _) => 6,
      ('in_production', 'qc') => 5,
      ('in_production', _) => 4,
      ('accepted', _) => 3,
      ('paid', _) => 2,
      _ => 1,
    };

    const labels = [
      'Создан',
      'Оплачен',
      'Подтвержден',
      'Цех',
      'ОТК',
      'Готов',
    ];

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(labels.length, (index) {
          final step = index + 1;
          final isDone = step < currentStep;
          final isCurrent = step == currentStep;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? scheme.primary
                  : isDone
                      ? scheme.secondaryContainer
                      : scheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isCurrent || isDone ? Colors.transparent : scheme.outline,
              ),
            ),
            child: Text(
              labels[index],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCurrent
                        ? scheme.onPrimary
                        : isDone
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                    fontWeight: isCurrent || isDone
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
            ),
          );
        }),
      );
    }

    return Column(
      children: List.generate(labels.length, (index) {
        final step = index + 1;
        final isDone = step < currentStep;
        final isCurrent = step == currentStep;
        final isLast = index == labels.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isCurrent ? 18 : 14,
                    height: isCurrent ? 18 : 14,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? scheme.primary
                          : isDone
                              ? scheme.secondaryContainer
                              : scheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isCurrent || isDone ? Colors.transparent : scheme.outline,
                      ),
                    ),
                    child: isCurrent
                        ? Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: scheme.onPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: isDone ? scheme.secondaryContainer : scheme.outline,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        labels[index],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isCurrent || isDone
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'Сейчас',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PayOrderButton extends StatelessWidget {
  const _PayOrderButton({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return PrimaryButton(
      label:
          controller.payOrderId == order.id ? 'Оплата...' : 'Перейти к оплате',
      onPressed: controller.payOrderId == order.id
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _QuickPaymentScreen(order: order),
                ),
              ),
    );
  }
}

class _QuickPaymentScreen extends StatefulWidget {
  const _QuickPaymentScreen({required this.order});

  final Order order;

  @override
  State<_QuickPaymentScreen> createState() => _QuickPaymentScreenState();
}

class _QuickPaymentScreenState extends State<_QuickPaymentScreen> {
  String _paymentMethod = 'apple_pay';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final order = widget.order;
    final colorScheme = Theme.of(context).colorScheme;
    final product = controller.products
        .where((item) => item.id == order.productId)
        .firstOrNull;
    final unitPrice = num.tryParse('${product?.price ?? 18900}') ?? 18900;
    final total = unitPrice * order.quantity;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.outline),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Быстрая оплата',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassPanel(
                backgroundColor: colorScheme.primary,
                borderColor: colorScheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ОПЛАТА',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.72),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Подтвердите заказ',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'После подтверждения заказ перейдёт на следующий этап.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Способ оплаты',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PaymentMethodCard(
                      assetPath: 'logo/apple pay.png',
                      label: 'Apple Pay',
                      selected: _paymentMethod == 'apple_pay',
                      onTap: () => setState(() => _paymentMethod = 'apple_pay'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PaymentMethodCard(
                      assetPath: 'logo/google pay.png',
                      label: 'Google Pay',
                      selected: _paymentMethod == 'google_pay',
                      onTap: () => setState(() => _paymentMethod = 'google_pay'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PaymentMethodCard(
                      assetPath: 'logo/kaspi.png',
                      label: 'Kaspi',
                      selected: _paymentMethod == 'kaspi',
                      onTap: () => setState(() => _paymentMethod = 'kaspi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _paymentMethodLabel(_paymentMethod),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
                    _MetaRow(
                      label: 'price',
                      value: '${formatTenge(unitPrice)} × ${order.quantity}',
                    ),
                    _MetaRow(label: 'ready_date', value: order.selectedReadyDate),
                    _MetaRow(label: 'order_code', value: _displayOrderCode(order)),
                  ],
                ),
              ),
              const Spacer(),
              GlassPanel(
                child: Column(
                  children: [
                    _MetaRow(label: 'tracking_stage', value: 'Ожидает оплаты'),
                    _MetaRow(label: 'price', value: formatTenge(total)),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: controller.payOrderId == order.id
                          ? 'Оплата...'
                          : 'Подтвердить оплату',
                      onPressed: controller.payOrderId == order.id
                          ? null
                          : () async {
                              await controller.payOrder(order);
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      _PaymentSuccessScreen(order: order),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.assetPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 112,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  color: selected ? colorScheme.onPrimary : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        selected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSuccessScreen extends StatelessWidget {
  const _PaymentSuccessScreen({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Оплата подтверждена',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Заказ ${_displayOrderCode(order)} передан дальше. Следующий шаг увидите в таймлайне.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'К заказу',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyOrderScreen extends StatelessWidget {
  const _ReadyOrderScreen({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final product = controller.products
        .where((item) => item.id == order.productId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: const Icon(Icons.close_rounded),
                ),
              ),
              const Spacer(),
              Text(
                'ЗАКАЗ ГОТОВ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                order.productTitle,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 14),
              Text(
                'Можно повторить этот заказ в один шаг.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              _OrderFactStrip(
                items: [
                  ('Код заказа', _displayOrderCode(order)),
                  ('Количество', '${order.quantity}'),
                  ('Готовность', order.selectedReadyDate),
                  ('Статус', 'Готов'),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Повторить заказ',
                onPressed: product == null
                    ? null
                    : () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetContext) {
                            return _CreateOrderSheet(
                              product: product,
                              outerContext: context,
                              initialQuantity: order.quantity,
                            );
                          },
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _paymentMethodLabel(String value) {
  switch (value) {
    case 'google_pay':
      return 'Google Pay';
    case 'kaspi':
      return 'Kaspi';
    default:
      return 'Apple Pay';
  }
}

bool _isActiveOrder(Order order) =>
    !{'ready', 'delivered', 'archived'}.contains(order.status);

String _displayOrderCode(Order order) {
  if (order.orderCode.trim().isNotEmpty) {
    return order.orderCode;
  }
  return _shortOrderId(order.id);
}

String _shortOrderId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return value.substring(0, 8).toUpperCase();
}

String _clientOrderNextStepMessage(Order order) {
  switch (order.status) {
    case 'placed':
      return 'Остался один шаг: подтвердить тестовую оплату.';
    case 'paid':
      return 'Оплата принята. Франчайзи подтверждает запуск заказа.';
    case 'accepted':
      return 'Заказ подтвержден и готовится к передаче в цех.';
    case 'in_production':
      return 'Заказ уже в производстве. Отслеживайте путь по этапам.';
    case 'ready':
      return 'Заказ готов. Можно завершать выдачу клиенту.';
    case 'delivered':
      return 'Заказ уже выдан клиенту.';
    case 'archived':
      return 'Заказ закрыт и перенесён в архив.';
    default:
      return 'Статус обновляется автоматически.';
  }
}

String _clientOrderSupportNote(Order order) {
  switch (order.status) {
    case 'placed':
      return 'После оплаты заказ сразу попадёт в очередь франчайзи.';
    case 'paid':
      return 'Следующий шаг выполняет франчайзи. Дополнительных действий не требуется.';
    case 'accepted':
      return 'Подтверждённый заказ готовится к запуску производственных этапов.';
    case 'in_production':
      return 'Производство выполняет этапы заказа. Готовность обновится автоматически.';
    case 'ready':
      return 'Финальный статус получен. Заказ готов для клиента.';
    default:
      return 'Состояние заказа синхронизируется автоматически.';
  }
}

class _LoyaltyMeter extends StatelessWidget {
  const _LoyaltyMeter({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0, 100);
    final value = safeProgress / 100;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Накопленный прогресс',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '$safeProgress%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: value,
            backgroundColor: colorScheme.outline,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class _OrderFactStrip extends StatelessWidget {
  const _OrderFactStrip({
    required this.items,
    this.dense = false,
  });

  final List<(String, String)> items;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: dense ? 112 : 132,
            maxWidth: dense ? 148 : 172,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 12 : 14,
              vertical: dense ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
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

class _OrderSupportNote extends StatelessWidget {
  const _OrderSupportNote({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(
        _clientOrderSupportNote(order),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
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

int _resolvedLoyalty(Order order) {
  final raw = int.tryParse(order.loyaltyProgress.toString()) ?? 0;
  if (raw > 0) {
    return raw;
  }

  return switch (order.status) {
    'ready' => 100,
    'in_production' => 72,
    'accepted' => 45,
    _ => 18,
  };
}

_LoyaltySummary _loyaltySummary(List<Order> orders) {
  final completed = orders.where((item) => item.status == 'ready').toList();
  final totalSpent = completed.fold<double>(
    0,
    (sum, item) => sum + item.quantity * 15000,
  );
  final points = totalSpent ~/ 1000;
  final progress = (completed.length * 20).clamp(10, 100);
  final tier = switch (completed.length) {
    >= 5 => 'ATELIER',
    >= 3 => 'SELECT',
    >= 1 => 'START',
    _ => 'NEW',
  };
  return _LoyaltySummary(
    tier: tier,
    points: points,
    progress: progress,
  );
}

class _LoyaltySummary {
  const _LoyaltySummary({
    required this.tier,
    required this.points,
    required this.progress,
  });

  final String tier;
  final int points;
  final int progress;
}

String _formatOrderDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

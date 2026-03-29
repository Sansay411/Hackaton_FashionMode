import 'package:flutter/material.dart';

import '../../data/models/user.dart';
import 'app_background.dart';
import 'glass_panel.dart';

class RoleShellScaffold extends StatelessWidget {
  const RoleShellScaffold({
    super.key,
    required this.user,
    required this.roleTitle,
    required this.isOnline,
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
    required this.onLogout,
    required this.tabs,
    this.banner,
    this.headerAction,
  });

  final User user;
  final String roleTitle;
  final bool isOnline;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget child;
  final VoidCallback onLogout;
  final List<RoleShellTabItem> tabs;
  final Widget? banner;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 420;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (banner != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: banner!,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 16 : 24,
                  12,
                  isCompact ? 16 : 24,
                  10,
                ),
                child: GlassPanel(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 14 : 16,
                    isCompact ? 12 : 14,
                    isCompact ? 14 : 16,
                    isCompact ? 12 : 14,
                  ),
                  borderRadius: isCompact ? 24 : 28,
                  child: isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _ShellTag(label: roleTitle),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    _todayLabel(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _Avatar(
                                  name: user.fullName,
                                  size: 32,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.titleLarge?.copyWith(
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _roleSubtitle(user),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (headerAction != null) ...[
                                  const SizedBox(width: 6),
                                  headerAction!,
                                ],
                                const SizedBox(width: 6),
                                _CircleAction(
                                  icon: Icons.logout_rounded,
                                  onTap: onLogout,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _Avatar(
                              name: user.fullName,
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      _ShellTag(label: roleTitle),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          user.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _roleSubtitle(user),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _todayLabel(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (headerAction != null) ...[
                              const SizedBox(width: 8),
                              headerAction!,
                            ],
                            const SizedBox(width: 8),
                            _CircleAction(
                              icon: Icons.logout_rounded,
                              onTap: onLogout,
                            ),
                          ],
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
                  child: child,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 16 : 24,
                  16,
                  isCompact ? 16 : 24,
                  isCompact ? 18 : 24,
                ),
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  borderRadius: isCompact ? 24 : 28,
                  child: Row(
                    children: [
                      for (var index = 0; index < tabs.length; index++)
                        _NavItem(
                          icon: tabs[index].icon,
                          label: tabs[index].label,
                          selected: currentIndex == index,
                          onTap: () => onTabSelected(index),
                        ),
                    ],
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

class RoleShellTabItem {
  const RoleShellTabItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    this.size = 48,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parts = name
        .split(' ')
        .where((item) => item.trim().isNotEmpty)
        .map((item) => item.trim()[0])
        .take(2)
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      alignment: Alignment.center,
      child: Text(
        parts.isEmpty ? 'А' : parts,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: size > 40 ? 12 : 11,
            ),
      ),
    );
  }
}

String _roleSubtitle(User user) {
  if (user.role == UserRole.client) {
    return 'Каталог, заказ и статус в одном месте';
  }
  if (user.role == UserRole.franchisee) {
    return 'Контроль заказов и передача в производство';
  }
  return user.productionType == 'manager'
      ? 'Очередь задач, команда и назначения'
      : 'Личные задачи и быстрые действия';
}

class _ShellTag extends StatelessWidget {
  const _ShellTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onPrimary,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final iconColor = selected ? scheme.primary : scheme.onSurfaceVariant;
    final textColor = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final iconSize = isCompact ? 18.0 : 20.0;
    final iconBox = isCompact ? 38.0 : 42.0;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedScale(
          scale: selected ? 1 : 0.98,
          duration: const Duration(milliseconds: 180),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? iconBox + 4 : iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.secondaryContainer
                        : scheme.onPrimary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? scheme.secondaryContainer
                          : scheme.outline,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
                SizedBox(height: isCompact ? 6 : 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor,
                        fontSize: isCompact ? 9.5 : 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _todayLabel() {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  final now = DateTime.now();
  return 'Сегодня, ${now.day} ${months[now.month - 1]}';
}

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

    final tabs = user.productionType == 'manager'
        ? const [
            RoleShellTabItem(icon: Icons.dashboard_rounded, label: 'Очередь'),
            RoleShellTabItem(icon: Icons.groups_rounded, label: 'Команда'),
            RoleShellTabItem(
                icon: Icons.person_outline_rounded, label: 'Профиль'),
            RoleShellTabItem(icon: Icons.tune_rounded, label: 'Настройки'),
          ]
        : const [
            RoleShellTabItem(icon: Icons.dashboard_rounded, label: 'Задачи'),
            RoleShellTabItem(
                icon: Icons.person_outline_rounded, label: 'Профиль'),
            RoleShellTabItem(icon: Icons.tune_rounded, label: 'Настройки'),
          ];

    return RoleShellScaffold(
      user: user,
      roleTitle:
          user.productionType == 'manager' ? 'Менеджер цеха' : 'Сотрудник цеха',
      isOnline: controller.isRealtimeConnected,
      currentIndex: _currentTab,
      onTabSelected: (index) => setState(() => _currentTab = index),
      tabs: tabs,
      onLogout: () {
        controller.logout();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      headerAction: _HeaderRefreshButton(
        onTap: () => controller.refreshForCurrentRole(),
      ),
      child: user.productionType == 'manager'
          ? switch (_currentTab) {
              1 => _TeamTab(controller: controller),
              2 => _ProfileTab(controller: controller, user: user),
              3 => _SettingsTab(controller: controller),
              _ => _HomeTab(controller: controller, user: user),
            }
          : switch (_currentTab) {
              1 => _ProfileTab(controller: controller, user: user),
              2 => _SettingsTab(controller: controller),
              _ => _HomeTab(controller: controller, user: user),
            },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.controller,
    required this.user,
  });

  final AppController controller;
  final User user;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.productionTasks;
    final assigned = tasks.where((item) => item.status == 'assigned').length;
    final inProgress =
        tasks.where((item) => item.status == 'in_progress').length;
    final completed = tasks.where((item) => item.status == 'completed').length;
    final queued = tasks.where((item) => item.status == 'queued').length;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () => controller.refreshForCurrentRole(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _ProductionHero(
            user: user,
            queuedCount: queued,
            assignedCount: assigned,
            inProgressCount: inProgress,
            completedCount: completed,
          ),
          const SizedBox(height: 24),
          if (controller.productionError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassPanel(
                backgroundColor: colorScheme.surface,
                borderColor: colorScheme.error,
                child: Text(
                  controller.productionError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                ),
              ),
            ),
          if (controller.isProductionTasksLoading && tasks.isEmpty)
            const SizedBox(
              height: 280,
              child: LoadingStateView(message: 'Загрузка задач цеха'),
            )
          else if (tasks.isEmpty)
            SizedBox(
              height: 280,
              child: EmptyStateView(
                title: user.productionType == 'manager'
                    ? 'Очередь менеджера пуста'
                    : 'Ваших задач пока нет',
                description: user.productionType == 'manager'
                    ? 'Задачи появятся после передачи заказа в цех.'
                    : 'Как только менеджер назначит этап, он появится здесь.',
              ),
            )
          else if (user.productionType == 'manager')
            _ManagerView(controller: controller, tasks: tasks, user: user)
          else
            _WorkerView(controller: controller, tasks: tasks, user: user),
        ],
      ),
    );
  }
}

class _ManagerView extends StatefulWidget {
  const _ManagerView({
    required this.controller,
    required this.tasks,
    required this.user,
  });

  final AppController controller;
  final List<ProductionTask> tasks;
  final User user;

  @override
  State<_ManagerView> createState() => _ManagerViewState();
}

class _ManagerViewState extends State<_ManagerView> {
  String _statusFilter = 'all';
  String _workerFilter = 'all';
  String _sortMode = 'priority';

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks.where((item) {
      final statusPass = _statusFilter == 'all' || item.status == _statusFilter;
      final workerPass =
          _workerFilter == 'all' || item.assignedTo == _workerFilter;
      return statusPass && workerPass;
    }).toList()
      ..sort((a, b) {
        if (_sortMode == 'updated') {
          return b.updatedAt.compareTo(a.updatedAt);
        }
        final priorityCompare =
            _priorityRank(b.priority).compareTo(_priorityRank(a.priority));
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        final statusCompare =
            _statusRank(a.status).compareTo(_statusRank(b.status));
        if (statusCompare != 0) {
          return statusCompare;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

    final queued = tasks.where((item) => item.status == 'queued').toList();
    final assigned = tasks.where((item) => item.status == 'assigned').toList();
    final inProgress =
        tasks.where((item) => item.status == 'in_progress').toList();
    final completed =
        tasks.where((item) => item.status == 'completed').toList();

    return Column(
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ФИЛЬТРЫ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [
                    ('all', 'Все'),
                    ('queued', 'Очередь'),
                    ('assigned', 'Назначено'),
                    ('in_progress', 'В работе'),
                    ('completed', 'Готово'),
                  ])
                    _FilterChip(
                      label: item.$2,
                      selected: _statusFilter == item.$1,
                      onTap: () => setState(() => _statusFilter = item.$1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.controller.productionOrderCodeSearchQuery,
                textCapitalization: TextCapitalization.characters,
                onFieldSubmitted: (value) =>
                    widget.controller.setProductionOrderCodeSearchQuery(value),
                decoration: const InputDecoration(
                  labelText: 'Поиск по коду заказа',
                  hintText: 'AV-20260329-0001',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final fields = [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _workerFilter,
                        decoration: const InputDecoration(
                          labelText: 'Швея',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Все швеи'),
                          ),
                          ...widget.controller.productionWorkers.map(
                            (worker) => DropdownMenuItem(
                              value: worker.id,
                              child: Text(worker.fullName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _workerFilter = value ?? 'all');
                        },
                      ),
                    ),
                    if (!compact) const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortMode,
                        decoration: const InputDecoration(
                          labelText: 'Сортировка',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'priority',
                            child: Text('По приоритету'),
                          ),
                          DropdownMenuItem(
                            value: 'updated',
                            child: Text('По обновлению'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _sortMode = value ?? 'priority');
                        },
                      ),
                    ),
                  ];

                  return compact
                      ? Column(
                          children: [
                            fields.first,
                            const SizedBox(height: 12),
                            fields.last,
                          ],
                        )
                      : Row(children: fields);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ManagerSection(
          title: 'Очередь',
          subtitle: 'Новые этапы без исполнителя',
          tasks: queued,
        ),
        const SizedBox(height: 16),
        _ManagerSection(
          title: 'Назначено',
          subtitle: 'Передано сотрудникам',
          tasks: assigned,
        ),
        const SizedBox(height: 16),
        _ManagerSection(
          title: 'В работе',
          subtitle: 'Активные этапы цеха',
          tasks: inProgress,
        ),
        const SizedBox(height: 16),
        _ManagerSection(
          title: 'Завершено',
          subtitle: 'Закрытые этапы',
          tasks: completed,
        ),
      ],
    );
  }

  int _priorityRank(String value) {
    switch (value) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  int _statusRank(String value) {
    switch (value) {
      case 'in_progress':
        return 0;
      case 'queued':
        return 1;
      case 'assigned':
        return 2;
      case 'completed':
        return 3;
      default:
        return 4;
    }
  }
}

class _TeamTab extends StatelessWidget {
  const _TeamTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _WorkerRosterSection(
          controller: controller,
          tasks: controller.productionTasks,
        ),
      ],
    );
  }
}

class _WorkerView extends StatelessWidget {
  const _WorkerView({
    required this.controller,
    required this.tasks,
    required this.user,
  });

  final AppController controller;
  final List<ProductionTask> tasks;
  final User user;

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<ProductionTask>.from(tasks)
      ..sort(_compareWorkerTasks);
    final activeTask =
        sortedTasks.where((item) => item.status == 'in_progress').firstOrNull;
    final availableAssignedTask = sortedTasks
        .where(
          (item) =>
              item.status == 'assigned' &&
              _workerBlockingReason(item, sortedTasks) == null,
        )
        .firstOrNull;
    final currentTask = activeTask ?? availableAssignedTask;
    final firstBlockedAssignedTask = currentTask == null
        ? sortedTasks
            .where((item) => item.status == 'assigned')
            .map((item) => _workerBlockingReason(item, sortedTasks))
            .whereType<String>()
            .firstOrNull
        : null;
    final completedTasks =
        sortedTasks.where((item) => item.status == 'completed').toList();
    final lastCompleted = completedTasks.isEmpty ? null : completedTasks.first;
    final currentOrderTasks = currentTask == null
        ? const <ProductionTask>[]
        : (sortedTasks
              .where((item) => item.orderId == currentTask.orderId)
              .toList()
            ..sort((a, b) =>
                _stageRank(a.operationStage).compareTo(_stageRank(b.operationStage))));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentTask != null) ...[
          SectionHeader(
            title: currentTask.status == 'in_progress'
                ? 'Активная работа'
                : 'Назначено на сейчас',
          ),
          const SizedBox(height: 16),
          _WorkerTaskCard(
            task: currentTask,
            isPriority: true,
            canAct: true,
          ),
          if (currentOrderTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _WorkerStageStrip(
              tasks: currentOrderTasks,
              activeTaskId: currentTask.id,
            ),
          ],
          const SizedBox(height: 24),
        ] else if (lastCompleted != null) ...[
          _WorkerCompletionHint(task: lastCompleted),
          const SizedBox(height: 24),
        ] else if (firstBlockedAssignedTask != null) ...[
          GlassPanel(
            borderColor: colorScheme.outline,
            child: Text(
              firstBlockedAssignedTask,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        SectionHeader(
          title: completedTasks.isEmpty ? 'Мои задачи' : 'Остальные задачи',
          trailing: Text(
            '${sortedTasks.length}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ),
        const SizedBox(height: 16),
        ...sortedTasks
            .where((task) => currentTask == null || task.id != currentTask.id)
            .map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _WorkerTaskCard(
                  task: task,
                  canAct: false,
                  helperMessage: task.status == 'assigned'
                      ? _workerBlockingReason(task, sortedTasks) ??
                          'Этап откроется после текущей задачи.'
                      : null,
                ),
              ),
            ),
      ],
    );
  }

  int _workerSortRank(ProductionTask task) {
    switch (task.status) {
      case 'in_progress':
        return 0;
      case 'assigned':
        return 1;
      case 'queued':
        return 2;
      default:
        return 3;
    }
  }

  int _compareWorkerTasks(ProductionTask a, ProductionTask b) {
    final statusCompare = _workerSortRank(a).compareTo(_workerSortRank(b));
    if (statusCompare != 0) {
      return statusCompare;
    }

    final stageCompare =
        _stageRank(a.operationStage).compareTo(_stageRank(b.operationStage));
    if (stageCompare != 0) {
      return stageCompare;
    }

    return a.id.compareTo(b.id);
  }
}

class _WorkerStageStrip extends StatelessWidget {
  const _WorkerStageStrip({
    required this.tasks,
    required this.activeTaskId,
  });

  final List<ProductionTask> tasks;
  final String activeTaskId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outline,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Этапы заказа',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final task in tasks)
                _StagePill(
                  label: _shortStageLabel(task.operationStage),
                  active: task.id == activeTaskId,
                  done: task.status == 'completed',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  const _StagePill({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = done
        ? colorScheme.secondaryContainer
        : active
            ? colorScheme.primary
            : colorScheme.surface;
    final foregroundColor = done
        ? colorScheme.primary
        : active
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active || done ? backgroundColor : colorScheme.outline,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _WorkerCompletionHint extends StatelessWidget {
  const _WorkerCompletionHint({required this.task});

  final ProductionTask task;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFinalStage = task.operationStage == 'qc';

    return GlassPanel(
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              isFinalStage ? Icons.check_circle_outline : Icons.task_alt_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFinalStage ? 'Заказ готов' : 'Этап завершён',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  isFinalStage
                      ? 'Финальная проверка завершена. Клиент увидит статус готов.'
                      : 'Ваш этап закрыт. Следующая задача ждёт распределения менеджером.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerRosterSection extends StatelessWidget {
  const _WorkerRosterSection({
    required this.controller,
    required this.tasks,
  });

  final AppController controller;
  final List<ProductionTask> tasks;

  @override
  Widget build(BuildContext context) {
    final workers = controller.productionWorkers;
    final activeByWorker = <String, int>{};
    final colorScheme = Theme.of(context).colorScheme;

    for (final task in tasks) {
      if (task.assignedTo == null || task.status == 'completed') {
        continue;
      }
      activeByWorker.update(
        task.assignedTo!,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 30,
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
                      'КОМАНДА',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Швеи и текущая загрузка',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                label: controller.isWorkerCreating
                    ? 'Создание...'
                    : 'Добавить швею',
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.primary,
                isExpanded: false,
                minHeight: 40,
                fontSize: 10,
                onPressed: controller.isWorkerCreating
                    ? null
                    : () => _showCreateWorkerSheet(context),
              ),
            ],
          ),
          if (controller.workerCreateError != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.workerCreateError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          if (workers.isEmpty)
            Text(
              'Сотрудников пока нет.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else
            Column(
              children: [
                for (final worker in (List<User>.from(workers)
                  ..sort((a, b) {
                    final left = activeByWorker[a.id] ?? 0;
                    final right = activeByWorker[b.id] ?? 0;
                    final loadCompare = right.compareTo(left);
                    if (loadCompare != 0) {
                      return loadCompare;
                    }
                    return a.fullName.compareTo(b.fullName);
                  })))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkerBadge(
                      workerId: worker.id,
                      name: worker.fullName,
                      email: worker.email,
                      specialization: worker.specialization,
                      activeCount: activeByWorker[worker.id] ?? 0,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateWorkerSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'demo123');
    var specialization = 'cutting';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final sheetController = AppScope.of(sheetContext);
            final colorScheme = Theme.of(sheetContext).colorScheme;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: GlassPanel(
                backgroundColor: colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'НОВАЯ ШВЕЯ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Новая швея сразу появится в команде и сможет войти под своими данными.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Имя и фамилия'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Почта'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Пароль'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: specialization,
                      decoration:
                          const InputDecoration(labelText: 'Специализация'),
                      items: const [
                        DropdownMenuItem(
                          value: 'cutting',
                          child: Text('Лёгкие изделия'),
                        ),
                        DropdownMenuItem(
                          value: 'sewing',
                          child: Text('Базовый пошив'),
                        ),
                        DropdownMenuItem(
                          value: 'finishing',
                          child: Text('Финишная обработка'),
                        ),
                        DropdownMenuItem(
                          value: 'qc',
                          child: Text('Финальная проверка'),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(
                            () => specialization = value ?? 'cutting');
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: sheetController.isWorkerCreating
                          ? 'Создание...'
                          : 'Создать сотрудника',
                      onPressed: sheetController.isWorkerCreating
                          ? null
                          : () async {
                              final success =
                                  await sheetController.createProductionWorker(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                fullName: nameController.text.trim(),
                                specialization: specialization,
                              );
                              if (!sheetContext.mounted || !success) {
                                return;
                              }
                              Navigator.of(sheetContext).pop();
                            },
                    ),
                    if (sheetController.workerCreateError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        sheetController.workerCreateError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}

class _WorkerBadge extends StatelessWidget {
  const _WorkerBadge({
    required this.workerId,
    required this.name,
    required this.email,
    required this.specialization,
    required this.activeCount,
  });

  final String workerId;
  final String name;
  final String email;
  final String? specialization;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDeleting = controller.deleteWorkerId == workerId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                label: isDeleting ? 'Удаление...' : 'Удалить',
                isOutlined: true,
                isExpanded: false,
                minHeight: 36,
                fontSize: 9,
                onPressed: isDeleting
                    ? null
                    : () => _confirmDelete(context, controller),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(status: _workerSpecializationLabel(specialization)),
              StatusChip(
                status: activeCount == 0 ? 'Свободна' : '$activeCount в работе',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удалить швею'),
          content: Text('Удалить сотрудника $name? Действие потребует подтверждение.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.deleteProductionWorker(workerId);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? colorScheme.secondaryContainer : colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.secondaryContainer
                : colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _ManagerSection extends StatelessWidget {
  const _ManagerSection({
    required this.title,
    required this.subtitle,
    required this.tasks,
  });

  final String title;
  final String subtitle;
  final List<ProductionTask> tasks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      borderRadius: 30,
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
                      style: Theme.of(context).textTheme.headlineSmall,
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
              Text('${tasks.length}',
                  style: Theme.of(context).textTheme.headlineLarge),
            ],
          ),
          if (tasks.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Пусто',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ManagerTaskCard(task: task),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagerTaskCard extends StatelessWidget {
  const _ManagerTaskCard({required this.task});

  final ProductionTask task;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isAssigning = controller.assignTaskId == task.id;
    final matchingWorkers = List<User>.from(controller.productionWorkers)
      ..sort((a, b) {
        final leftMatches = a.specialization == task.operationStage ? 0 : 1;
        final rightMatches = b.specialization == task.operationStage ? 0 : 1;
        final specializationCompare = leftMatches.compareTo(rightMatches);
        if (specializationCompare != 0) {
          return specializationCompare;
        }
        final left = _activeLoadForWorker(controller.productionTasks, a.id);
        final right = _activeLoadForWorker(controller.productionTasks, b.id);
        final loadCompare = left.compareTo(right);
        if (loadCompare != 0) {
          return loadCompare;
        }
        return a.fullName.compareTo(b.fullName);
      });
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: _priorityAccentColor(task.priority, colorScheme),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(task.title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(width: 8),
              StatusChip(status: task.priority),
              const SizedBox(width: 8),
              StatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _managerTaskSubtitle(task),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _ManagerTaskFactStrip(
            items: [
              ('Код заказа', _displayTaskOrderCode(task)),
              ('Приоритет', statusLabel(task.priority)),
              ('Исполнитель', task.assignedToName ?? 'Не назначено'),
              ('ID', task.orderId),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatCompactDate(task.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          if (task.status != 'completed') ...[
            const SizedBox(height: 16),
            PrimaryButton(
              label: isAssigning
                  ? 'Назначение...'
                  : task.assignedTo == null
                      ? 'Назначить исполнителя'
                      : 'Сменить исполнителя',
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.primary,
              onPressed: isAssigning || matchingWorkers.isEmpty
                  ? null
                  : () => _showAssignSheet(
                        context,
                        controller,
                        matchingWorkers,
                      ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAssignSheet(
    BuildContext context,
    AppController controller,
    List<User> workers,
  ) async {
    final activeLoads = <String, int>{};
    for (final item in controller.productionTasks) {
      if (item.assignedTo == null || item.status == 'completed') {
        continue;
      }
      activeLoads.update(
        item.assignedTo!,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: GlassPanel(
            backgroundColor: colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'НАЗНАЧЕНИЕ',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _displayTaskOrderCode(task),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                _ManagerTaskFactStrip(
                  items: [
                    ('Код заказа', _displayTaskOrderCode(task)),
                    ('Приоритет', statusLabel(task.priority)),
                    ('Статус', statusLabel(task.status)),
                    ('ID', task.orderId),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Список швей',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      children: workers.map((worker) {
                        final activeCount = activeLoads[worker.id] ?? 0;
                        final isCurrent = task.assignedTo == worker.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AssignWorkerCard(
                            worker: worker,
                            activeCount: activeCount,
                            isCurrent: isCurrent,
                            isRecommended:
                                worker.specialization == task.operationStage,
                            onAssign: () async {
                              Navigator.of(sheetContext).pop();
                              await controller.assignTask(
                                task: task,
                                workerId: worker.id,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

int _activeLoadForWorker(List<ProductionTask> tasks, String workerId) {
  return tasks
      .where(
        (task) =>
            task.assignedTo == workerId &&
            task.status != 'completed' &&
            task.status != 'queued',
      )
      .length;
}

Color _priorityAccentColor(String priority, ColorScheme colorScheme) {
  switch (priority) {
    case 'high':
      return colorScheme.secondaryContainer;
    case 'medium':
      return colorScheme.primary.withValues(alpha: 0.72);
    default:
      return colorScheme.outline;
  }
}

String _formatCompactDate(String value) {
  if (value.length >= 16) {
    return value.substring(0, 16).replaceFirst('T', ' · ');
  }
  return value;
}

String _managerTaskSubtitle(ProductionTask task) {
  switch (task.status) {
    case 'queued':
      return 'Этап ждёт назначения исполнителя.';
    case 'assigned':
      return 'Этап закреплён за сотрудником и ждёт старта.';
    case 'in_progress':
      return 'Этап уже в работе и обновляется в реальном времени.';
    case 'completed':
      return 'Этап завершён. Результат уже учтён в процессе заказа.';
    default:
      return 'Статус задачи обновляется автоматически.';
  }
}

String? _workerBlockingReason(
  ProductionTask task,
  List<ProductionTask> workerTasks,
) {
  if (task.status != 'assigned') {
    return null;
  }

  final activeTask =
      workerTasks.where((item) => item.status == 'in_progress').firstOrNull;
  if (activeTask != null && activeTask.id != task.id) {
    return 'Сначала завершите этап, который уже в работе.';
  }

  final sameOrderTasks = workerTasks
      .where((item) => item.orderId == task.orderId)
      .toList();

  for (final item in sameOrderTasks) {
    if (_stageRank(item.operationStage) < _stageRank(task.operationStage) &&
        item.status != 'completed') {
      return 'Сначала завершите предыдущий этап этого заказа.';
    }
  }

  return null;
}

class _ManagerTaskFactStrip extends StatelessWidget {
  const _ManagerTaskFactStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 128, maxWidth: 168),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(22),
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

class _AssignWorkerCard extends StatelessWidget {
  const _AssignWorkerCard({
    required this.worker,
    required this.activeCount,
    required this.isCurrent,
    required this.isRecommended,
    required this.onAssign,
  });

  final User worker;
  final int activeCount;
  final bool isCurrent;
  final bool isRecommended;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.secondaryContainer.withValues(alpha: 0.45)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isCurrent
              ? colorScheme.secondaryContainer
              : colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  worker.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isRecommended && !isCurrent)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Рекомендовано',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontSize: 10,
                        ),
                  ),
                ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ТЕКУЩИЙ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontSize: 10,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            worker.email,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _ManagerTaskFactStrip(
            items: [
              ('Специализация', _workerSpecializationLabel(worker.specialization)),
              (
                'Загрузка',
                activeCount == 0 ? 'Свободен' : '$activeCount в работе'
              ),
            ],
          ),
          const SizedBox(height: 16),
            PrimaryButton(
              label: isCurrent ? 'Назначен' : 'Назначить',
            isOutlined: isCurrent,
            backgroundColor:
                isCurrent ? null : colorScheme.secondaryContainer,
            foregroundColor:
                isCurrent ? null : colorScheme.primary,
            onPressed: isCurrent ? null : onAssign,
          ),
        ],
      ),
    );
  }
}

class _WorkerTaskCard extends StatelessWidget {
  const _WorkerTaskCard({
    required this.task,
    this.isPriority = false,
    this.canAct = true,
    this.helperMessage,
  });

  final ProductionTask task;
  final bool isPriority;
  final bool canAct;
  final String? helperMessage;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isBusy = controller.taskActionId == task.id;
    final colorScheme = Theme.of(context).colorScheme;

    final action = switch (task.status) {
      'assigned' => (
          label: isBusy ? 'Запуск...' : 'Взять в работу',
          onTap: () => controller.startTask(task),
        ),
      'in_progress' => (
          label: isBusy ? 'Завершение...' : 'Завершить этап',
          onTap: () => controller.completeTask(task),
        ),
      _ => null,
    };

    return GlassPanel(
      backgroundColor: isPriority ? colorScheme.primary : colorScheme.surface,
      borderColor: isPriority ? colorScheme.primary : colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isPriority
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: task.priority),
              const SizedBox(width: 8),
              StatusChip(status: task.status),
            ],
          ),
          const SizedBox(height: 16),
          _Line(
            label: 'order_code',
            value: _displayTaskOrderCode(task),
            color: isPriority ? colorScheme.onPrimary : null,
          ),
          _Line(
            label: 'operation_stage',
            value: _operationLabel(task.operationStage),
            color: isPriority ? colorScheme.onPrimary : null,
          ),
          _Line(
            label: 'priority',
            value: statusLabel(task.priority),
            color: isPriority ? colorScheme.onPrimary : null,
          ),
          _Line(
            label: 'assigned_to_name',
            value: task.assignedToName ?? '-',
            color: isPriority ? colorScheme.onPrimary : null,
          ),
          _Line(
            label: 'started_at',
            value: task.startedAt ?? '-',
            color: isPriority ? colorScheme.onPrimary : null,
          ),
          _Line(
            label: 'completed_at',
            value: task.completedAt ?? '-',
            color: isPriority ? colorScheme.onPrimary : null,
          ),
          if (action != null && canAct) ...[
            const SizedBox(height: 24),
            PrimaryButton(
              label: action.label,
              minHeight: isPriority ? 78 : 62,
              fontSize: isPriority ? 16 : 14,
              backgroundColor:
                  isPriority
                      ? colorScheme.secondaryContainer
                      : colorScheme.primary,
              foregroundColor:
                  isPriority ? colorScheme.primary : colorScheme.onPrimary,
              onPressed: isBusy
                  ? null
                  : () async {
                      await action.onTap();
                      if (!context.mounted || controller.productionError != null) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_successMessageForTask(task)),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
          ] else if (helperMessage != null) ...[
            const SizedBox(height: 18),
            Text(
              helperMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPriority
                        ? colorScheme.onPrimary.withValues(alpha: 0.82)
                        : colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String _successMessageForTask(ProductionTask task) {
    switch (task.status) {
      case 'assigned':
        return 'Этап взят в работу.';
      case 'in_progress':
        return task.operationStage == 'qc'
            ? 'Финальный этап завершён. Заказ переведён в готово.'
            : 'Этап завершён. Следующая задача перейдёт менеджеру.';
      default:
        return 'Изменения сохранены.';
    }
  }
}

class _ProductionHero extends StatelessWidget {
  const _ProductionHero({
    required this.user,
    required this.queuedCount,
    required this.assignedCount,
    required this.inProgressCount,
    required this.completedCount,
  });

  final User user;
  final int queuedCount;
  final int assignedCount;
  final int inProgressCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isManager = user.productionType == 'manager';
    final colorScheme = theme.colorScheme;
    final waitingCount = queuedCount + assignedCount;

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isManager ? 'ОБЗОР ЦЕХА' : 'МОИ ЗАДАЧИ',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isManager ? 'Очередь и команда' : 'Рабочая смена',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isManager
                ? 'Назначения, загрузка и контроль готовности.'
                : 'Быстрый доступ к личным задачам и этапам.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final stats = [
                _DarkStat(value: '$inProgressCount', label: 'В работе'),
                _DarkStat(value: '$waitingCount', label: 'Ожидают'),
                _DarkStat(value: '$completedCount', label: 'Завершено'),
              ];

              return compact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: stats[0]),
                            const SizedBox(width: 10),
                            Expanded(child: stats[1]),
                          ],
                        ),
                        const SizedBox(height: 10),
                        stats[2],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: stats[0]),
                        const SizedBox(width: 10),
                        Expanded(child: stats[1]),
                        const SizedBox(width: 10),
                        Expanded(child: stats[2]),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _DarkStat extends StatelessWidget {
  const _DarkStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

String _workerSpecializationLabel(String? value) {
  switch (value) {
    case 'cutting':
      return 'Лёгкие изделия';
    case 'sewing':
      return 'Базовый пошив';
    case 'finishing':
      return 'Финишная обработка';
    case 'qc':
      return 'Финальная проверка';
    default:
      return 'Без профиля';
  }
}

String _operationLabel(String? value) {
  switch (value) {
    case 'cutting':
      return 'Подготовка изделия';
    case 'sewing':
      return 'Основной пошив';
    case 'finishing':
      return 'Финишная обработка';
    case 'qc':
      return 'Финальная проверка';
    default:
      return 'Этап заказа';
  }
}

String _displayTaskOrderCode(ProductionTask task) {
  if (task.orderCode.trim().isNotEmpty) {
    return task.orderCode;
  }
  return task.orderId;
}

int _stageRank(String? value) {
  switch (value) {
    case 'cutting':
      return 0;
    case 'sewing':
      return 1;
    case 'finishing':
      return 2;
    case 'qc':
      return 3;
    default:
      return 4;
  }
}

String _shortStageLabel(String? value) {
  switch (value) {
    case 'cutting':
      return 'Подготовка';
    case 'sewing':
      return 'Пошив';
    case 'finishing':
      return 'Финиш';
    case 'qc':
      return 'Проверка';
    default:
      return 'Этап';
  }
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
              _Line(label: 'full_name', value: user.fullName),
              _Line(label: 'email', value: user.email),
              _Line(label: 'role', value: roleValueLabel(user.role.value)),
              _Line(
                label: 'production_type',
                value: productionTypeLabel(user.productionType),
              ),
              _Line(
                label: 'specialization',
                value: _workerSpecializationLabel(user.specialization),
              ),
              _Line(label: 'franchise_id', value: user.franchiseId ?? '-'),
              _Line(label: 'created_at', value: user.createdAt),
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
              _ProductionSwitch(
                title: 'Уведомления',
                value: controller.notificationsEnabled,
                onChanged: controller.setNotificationsEnabled,
              ),
              _ProductionSwitch(
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

class _ProductionSwitch extends StatelessWidget {
  const _ProductionSwitch({
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

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).colorScheme.onSurface;
    final secondaryColor = color == null
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : color!.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              fieldLabel(label).toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    color: secondaryColor,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: baseColor,
                  ),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

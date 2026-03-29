import '../models/order.dart';
import '../models/product.dart';
import '../models/production_task.dart';
import '../models/session.dart';
import '../models/user.dart';
import 'app_repository.dart';

class MockRepository implements AppRepository {
  MockRepository() {
    _seed();
  }

  final List<User> _users = [];
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<ProductionTask> _tasks = [];
  final Map<String, String> _passwordByEmail = {};
  String? _lastEmail;

  int _orderCounter = 1;
  int _taskCounter = 1;

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final normalizedEmail = email.trim().toLowerCase();

    if (_passwordByEmail[normalizedEmail] != password) {
      throw Exception('Неверные учетные данные.');
    }

    final user =
        _users.where((item) => item.email == normalizedEmail).firstOrNull;
    if (user == null) {
      throw Exception('Для этой почты не найден демо-пользователь.');
    }

    _lastEmail = user.email;
    return Session(token: 'mock-token-${user.id}', user: user);
  }

  @override
  Future<Session> registerClient({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final normalizedEmail = email.trim().toLowerCase();
    if (_users.any((item) => item.email == normalizedEmail)) {
      throw Exception('Пользователь с такой почтой уже существует.');
    }

    final user = User(
      id: 'user_${_users.length + 1}',
      email: normalizedEmail,
      fullName: fullName.trim(),
      role: UserRole.client,
      productionType: null,
      specialization: null,
      franchiseId: '1',
      createdAt: DateTime.now().toIso8601String(),
    );
    _users.add(user);
    _passwordByEmail[normalizedEmail] = password;
    _lastEmail = user.email;
    return Session(token: 'mock-token-${user.id}', user: user);
  }

  @override
  Future<List<Product>> getProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<Product>.from(_products.where((item) => item.isActive));
  }

  @override
  Future<void> createOrder({
    required String clientId,
    required String franchiseId,
    required String productId,
    required String productTitle,
    required int quantity,
    required String orderType,
    required String selectedReadyDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final order = Order(
      id: 'order_${_orderCounter.toString().padLeft(3, '0')}',
      orderCode: _nextOrderCode(DateTime.now()),
      clientId: clientId,
      franchiseId: franchiseId,
      productId: productId,
      productTitle: productTitle,
      quantity: quantity,
      orderType: orderType,
      selectedReadyDate: selectedReadyDate,
      status: 'placed',
      trackingStage: 'placed',
      loyaltyProgress: 0,
      createdAt: DateTime.now().toIso8601String(),
    );

    _orderCounter += 1;
    _orders.insert(0, order);
  }

  @override
  Future<List<Order>> getClientOrders(String clientId, {String? orderCode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final query = orderCode?.trim().toUpperCase() ?? '';
    return _orders.where((item) {
      if (item.clientId != clientId) {
        return false;
      }
      return query.isEmpty || item.orderCode.startsWith(query);
    }).toList();
  }

  @override
  Future<List<Order>> getFranchiseOrders(String franchiseId, {String? orderCode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final query = orderCode?.trim().toUpperCase() ?? '';
    return _orders.where((item) {
      if (item.franchiseId != franchiseId) {
        return false;
      }
      return query.isEmpty || item.orderCode.startsWith(query);
    }).toList();
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final orderIndex = _orders.indexWhere((item) => item.id == orderId);
    if (orderIndex == -1) {
      throw Exception('Заказ не найден.');
    }

    final current = _orders[orderIndex];
    _orders[orderIndex] = current.copyWith(
      status: status,
      trackingStage: status,
    );

    if (status == 'in_production' &&
        !_tasks.any((item) => item.orderId == orderId)) {
      for (final stage in ['cutting', 'sewing', 'finishing', 'qc']) {
        _tasks.insert(
          0,
          ProductionTask(
            id: 'task_${_taskCounter.toString().padLeft(3, '0')}',
            orderId: orderId,
            orderCode: current.orderCode,
            franchiseId: current.franchiseId,
            title: '${current.productTitle} · ${stage.toUpperCase()}',
            priority: current.orderType == 'in_stock' ? 'high' : 'medium',
            assignedTo: null,
            assignedToName: null,
            createdBy: 'user_franchisee',
            status: 'queued',
            operationStage: stage,
            startedAt: null,
            completedAt: null,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
        _taskCounter += 1;
      }
    }
  }

  @override
  Future<List<ProductionTask>> getProductionTasks(String franchiseId, {String? orderCode}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final currentUser =
        _users.where((item) => item.email == _lastEmail).firstOrNull;
    final query = orderCode?.trim().toUpperCase() ?? '';
    return _tasks.where((item) {
      if (item.franchiseId != franchiseId) {
        return false;
      }
      if (query.isNotEmpty && !item.orderCode.startsWith(query)) {
        return false;
      }
      if (currentUser?.productionType == 'worker') {
        return item.assignedTo == currentUser?.id;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<User>> getProductionWorkers(String franchiseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _users
        .where(
          (item) =>
              item.role == UserRole.production &&
              item.productionType == 'worker' &&
              item.franchiseId == franchiseId,
        )
        .toList();
  }

  @override
  Future<User> createProductionWorker({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final normalizedEmail = email.trim().toLowerCase();
    if (_users.any((item) => item.email == normalizedEmail)) {
      throw Exception('Пользователь с такой почтой уже существует.');
    }

    final worker = User(
      id: 'user_worker_${_users.length + 1}',
      email: normalizedEmail,
      fullName: fullName.trim(),
      role: UserRole.production,
      productionType: 'worker',
      specialization: specialization.trim(),
      franchiseId: 'franchise_001',
      createdAt: DateTime.now().toIso8601String(),
    );
    _users.add(worker);
    _passwordByEmail[normalizedEmail] = password;
    return worker;
  }

  @override
  Future<void> deleteProductionWorker(String workerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final hasActiveTasks = _tasks.any(
      (item) =>
          item.assignedTo == workerId &&
          item.status != 'completed',
    );
    if (hasActiveTasks) {
      throw Exception('Нельзя удалить швею, пока на ней есть активные задачи.');
    }

    for (var index = 0; index < _tasks.length; index++) {
      final task = _tasks[index];
      if (task.assignedTo == workerId) {
        _tasks[index] = task.copyWith(
          assignedTo: null,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
    }

    final userIndex = _users.indexWhere((item) => item.id == workerId);
    if (userIndex == -1) {
      throw Exception('Швея не найдена.');
    }
    final email = _users[userIndex].email;
    _users.removeAt(userIndex);
    _passwordByEmail.remove(email);
  }

  @override
  Future<void> assignTask({
    required String taskId,
    required String workerId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final taskIndex = _tasks.indexWhere((item) => item.id == taskId);
    final worker = _users.where((item) => item.id == workerId).firstOrNull;
    if (taskIndex == -1 || worker == null) {
      throw Exception('Не удалось назначить задачу.');
    }
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(
      assignedTo: worker.id,
      assignedToName: worker.fullName,
      status: 'assigned',
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> startTask(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final taskIndex = _tasks.indexWhere((item) => item.id == taskId);
    if (taskIndex == -1) {
      throw Exception('Производственная задача не найдена.');
    }
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(
      status: 'in_progress',
      startedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<void> completeTask(String taskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final taskIndex = _tasks.indexWhere((item) => item.id == taskId);
    if (taskIndex == -1) {
      throw Exception('Производственная задача не найдена.');
    }

    final task = _tasks[taskIndex];
    _tasks[taskIndex] = task.copyWith(
      status: 'completed',
      completedAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    final orderIndex = _orders.indexWhere((item) => item.id == task.orderId);
    final remaining = _tasks.where(
      (item) => item.orderId == task.orderId && item.status != 'completed',
    );
    if (orderIndex != -1 && remaining.isEmpty && task.operationStage == 'qc') {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: 'ready',
        trackingStage: 'ready',
      );
    } else if (orderIndex != -1) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: 'in_production',
        trackingStage: task.operationStage,
      );
    }
  }

  @override
  Future<User> updateProfile({
    required String fullName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final index = _users.indexWhere((item) => item.email == _lastEmail);
    if (index == -1) {
      throw Exception('Профиль не найден.');
    }

    final updated = _users[index].copyWith(fullName: fullName.trim());
    _users[index] = updated;
    return updated;
  }

  void _seed() {
    const franchiseId = 'franchise_001';

    _users.addAll(
      [
        User(
          id: 'user_client',
          email: 'client@avishu.com',
          fullName: 'Клиент AVISHU',
          role: UserRole.client,
          productionType: null,
          specialization: null,
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_franchisee',
          email: 'franchisee@avishu.com',
          fullName: 'Франчайзи AVISHU',
          role: UserRole.franchisee,
          productionType: null,
          specialization: null,
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_production_manager',
          email: 'production.manager@avishu.com',
          fullName: 'Менеджер цеха AVISHU',
          role: UserRole.production,
          productionType: 'manager',
          specialization: null,
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_worker_1',
          email: '1@gmail.com',
          fullName: 'Швея 1',
          role: UserRole.production,
          productionType: 'worker',
          specialization: 'sewing',
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_worker_2',
          email: '2@gmail.com',
          fullName: 'Швея 2',
          role: UserRole.production,
          productionType: 'worker',
          specialization: 'sewing',
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_worker_3',
          email: '3@gmail.com',
          fullName: 'Швея 3',
          role: UserRole.production,
          productionType: 'worker',
          specialization: 'sewing',
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
      ],
    );
    for (final user in _users) {
      _passwordByEmail[user.email] = 'demo123';
    }

    _products.addAll(
      const [
        Product(
          id: 'product_001',
          title: 'Футболка BRIGHT',
          description:
              'Минималистичная базовая футболка из женской линии AVISHU.',
          price: 15200,
          currency: '₸',
          imageUrl: 'https://avishu.kz/wp-content/uploads/2024/09/BRIGHT_madg5.webp',
          availabilityType: 'in_stock',
          defaultReadyDays: 2,
          isActive: true,
        ),
        Product(
          id: 'product_002',
          title: 'Лонгслив SKIN',
          description: 'Лаконичный лонгслив AVISHU для многослойных образов.',
          price: 22000,
          currency: '₸',
          imageUrl: 'https://avishu.kz/wp-content/uploads/2025/12/SKIN-cofee_1.webp',
          availabilityType: 'in_stock',
          defaultReadyDays: 2,
          isActive: true,
        ),
        Product(
          id: 'product_003',
          title: 'Юбка ALL.INN',
          description: 'Чистый силуэт с фирменной стилистикой AVISHU.',
          price: 23500,
          currency: '₸',
          imageUrl: 'https://avishu.kz/wp-content/uploads/2025/12/ALL.INN_skirt-bl1.webp',
          availabilityType: 'made_to_order',
          defaultReadyDays: 5,
          isActive: true,
        ),
        Product(
          id: 'product_004',
          title: 'Рубашка EVO',
          description:
              'Структурная рубашка AVISHU с акцентом на форму и посадку.',
          price: 27200,
          currency: '₸',
          imageUrl: 'https://avishu.kz/wp-content/uploads/2025/04/IMG_0335-1.webp',
          availabilityType: 'made_to_order',
          defaultReadyDays: 5,
          isActive: true,
        ),
        Product(
          id: 'product_005',
          title: 'LOOM худи',
          description: 'Объёмное худи AVISHU из женской коллекции.',
          price: 32000,
          currency: '₸',
          imageUrl: 'https://avishu.kz/wp-content/uploads/2025/11/loom_grey1.webp',
          availabilityType: 'made_to_order',
          defaultReadyDays: 6,
          isActive: true,
        ),
      ],
    );

    _orders.addAll(
      const [
        Order(
          id: 'order_001',
          orderCode: 'AV-20260327-0001',
          clientId: 'user_client',
          franchiseId: franchiseId,
          productId: 'product_001',
          productTitle: 'Футболка BRIGHT',
          quantity: 1,
          orderType: 'in_stock',
          selectedReadyDate: '2026-03-30',
          status: 'in_production',
          trackingStage: 'sewing',
          loyaltyProgress: 60,
          createdAt: '2026-03-27T09:00:00Z',
        ),
        Order(
          id: 'order_002',
          orderCode: 'AV-20260327-0002',
          clientId: 'user_client',
          franchiseId: franchiseId,
          productId: 'product_003',
          productTitle: 'Юбка ALL.INN',
          quantity: 1,
          orderType: 'made_to_order',
          selectedReadyDate: '2026-04-01',
          status: 'in_production',
          trackingStage: 'cutting',
          loyaltyProgress: 35,
          createdAt: '2026-03-27T12:00:00Z',
        ),
        Order(
          id: 'order_003',
          orderCode: 'AV-20260327-0003',
          clientId: 'user_client',
          franchiseId: franchiseId,
          productId: 'product_004',
          productTitle: 'Рубашка EVO',
          quantity: 1,
          orderType: 'made_to_order',
          selectedReadyDate: '2026-04-02',
          status: 'paid',
          trackingStage: 'paid',
          loyaltyProgress: 10,
          createdAt: '2026-03-27T16:00:00Z',
        ),
      ],
    );

    _tasks.addAll(
      const [
        ProductionTask(
          id: 'task_001',
          orderId: 'order_001',
          orderCode: 'AV-20260327-0001',
          franchiseId: franchiseId,
          title: 'Футболка BRIGHT · CUTTING',
          priority: 'high',
          assignedTo: 'user_worker_cutting',
          assignedToName: 'Раскрой AVISHU',
          createdBy: 'user_production_manager',
          status: 'completed',
          operationStage: 'cutting',
          startedAt: '2026-03-27T08:30:00Z',
          completedAt: '2026-03-27T09:20:00Z',
          createdAt: '2026-03-27T08:00:00Z',
          updatedAt: '2026-03-27T09:20:00Z',
        ),
        ProductionTask(
          id: 'task_002',
          orderId: 'order_001',
          orderCode: 'AV-20260327-0001',
          franchiseId: franchiseId,
          title: 'Футболка BRIGHT · SEWING',
          priority: 'high',
          assignedTo: 'user_worker_sewing',
          assignedToName: 'Пошив AVISHU',
          createdBy: 'user_production_manager',
          status: 'in_progress',
          operationStage: 'sewing',
          startedAt: '2026-03-27T11:00:00Z',
          completedAt: null,
          createdAt: '2026-03-27T08:00:00Z',
          updatedAt: '2026-03-27T11:00:00Z',
        ),
        ProductionTask(
          id: 'task_003',
          orderId: 'order_001',
          orderCode: 'AV-20260327-0001',
          franchiseId: franchiseId,
          title: 'Футболка BRIGHT · FINISHING',
          priority: 'medium',
          assignedTo: null,
          assignedToName: null,
          createdBy: 'user_production_manager',
          status: 'queued',
          operationStage: 'finishing',
          startedAt: null,
          completedAt: null,
          createdAt: '2026-03-27T08:00:00Z',
          updatedAt: '2026-03-27T08:00:00Z',
        ),
        ProductionTask(
          id: 'task_004',
          orderId: 'order_001',
          orderCode: 'AV-20260327-0001',
          franchiseId: franchiseId,
          title: 'Футболка BRIGHT · QC',
          priority: 'medium',
          assignedTo: null,
          assignedToName: null,
          createdBy: 'user_production_manager',
          status: 'queued',
          operationStage: 'qc',
          startedAt: null,
          completedAt: null,
          createdAt: '2026-03-27T08:00:00Z',
          updatedAt: '2026-03-27T08:00:00Z',
        ),
        ProductionTask(
          id: 'task_005',
          orderId: 'order_002',
          orderCode: 'AV-20260327-0002',
          franchiseId: franchiseId,
          title: 'Юбка ALL.INN · CUTTING',
          priority: 'medium',
          assignedTo: 'user_worker_cutting',
          assignedToName: 'Раскрой AVISHU',
          createdBy: 'user_production_manager',
          status: 'assigned',
          operationStage: 'cutting',
          startedAt: null,
          completedAt: null,
          createdAt: '2026-03-27T12:00:00Z',
          updatedAt: '2026-03-27T12:40:00Z',
        ),
        ProductionTask(
          id: 'task_006',
          orderId: 'order_002',
          orderCode: 'AV-20260327-0002',
          franchiseId: franchiseId,
          title: 'Юбка ALL.INN · SEWING',
          priority: 'medium',
          assignedTo: null,
          assignedToName: null,
          createdBy: 'user_production_manager',
          status: 'queued',
          operationStage: 'sewing',
          startedAt: null,
          completedAt: null,
          createdAt: '2026-03-27T12:00:00Z',
          updatedAt: '2026-03-27T12:00:00Z',
        ),
        ProductionTask(
          id: 'task_007',
          orderId: 'order_002',
          orderCode: 'AV-20260327-0002',
          franchiseId: franchiseId,
          title: 'Юбка ALL.INN · FINISHING',
          priority: 'medium',
          assignedTo: null,
          assignedToName: null,
          createdBy: 'user_production_manager',
          status: 'queued',
          operationStage: 'finishing',
          startedAt: null,
          completedAt: null,
          createdAt: '2026-03-27T12:00:00Z',
          updatedAt: '2026-03-27T12:00:00Z',
        ),
        ProductionTask(
          id: 'task_008',
          orderId: 'order_002',
          orderCode: 'AV-20260327-0002',
          franchiseId: franchiseId,
          title: 'Юбка ALL.INN · QC',
          priority: 'low',
          assignedTo: null,
          assignedToName: null,
          createdBy: 'user_production_manager',
          status: 'queued',
          operationStage: 'qc',
          startedAt: null,
          completedAt: null,
          createdAt: '2026-03-27T12:00:00Z',
          updatedAt: '2026-03-27T12:00:00Z',
        ),
      ],
    );

    _orderCounter = 4;
    _taskCounter = 9;
  }

  @override
  void dispose() {}

  String _nextOrderCode(DateTime now) {
    final prefix = 'AV-${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-';
    var nextNumber = 1;
    for (final order in _orders) {
      if (!order.orderCode.startsWith(prefix)) {
        continue;
      }
      final suffix = order.orderCode.split('-').last;
      final parsed = int.tryParse(suffix);
      if (parsed != null && parsed >= nextNumber) {
        nextNumber = parsed + 1;
      }
    }
    return '$prefix${nextNumber.toString().padLeft(4, '0')}';
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

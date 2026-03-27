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

  int _orderCounter = 1;
  int _taskCounter = 1;

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (password != 'demo123') {
      throw Exception('Неверные учетные данные.');
    }

    final user = _users.where((item) => item.email == email).firstOrNull;
    if (user == null) {
      throw Exception('Для этой почты не найден демо-пользователь.');
    }

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

    final task = ProductionTask(
      id: 'task_${_taskCounter.toString().padLeft(3, '0')}',
      orderId: order.id,
      franchiseId: franchiseId,
      title: productTitle,
      status: 'queued',
      operationStage: 'queued',
      createdAt: DateTime.now().toIso8601String(),
    );

    _orderCounter += 1;
    _taskCounter += 1;
    _orders.insert(0, order);
    _tasks.insert(0, task);
  }

  @override
  Future<List<Order>> getClientOrders(String clientId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _orders.where((item) => item.clientId == clientId).toList();
  }

  @override
  Future<List<Order>> getFranchiseOrders(String franchiseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _orders.where((item) => item.franchiseId == franchiseId).toList();
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

    final taskIndex = _tasks.indexWhere((item) => item.orderId == orderId);
    if (taskIndex != -1 && status == 'in_production') {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: 'active',
        operationStage: 'active',
      );
    }
  }

  @override
  Future<List<ProductionTask>> getProductionTasks(String franchiseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _tasks.where((item) => item.franchiseId == franchiseId).toList();
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
      operationStage: 'completed',
    );

    final orderIndex = _orders.indexWhere((item) => item.id == task.orderId);
    if (orderIndex != -1) {
      _orders[orderIndex] = _orders[orderIndex].copyWith(
        status: 'ready',
        trackingStage: 'ready',
      );
    }
  }

  void _seed() {
    const franchiseId = 'franchise_001';

    _users.addAll(
      [
        User(
          id: 'user_client',
          email: 'client@avishu.app',
          fullName: 'AVISHU Клиент',
          role: UserRole.client,
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_franchisee',
          email: 'franchisee@avishu.app',
          fullName: 'AVISHU Франчайзи',
          role: UserRole.franchisee,
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
        User(
          id: 'user_production',
          email: 'production@avishu.app',
          fullName: 'AVISHU Производство',
          role: UserRole.production,
          franchiseId: franchiseId,
          createdAt: '2026-03-27T00:00:00Z',
        ),
      ],
    );

    _products.addAll(
      const [
        Product(
          id: 'product_001',
          title: 'Приталенный жакет',
          description: 'Структурный монохромный жакет для премиального образа.',
          price: 89000,
          currency: '₸',
          imageUrl: '',
          availabilityType: 'made_to_order',
          defaultReadyDays: 5,
          isActive: true,
        ),
        Product(
          id: 'product_002',
          title: 'Редакционное платье',
          description: 'Минималистичный силуэт с кутюрной отделкой.',
          price: 125000,
          currency: '₸',
          imageUrl: '',
          availabilityType: 'made_to_order',
          defaultReadyDays: 7,
          isActive: true,
        ),
        Product(
          id: 'product_003',
          title: 'Фирменная рубашка',
          description: 'Премиальная рубашка с чистым кроем на каждый день.',
          price: 54000,
          currency: '₸',
          imageUrl: '',
          availabilityType: 'in_stock',
          defaultReadyDays: 2,
          isActive: true,
        ),
      ],
    );
  }

  @override
  void dispose() {}
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

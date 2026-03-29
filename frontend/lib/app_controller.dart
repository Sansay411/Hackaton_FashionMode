import 'package:flutter/widgets.dart';

import 'core/config/app_config.dart';
import 'data/models/order.dart';
import 'data/models/product.dart';
import 'data/models/production_task.dart';
import 'data/models/session.dart';
import 'data/models/user.dart';
import 'data/repositories/api_repository.dart';
import 'data/repositories/app_repository.dart';
import 'data/repositories/mock_repository.dart';
import 'data/services/http_client.dart';
import 'data/services/realtime_sync_service.dart';

class AppController extends ChangeNotifier {
  AppController({required this.config})
      : _mockRepository = MockRepository(),
        _syncService = RealtimeSyncService() {
    _httpClient = HttpClientService(
      baseUrl: config.apiBaseUrl,
      tokenProvider: () => _session?.token,
    );
    _apiRepository = ApiRepository(_httpClient);
    _activeRepository = config.useMock ? _mockRepository : _apiRepository;
    isUsingMock = config.useMock;
    modeMessage = config.useMock
        ? 'Приложение работает в демонстрационном режиме без сервера.'
        : null;
  }

  final AppConfig config;
  final MockRepository _mockRepository;
  late final HttpClientService _httpClient;
  final RealtimeSyncService _syncService;
  late final ApiRepository _apiRepository;
  late AppRepository _activeRepository;

  Session? _session;

  Session? get session => _session;
  User? get currentUser => _session?.user;

  bool isUsingMock = false;
  bool isRealtimeConnected = false;
  String? modeMessage;
  bool isAuthenticating = false;
  bool isRegistering = false;
  bool isProfileSaving = false;
  bool isProductsLoading = false;
  bool isClientOrdersLoading = false;
  bool isFranchiseeOrdersLoading = false;
  bool isProductionTasksLoading = false;
  bool isWorkerCreating = false;
  String? deleteWorkerId;
  String? authError;
  String? registerError;
  String? clientError;
  String? franchiseeError;
  String? productionError;
  String? workerCreateError;
  String? profileError;
  String? createOrderProductId;
  String? orderActionId;
  String? taskActionId;
  String? assignTaskId;
  String? payOrderId;
  bool notificationsEnabled = true;
  bool instantUpdatesEnabled = true;
  bool editorialCardsEnabled = true;
  bool compactModeEnabled = false;
  bool biometricLockEnabled = false;
  bool showOrderHintsEnabled = true;
  bool autoOpenCartEnabled = true;
  bool priorityFirstEnabled = true;
  bool showTeamLoadEnabled = true;
  String clientOrderSearchQuery = '';
  String franchiseeOrderSearchQuery = '';
  String productionOrderCodeSearchQuery = '';

  List<Product> products = const [];
  List<Order> clientOrders = const [];
  List<Order> franchiseeOrders = const [];
  List<ProductionTask> productionTasks = const [];
  List<User> productionWorkers = const [];
  final Map<String, int> cartQuantities = <String, int>{};

  int get cartItemsCount =>
      cartQuantities.values.fold(0, (sum, value) => sum + value);

  List<({Product product, int quantity})> get cartItems {
    return cartQuantities.entries
        .map((entry) {
          Product? product;
          for (final item in products) {
            if (item.id == entry.key) {
              product = item;
              break;
            }
          }
          if (product == null) {
            return null;
          }
          return (product: product, quantity: entry.value);
        })
        .whereType<({Product product, int quantity})>()
        .toList();
  }

  double get cartTotal {
    return cartItems.fold(
      0,
      (sum, item) => sum + (item.product.price.toDouble() * item.quantity),
    );
  }

  Future<void> bootstrap() async {
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isAuthenticating = true;
    authError = null;
    registerError = null;
    notifyListeners();

    try {
      _session = await _activeRepository.login(
        email: email,
        password: password,
      );
      await refreshForCurrentRole();
      _startSync();
      return true;
    } catch (error) {
      authError = _messageFor(error);
      return false;
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<bool> registerClient({
    required String fullName,
    required String email,
    required String password,
  }) async {
    isRegistering = true;
    registerError = null;
    authError = null;
    notifyListeners();

    try {
      _session = await _activeRepository.registerClient(
        email: email,
        password: password,
        fullName: fullName,
      );
      await refreshForCurrentRole();
      _startSync();
      return true;
    } catch (error) {
      registerError = _messageFor(error);
      return false;
    } finally {
      isRegistering = false;
      notifyListeners();
    }
  }

  Future<void> refreshForCurrentRole({bool silent = false}) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    switch (user.role) {
      case UserRole.client:
        await _loadClientData(user, silent: silent);
        break;
      case UserRole.franchisee:
        await _loadFranchiseeData(user, silent: silent);
        break;
      case UserRole.production:
        await _loadProductionData(user, silent: silent);
        break;
    }
  }

  Future<void> createOrder({
    required Product product,
    required int quantity,
    required String selectedReadyDate,
  }) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    createOrderProductId = product.id;
    clientError = null;
    notifyListeners();

    try {
      await _activeRepository.createOrder(
        clientId: user.id,
        franchiseId: user.franchiseId ?? '',
        productId: product.id,
        productTitle: product.title,
        quantity: quantity,
        orderType: product.availabilityType,
        selectedReadyDate: selectedReadyDate,
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      clientError = _messageFor(error);
    } finally {
      createOrderProductId = null;
      notifyListeners();
    }
  }

  Future<void> payOrder(Order order) async {
    payOrderId = order.id;
    clientError = null;
    final index = clientOrders.indexWhere((item) => item.id == order.id);
    final previous = index == -1 ? null : clientOrders[index];
    if (index != -1) {
      clientOrders = List<Order>.from(clientOrders)
        ..[index] = clientOrders[index].copyWith(
          status: 'paid',
          trackingStage: 'paid',
        );
    }
    notifyListeners();

    try {
      await _activeRepository.updateOrderStatus(
        orderId: order.id,
        status: 'paid',
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      if (index != -1 && previous != null) {
        clientOrders = List<Order>.from(clientOrders)..[index] = previous;
      }
      clientError = _messageFor(error);
    } finally {
      payOrderId = null;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(Order order, String status) async {
    orderActionId = order.id;
    franchiseeError = null;
    clientError = null;
    notifyListeners();

    try {
      await _activeRepository.updateOrderStatus(
        orderId: order.id,
        status: status,
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      if (currentUser?.role == UserRole.client) {
        clientError = _messageFor(error);
      } else if (currentUser?.role == UserRole.franchisee) {
        franchiseeError = _messageFor(error);
      }
    } finally {
      orderActionId = null;
      notifyListeners();
    }
  }

  Future<void> completeTask(ProductionTask task) async {
    taskActionId = task.id;
    productionError = null;
    final index = productionTasks.indexWhere((item) => item.id == task.id);
    final previous = index == -1 ? null : productionTasks[index];
    if (index != -1) {
      productionTasks = List<ProductionTask>.from(productionTasks)
        ..[index] = productionTasks[index].copyWith(
          status: 'completed',
          completedAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
    }
    notifyListeners();

    try {
      await _activeRepository.completeTask(task.id);
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      if (index != -1 && previous != null) {
        productionTasks = List<ProductionTask>.from(productionTasks)
          ..[index] = previous;
      }
      productionError = _messageFor(error);
    } finally {
      taskActionId = null;
      notifyListeners();
    }
  }

  Future<void> assignTask({
    required ProductionTask task,
    required String workerId,
  }) async {
    assignTaskId = task.id;
    productionError = null;
    notifyListeners();

    try {
      await _activeRepository.assignTask(
        taskId: task.id,
        workerId: workerId,
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      productionError = _messageFor(error);
    } finally {
      assignTaskId = null;
      notifyListeners();
    }
  }

  Future<bool> createProductionWorker({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
  }) async {
    isWorkerCreating = true;
    workerCreateError = null;
    productionError = null;
    notifyListeners();

    try {
      await _activeRepository.createProductionWorker(
        email: email,
        password: password,
        fullName: fullName,
        specialization: specialization,
      );
      await refreshForCurrentRole(silent: true);
      return true;
    } catch (error) {
      workerCreateError = _messageFor(error);
      productionError = workerCreateError;
      return false;
    } finally {
      isWorkerCreating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProductionWorker(String workerId) async {
    deleteWorkerId = workerId;
    workerCreateError = null;
    productionError = null;
    notifyListeners();

    try {
      await _activeRepository.deleteProductionWorker(workerId);
      await refreshForCurrentRole(silent: true);
      return true;
    } catch (error) {
      workerCreateError = _messageFor(error);
      productionError = workerCreateError;
      return false;
    } finally {
      deleteWorkerId = null;
      notifyListeners();
    }
  }

  Future<void> startTask(ProductionTask task) async {
    taskActionId = task.id;
    productionError = null;
    final index = productionTasks.indexWhere((item) => item.id == task.id);
    final previous = index == -1 ? null : productionTasks[index];
    if (index != -1) {
      productionTasks = List<ProductionTask>.from(productionTasks)
        ..[index] = productionTasks[index].copyWith(
          status: 'in_progress',
          startedAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
    }
    notifyListeners();

    try {
      await _activeRepository.startTask(task.id);
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      if (index != -1 && previous != null) {
        productionTasks = List<ProductionTask>.from(productionTasks)
          ..[index] = previous;
      }
      productionError = _messageFor(error);
    } finally {
      taskActionId = null;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
  }) async {
    if (_session == null) {
      return false;
    }

    isProfileSaving = true;
    profileError = null;
    notifyListeners();

    try {
      final updatedUser = await _activeRepository.updateProfile(
        fullName: fullName,
      );
      _session = Session(token: _session!.token, user: updatedUser);
      return true;
    } catch (error) {
      profileError = _messageFor(error);
      return false;
    } finally {
      isProfileSaving = false;
      notifyListeners();
    }
  }

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void setInstantUpdatesEnabled(bool value) {
    instantUpdatesEnabled = value;
    notifyListeners();
  }

  void setEditorialCardsEnabled(bool value) {
    editorialCardsEnabled = value;
    notifyListeners();
  }

  void setCompactModeEnabled(bool value) {
    compactModeEnabled = value;
    notifyListeners();
  }

  void setBiometricLockEnabled(bool value) {
    biometricLockEnabled = value;
    notifyListeners();
  }

  void setShowOrderHintsEnabled(bool value) {
    showOrderHintsEnabled = value;
    notifyListeners();
  }

  void setAutoOpenCartEnabled(bool value) {
    autoOpenCartEnabled = value;
    notifyListeners();
  }

  void setPriorityFirstEnabled(bool value) {
    priorityFirstEnabled = value;
    notifyListeners();
  }

  void setShowTeamLoadEnabled(bool value) {
    showTeamLoadEnabled = value;
    notifyListeners();
  }

  Future<void> setClientOrderSearchQuery(String value) async {
    clientOrderSearchQuery = value.trim().toUpperCase();
    await refreshForCurrentRole(silent: true);
  }

  Future<void> setFranchiseeOrderSearchQuery(String value) async {
    franchiseeOrderSearchQuery = value.trim().toUpperCase();
    await refreshForCurrentRole(silent: true);
  }

  Future<void> setProductionOrderCodeSearchQuery(String value) async {
    productionOrderCodeSearchQuery = value.trim().toUpperCase();
    await refreshForCurrentRole(silent: true);
  }

  void addToCart(Product product) {
    cartQuantities.update(product.id, (value) => value + 1, ifAbsent: () => 1);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      cartQuantities.remove(productId);
    } else {
      cartQuantities[productId] = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    cartQuantities.clear();
    notifyListeners();
  }

  void logout() {
    _syncService.stop();
    _session = null;
    products = const [];
    clientOrders = const [];
    franchiseeOrders = const [];
    productionTasks = const [];
    productionWorkers = const [];
    cartQuantities.clear();
    authError = null;
    registerError = null;
    clientError = null;
    franchiseeError = null;
    productionError = null;
    workerCreateError = null;
    deleteWorkerId = null;
    profileError = null;
    createOrderProductId = null;
    orderActionId = null;
    taskActionId = null;
    assignTaskId = null;
    payOrderId = null;
    clientOrderSearchQuery = '';
    franchiseeOrderSearchQuery = '';
    productionOrderCodeSearchQuery = '';
    if (!config.useMock) {
      isUsingMock = false;
      isRealtimeConnected = false;
      modeMessage = null;
      _activeRepository = _apiRepository;
    }
    notifyListeners();
  }

  Future<void> _loadClientData(User user, {required bool silent}) async {
    if (!silent) {
      isProductsLoading = true;
      isClientOrdersLoading = true;
      clientError = null;
      notifyListeners();
    }

    try {
      final fetchedProducts = await _activeRepository.getProducts();
      final fetchedOrders = await _activeRepository.getClientOrders(
        user.id,
        orderCode: clientOrderSearchQuery,
      );
      products = fetchedProducts;
      clientOrders = fetchedOrders;
    } catch (error) {
      clientError = _messageFor(error);
    } finally {
      isProductsLoading = false;
      isClientOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFranchiseeData(User user, {required bool silent}) async {
    if (!silent) {
      isFranchiseeOrdersLoading = true;
      franchiseeError = null;
      notifyListeners();
    }

    try {
      final fetchedProducts = products.isEmpty
          ? await _activeRepository.getProducts()
          : products;
      final fetchedOrders = await _activeRepository.getFranchiseOrders(
        user.franchiseId ?? '',
        orderCode: franchiseeOrderSearchQuery,
      );
      products = fetchedProducts;
      franchiseeOrders = fetchedOrders;
    } catch (error) {
      franchiseeError = _messageFor(error);
    } finally {
      isFranchiseeOrdersLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProductionData(User user, {required bool silent}) async {
    if (!silent) {
      isProductionTasksLoading = true;
      productionError = null;
      notifyListeners();
    }

    try {
      final fetchedTasks = await _activeRepository.getProductionTasks(
        user.franchiseId ?? '',
        orderCode: productionOrderCodeSearchQuery,
      );
      final fetchedWorkers = user.productionType == 'manager'
          ? await _activeRepository.getProductionWorkers(user.franchiseId ?? '')
          : const <User>[];
      productionTasks = fetchedTasks;
      productionWorkers = fetchedWorkers;
    } catch (error) {
      productionError = _messageFor(error);
    } finally {
      isProductionTasksLoading = false;
      notifyListeners();
    }
  }

  void _startSync() {
    final user = currentUser;
    if (user == null) {
      return;
    }

    isRealtimeConnected = config.enableRealtime && !isUsingMock;
    _syncService.start(
      baseUrl: config.apiBaseUrl,
      user: user,
      enableRealtime: config.enableRealtime && !isUsingMock,
      pollingInterval: Duration(seconds: config.syncIntervalSeconds),
      onTick: () => refreshForCurrentRole(silent: true),
      onConnectionChanged: (connected) {
        isRealtimeConnected = connected;
        notifyListeners();
      },
    );
  }

  String _messageFor(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();

    if (raw.contains('Connection refused')) {
      return 'Сервер недоступен. Проверьте, что backend запущен и адрес указан верно.';
    }
    if (raw.contains('Invalid email or password')) {
      return 'Неверная почта или пароль.';
    }
    if (raw.contains('User with this email already exists')) {
      return 'Пользователь с такой почтой уже существует.';
    }
    if (raw.contains('Valid email is required')) {
      return 'Введите корректную почту сотрудника.';
    }
    if (raw.contains('Password must be at least 6 characters')) {
      return 'Пароль должен содержать минимум 6 символов.';
    }
    if (raw.contains('Unsupported worker specialization')) {
      return 'Выбрана неподдерживаемая специализация сотрудника.';
    }
    if (raw.contains('Full name is required')) {
      return 'Введите имя сотрудника.';
    }
    if (raw.contains('Authenticated user is not registered in backend roles')) {
      return 'Учетная запись найдена, но не привязана к роли в системе.';
    }
    if (raw.contains('Supabase auth service unavailable')) {
      return 'Сервис авторизации временно недоступен.';
    }
    if (raw.contains('Invalid authentication credentials')) {
      return 'Сессия недействительна. Выполните вход заново.';
    }
    if (raw.contains('Invalid order status')) {
      return 'Недопустимый статус заказа.';
    }
    if (raw.contains('Invalid order status transition')) {
      return 'Переход статуса сейчас недоступен.';
    }
    if (raw.contains('Client can only confirm payment')) {
      return 'Клиент может подтвердить только оплату своего заказа.';
    }
    if (raw.contains('Franchisee can only confirm or send to production')) {
      return 'Франчайзи может только подтвердить заказ или передать его в цех.';
    }
    if (raw.contains('Franchisee can only confirm, send to production or close order')) {
      return 'Франчайзи может подтверждать, передавать в цех и закрывать заказ.';
    }
    if (raw.contains('Access denied for production type')) {
      return 'Недостаточно прав для этого производственного действия.';
    }
    if (raw.contains('Worker specialization must match task stage')) {
      return 'Специализация сотрудника должна совпадать с этапом задачи.';
    }
    if (raw.contains('Worker can start only own assigned task')) {
      return 'Сотрудник может брать в работу только свои задачи.';
    }
    if (raw.contains('Worker can complete only own task')) {
      return 'Сотрудник может завершать только свои задачи.';
    }
    if (raw.contains('Task must be assigned before start')) {
      return 'Сначала менеджер должен назначить задачу сотруднику.';
    }
    if (raw.contains('Task must be in_progress before completion')) {
      return 'Этап можно завершить только после перевода в работу.';
    }
    if (raw.contains('Previous production stages must be completed first')) {
      return 'Сначала нужно завершить предыдущие этапы производства.';
    }
    if (raw.contains('Target user is not a production worker')) {
      return 'Выбранный пользователь не является сотрудником цеха.';
    }
    if (raw.contains('Can only assign own franchise workers')) {
      return 'Можно назначать только сотрудников своей франшизы.';
    }
    if (raw.contains('Only queued or assigned task can be reassigned')) {
      return 'Назначать можно только задачи из очереди или уже назначенные.';
    }
    if (raw.contains('Order must be in_production before task start')) {
      return 'Заказ должен быть переведен в производство перед началом этапа.';
    }
    if (raw.contains('Order must be in_production before completion')) {
      return 'Заказ должен быть в производстве перед завершением этапа.';
    }

    return raw;
  }

  @override
  void dispose() {
    _syncService.stop();
    _apiRepository.dispose();
    _mockRepository.dispose();
    super.dispose();
  }
}

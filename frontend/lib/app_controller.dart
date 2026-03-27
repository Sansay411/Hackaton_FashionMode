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
  String? modeMessage;
  bool isAuthenticating = false;
  bool isProductsLoading = false;
  bool isClientOrdersLoading = false;
  bool isFranchiseeOrdersLoading = false;
  bool isProductionTasksLoading = false;
  String? authError;
  String? clientError;
  String? franchiseeError;
  String? productionError;
  String? createOrderProductId;
  String? orderActionId;
  String? taskActionId;

  List<Product> products = const [];
  List<Order> clientOrders = const [];
  List<Order> franchiseeOrders = const [];
  List<ProductionTask> productionTasks = const [];

  Future<void> bootstrap() async {
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isAuthenticating = true;
    authError = null;
    notifyListeners();

    try {
      _session = await _withFallback(
        (repository) => repository.login(email: email, password: password),
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
      await _withFallback(
        (repository) => repository.createOrder(
          clientId: user.id,
          franchiseId: user.franchiseId ?? '',
          productId: product.id,
          productTitle: product.title,
          quantity: quantity,
          orderType: product.availabilityType,
          selectedReadyDate: selectedReadyDate,
        ),
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      clientError = _messageFor(error);
    } finally {
      createOrderProductId = null;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(Order order, String status) async {
    orderActionId = order.id;
    if (currentUser?.role == UserRole.franchisee) {
      franchiseeError = null;
    }
    notifyListeners();

    try {
      await _withFallback(
        (repository) => repository.updateOrderStatus(
          orderId: order.id,
          status: status,
        ),
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      if (currentUser?.role == UserRole.franchisee) {
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
    notifyListeners();

    try {
      await _withFallback(
        (repository) => repository.completeTask(task.id),
      );
      await refreshForCurrentRole(silent: true);
    } catch (error) {
      productionError = _messageFor(error);
    } finally {
      taskActionId = null;
      notifyListeners();
    }
  }

  void logout() {
    _syncService.stop();
    _session = null;
    products = const [];
    clientOrders = const [];
    franchiseeOrders = const [];
    productionTasks = const [];
    authError = null;
    clientError = null;
    franchiseeError = null;
    productionError = null;
    createOrderProductId = null;
    orderActionId = null;
    taskActionId = null;
    if (!config.useMock) {
      isUsingMock = false;
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
      final fetchedProducts =
          await _withFallback((repository) => repository.getProducts());
      final fetchedOrders = await _withFallback(
        (repository) => repository.getClientOrders(user.id),
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
      final fetchedOrders = await _withFallback(
        (repository) => repository.getFranchiseOrders(user.franchiseId ?? ''),
      );
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
      final fetchedTasks = await _withFallback(
        (repository) => repository.getProductionTasks(user.franchiseId ?? ''),
      );
      productionTasks = fetchedTasks;
    } catch (error) {
      productionError = _messageFor(error);
    } finally {
      isProductionTasksLoading = false;
      notifyListeners();
    }
  }

  Future<T> _withFallback<T>(
    Future<T> Function(AppRepository repository) action,
  ) async {
    if (isUsingMock) {
      return action(_mockRepository);
    }

    try {
      return await action(_activeRepository);
    } catch (error) {
      if (!_shouldFallback(error)) {
        rethrow;
      }
      isUsingMock = true;
      modeMessage = 'Бэк недоступен. Включен демо-режим.';
      _activeRepository = _mockRepository;
      notifyListeners();
      return action(_mockRepository);
    }
  }

  void _startSync() {
    _syncService.start(
      interval: Duration(seconds: config.syncIntervalSeconds),
      onTick: () => refreshForCurrentRole(silent: true),
    );
  }

  String _messageFor(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  bool _shouldFallback(Object error) {
    final message = error.toString();
    return !message.contains('Request failed (4');
  }

  @override
  void dispose() {
    _syncService.stop();
    _apiRepository.dispose();
    _mockRepository.dispose();
    super.dispose();
  }
}

import '../models/order.dart';
import '../models/product.dart';
import '../models/production_task.dart';
import '../models/session.dart';
import '../models/user.dart';
import '../services/http_client.dart';
import 'app_repository.dart';

class ApiRepository implements AppRepository {
  ApiRepository(this._httpClient);

  final HttpClientService _httpClient;

  @override
  Future<Session> login({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return Session.fromJson(_asMap(response));
  }

  @override
  Future<Session> registerClient({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _httpClient.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
      },
    );

    return Session.fromJson(_asMap(response));
  }

  @override
  Future<List<Product>> getProducts() async {
    final response = await _httpClient.get('/products');
    final items = _asList(response);
    return items.map(Product.fromJson).toList();
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
    await _httpClient.post(
      '/orders',
      body: {
        'client_id': int.parse(clientId),
        'franchise_id': int.parse(franchiseId),
        'product_id': int.parse(productId),
        'quantity': quantity,
        'order_type': orderType,
        'selected_ready_date': selectedReadyDate,
      },
    );
  }

  @override
  Future<List<Order>> getClientOrders(String clientId, {String? orderCode}) async {
    final response = await _httpClient.get(
      '/orders/client/$clientId',
      queryParameters: {'order_code': orderCode},
    );
    return _asList(response).map(Order.fromJson).toList();
  }

  @override
  Future<List<Order>> getFranchiseOrders(String franchiseId, {String? orderCode}) async {
    final response = await _httpClient.get(
      '/orders/franchise/$franchiseId',
      queryParameters: {'order_code': orderCode},
    );
    return _asList(response).map(Order.fromJson).toList();
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _httpClient.patch(
      '/orders/$orderId/status',
      body: {'status': status},
    );
  }

  @override
  Future<List<ProductionTask>> getProductionTasks(String franchiseId, {String? orderCode}) async {
    final response = await _httpClient.get(
      '/production/tasks/$franchiseId',
      queryParameters: {'order_code': orderCode},
    );
    return _asList(response).map(ProductionTask.fromJson).toList();
  }

  @override
  Future<List<User>> getProductionWorkers(String franchiseId) async {
    final response = await _httpClient.get('/production/workers/$franchiseId');
    return _asList(response).map(User.fromJson).toList();
  }

  @override
  Future<User> createProductionWorker({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
  }) async {
    final response = await _httpClient.post(
      '/production/workers',
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'specialization': specialization,
      },
    );
    return User.fromJson(_asMap(response));
  }

  @override
  Future<void> deleteProductionWorker(String workerId) async {
    await _httpClient.delete('/production/workers/$workerId');
  }

  @override
  Future<void> assignTask({
    required String taskId,
    required String workerId,
  }) async {
    await _httpClient.patch(
      '/production/tasks/$taskId/assign',
      body: {'worker_id': int.parse(workerId)},
    );
  }

  @override
  Future<void> startTask(String taskId) async {
    await _httpClient.patch('/production/tasks/$taskId/start');
  }

  @override
  Future<void> completeTask(String taskId) async {
    await _httpClient.patch('/production/tasks/$taskId/complete');
  }

  @override
  Future<User> updateProfile({
    required String fullName,
  }) async {
    final response = await _httpClient.patch(
      '/users/me',
      body: {'full_name': fullName},
    );
    return User.fromJson(_asMap(response));
  }

  @override
  void dispose() {
    _httpClient.dispose();
  }

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (response is Map && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Сервер вернул неожиданный список данных.');
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Сервер вернул неожиданный объект данных.');
  }
}

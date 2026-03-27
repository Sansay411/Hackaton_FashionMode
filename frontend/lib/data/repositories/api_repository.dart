import '../models/order.dart';
import '../models/product.dart';
import '../models/production_task.dart';
import '../models/session.dart';
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
        'client_id': clientId,
        'franchise_id': franchiseId,
        'product_id': productId,
        'product_title': productTitle,
        'quantity': quantity,
        'order_type': orderType,
        'selected_ready_date': selectedReadyDate,
      },
    );
  }

  @override
  Future<List<Order>> getClientOrders(String clientId) async {
    final response = await _httpClient.get('/orders/client/$clientId');
    return _asList(response).map(Order.fromJson).toList();
  }

  @override
  Future<List<Order>> getFranchiseOrders(String franchiseId) async {
    final response = await _httpClient.get('/orders/franchise/$franchiseId');
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
  Future<List<ProductionTask>> getProductionTasks(String franchiseId) async {
    final response = await _httpClient.get('/production/tasks/$franchiseId');
    return _asList(response).map(ProductionTask.fromJson).toList();
  }

  @override
  Future<void> completeTask(String taskId) async {
    await _httpClient.patch('/production/tasks/$taskId/complete');
  }

  @override
  void dispose() {
    _httpClient.dispose();
  }

  List<Map<String, dynamic>> _asList(dynamic response) {
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    if (response is Map && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception('Expected a list response.');
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Expected an object response.');
  }
}

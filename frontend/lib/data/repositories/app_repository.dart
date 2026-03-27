import '../models/product.dart';
import '../models/production_task.dart';
import '../models/session.dart';
import '../models/order.dart';

abstract class AppRepository {
  Future<Session> login({
    required String email,
    required String password,
  });

  Future<List<Product>> getProducts();

  Future<void> createOrder({
    required String clientId,
    required String franchiseId,
    required String productId,
    required String productTitle,
    required int quantity,
    required String orderType,
    required String selectedReadyDate,
  });

  Future<List<Order>> getClientOrders(String clientId);

  Future<List<Order>> getFranchiseOrders(String franchiseId);

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  });

  Future<List<ProductionTask>> getProductionTasks(String franchiseId);

  Future<void> completeTask(String taskId);

  void dispose() {}
}

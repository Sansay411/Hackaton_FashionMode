import '../models/product.dart';
import '../models/production_task.dart';
import '../models/session.dart';
import '../models/order.dart';
import '../models/user.dart';

abstract class AppRepository {
  Future<Session> login({
    required String email,
    required String password,
  });

  Future<Session> registerClient({
    required String email,
    required String password,
    required String fullName,
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

  Future<List<Order>> getClientOrders(String clientId, {String? orderCode});

  Future<List<Order>> getFranchiseOrders(String franchiseId, {String? orderCode});

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  });

  Future<List<ProductionTask>> getProductionTasks(String franchiseId, {String? orderCode});

  Future<List<User>> getProductionWorkers(String franchiseId);

  Future<User> createProductionWorker({
    required String email,
    required String password,
    required String fullName,
    required String specialization,
  });

  Future<void> deleteProductionWorker(String workerId);

  Future<void> assignTask({
    required String taskId,
    required String workerId,
  });

  Future<void> startTask(String taskId);

  Future<void> completeTask(String taskId);

  Future<User> updateProfile({
    required String fullName,
  });

  void dispose() {}
}

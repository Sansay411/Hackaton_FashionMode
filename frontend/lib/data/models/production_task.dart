class ProductionTask {
  const ProductionTask({
    required this.id,
    required this.orderId,
    required this.franchiseId,
    required this.title,
    required this.status,
    required this.operationStage,
    required this.createdAt,
  });

  factory ProductionTask.fromJson(Map<String, dynamic> json) {
    return ProductionTask(
      id: _stringValue(json['id']),
      orderId: _stringValue(json['order_id']),
      franchiseId: _stringValue(json['franchise_id']),
      title: _stringValue(json['title']),
      status: _stringValue(json['status']),
      operationStage: _stringValue(json['operation_stage']),
      createdAt: _stringValue(json['created_at']),
    );
  }

  final String id;
  final String orderId;
  final String franchiseId;
  final String title;
  final String status;
  final String operationStage;
  final String createdAt;

  ProductionTask copyWith({
    String? id,
    String? orderId,
    String? franchiseId,
    String? title,
    String? status,
    String? operationStage,
    String? createdAt,
  }) {
    return ProductionTask(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      franchiseId: franchiseId ?? this.franchiseId,
      title: title ?? this.title,
      status: status ?? this.status,
      operationStage: operationStage ?? this.operationStage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'franchise_id': franchiseId,
      'title': title,
      'status': status,
      'operation_stage': operationStage,
      'created_at': createdAt,
    };
  }
}

String _stringValue(dynamic value) => value?.toString() ?? '';

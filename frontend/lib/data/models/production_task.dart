class ProductionTask {
  const ProductionTask({
    required this.id,
    required this.orderId,
    required this.orderCode,
    required this.franchiseId,
    required this.title,
    required this.priority,
    required this.assignedTo,
    required this.assignedToName,
    required this.createdBy,
    required this.status,
    required this.operationStage,
    required this.startedAt,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductionTask.fromJson(Map<String, dynamic> json) {
    return ProductionTask(
      id: _stringValue(json['id']),
      orderId: _stringValue(json['order_id']),
      orderCode: _stringValue(json['order_code']),
      franchiseId: _stringValue(json['franchise_id']),
      title: _stringValue(json['title']),
      priority: _stringValue(json['priority'], fallback: 'medium'),
      assignedTo: _nullableStringValue(json['assigned_to']),
      assignedToName: _nullableStringValue(json['assigned_to_name']),
      createdBy: _nullableStringValue(json['created_by']),
      status: _stringValue(json['status']),
      operationStage: _stringValue(json['operation_stage']),
      startedAt: _nullableStringValue(json['started_at']),
      completedAt: _nullableStringValue(json['completed_at']),
      createdAt: _stringValue(json['created_at']),
      updatedAt: _stringValue(json['updated_at']),
    );
  }

  final String id;
  final String orderId;
  final String orderCode;
  final String franchiseId;
  final String title;
  final String priority;
  final String? assignedTo;
  final String? assignedToName;
  final String? createdBy;
  final String status;
  final String operationStage;
  final String? startedAt;
  final String? completedAt;
  final String createdAt;
  final String updatedAt;

  ProductionTask copyWith({
    String? id,
    String? orderId,
    String? orderCode,
    String? franchiseId,
    String? title,
    String? priority,
    String? assignedTo,
    String? assignedToName,
    String? createdBy,
    String? status,
    String? operationStage,
    String? startedAt,
    String? completedAt,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductionTask(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      franchiseId: franchiseId ?? this.franchiseId,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      operationStage: operationStage ?? this.operationStage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'order_code': orderCode,
      'franchise_id': franchiseId,
      'title': title,
      'priority': priority,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'created_by': createdBy,
      'status': status,
      'operation_stage': operationStage,
      'started_at': startedAt,
      'completed_at': completedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

String _stringValue(dynamic value, {String fallback = ''}) =>
    value?.toString() ?? fallback;
String? _nullableStringValue(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}

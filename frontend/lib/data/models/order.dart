class Order {
  const Order({
    required this.id,
    required this.clientId,
    required this.franchiseId,
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.orderType,
    required this.selectedReadyDate,
    required this.status,
    required this.trackingStage,
    required this.loyaltyProgress,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: _stringValue(json['id']),
      clientId: _stringValue(json['client_id']),
      franchiseId: _stringValue(json['franchise_id']),
      productId: _stringValue(json['product_id']),
      productTitle: _stringValue(json['product_title']),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      orderType: _stringValue(json['order_type']),
      selectedReadyDate: _stringValue(json['selected_ready_date']),
      status: _stringValue(json['status']),
      trackingStage: _stringValue(json['tracking_stage']),
      loyaltyProgress: json['loyalty_progress'],
      createdAt: _stringValue(json['created_at']),
    );
  }

  final String id;
  final String clientId;
  final String franchiseId;
  final String productId;
  final String productTitle;
  final int quantity;
  final String orderType;
  final String selectedReadyDate;
  final String status;
  final String trackingStage;
  final dynamic loyaltyProgress;
  final String createdAt;

  Order copyWith({
    String? id,
    String? clientId,
    String? franchiseId,
    String? productId,
    String? productTitle,
    int? quantity,
    String? orderType,
    String? selectedReadyDate,
    String? status,
    String? trackingStage,
    dynamic loyaltyProgress,
    String? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      franchiseId: franchiseId ?? this.franchiseId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      quantity: quantity ?? this.quantity,
      orderType: orderType ?? this.orderType,
      selectedReadyDate: selectedReadyDate ?? this.selectedReadyDate,
      status: status ?? this.status,
      trackingStage: trackingStage ?? this.trackingStage,
      loyaltyProgress: loyaltyProgress ?? this.loyaltyProgress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'franchise_id': franchiseId,
      'product_id': productId,
      'product_title': productTitle,
      'quantity': quantity,
      'order_type': orderType,
      'selected_ready_date': selectedReadyDate,
      'status': status,
      'tracking_stage': trackingStage,
      'loyalty_progress': loyaltyProgress,
      'created_at': createdAt,
    };
  }
}

String _stringValue(dynamic value) => value?.toString() ?? '';

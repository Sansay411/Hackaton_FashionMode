class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.availabilityType,
    required this.defaultReadyDays,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _stringValue(json['id']),
      title: _stringValue(json['title']),
      description: _stringValue(json['description']),
      price: json['price'],
      currency: _stringValue(json['currency']),
      imageUrl: _stringValue(json['image_url']),
      availabilityType: _stringValue(json['availability_type']),
      defaultReadyDays: int.tryParse(json['default_ready_days'].toString()) ?? 0,
      isActive: json['is_active'] == true,
    );
  }

  final String id;
  final String title;
  final String description;
  final dynamic price;
  final String currency;
  final String imageUrl;
  final String availabilityType;
  final int defaultReadyDays;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'image_url': imageUrl,
      'availability_type': availabilityType,
      'default_ready_days': defaultReadyDays,
      'is_active': isActive,
    };
  }
}

String _stringValue(dynamic value) => value?.toString() ?? '';

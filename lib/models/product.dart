class Product {
  final int id;
  final String userId;
  final String name;
  final String unit;
  final double basePrice;
  final double defaultSellPrice;
  final int currentStock;

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.unit,
    required this.basePrice,
    required this.defaultSellPrice,
    required this.currentStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id']?.toString() ?? '',
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'pcs',
      basePrice: (json['base_price'] ?? 0).toDouble(),
      defaultSellPrice: (json['default_sell_price'] ?? 0).toDouble(),
      currentStock: json['current_stock'] is int
          ? json['current_stock']
          : int.parse(json['current_stock']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'unit': unit,
      'base_price': basePrice,
      'default_sell_price': defaultSellPrice,
      'current_stock': currentStock,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'name': name,
      'unit': unit,
      'base_price': basePrice,
      'sell_price': defaultSellPrice,
      'stock': currentStock,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'user_id': userId,
      'name': name,
      'unit': unit,
      'base_price': basePrice,
      'sell_price': defaultSellPrice,
      'stock': currentStock,
    };
  }

  Product copyWith({
    int? id,
    String? userId,
    String? name,
    String? unit,
    double? basePrice,
    double? defaultSellPrice,
    int? currentStock,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      basePrice: basePrice ?? this.basePrice,
      defaultSellPrice: defaultSellPrice ?? this.defaultSellPrice,
      currentStock: currentStock ?? this.currentStock,
    );
  }
}

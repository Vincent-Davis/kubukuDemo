class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String? category;
  final String? description;
  final String? imageUrl;
  final DateTime? lastUpdated;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.category,
    this.description,
    this.imageUrl,
    this.lastUpdated,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      category: json['category'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    String? category,
    String? description,
    String? imageUrl,
    DateTime? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

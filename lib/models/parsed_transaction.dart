import 'transaction.dart';

class ParsedTransaction {
  final String category;
  final String? action;
  final String? type;
  final List<ParsedTransactionItem> items;

  ParsedTransaction({
    required this.category,
    this.action,
    this.type,
    required this.items,
  });

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      category: json['category'],
      action: json['action'],
      type: json['type'],
      items: (json['items'] as List)
          .map((item) => ParsedTransactionItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'action': action,
      'type': type,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  bool get isStockTransaction => category == 'stock' && action == 'create';
  bool get isStockQuery => category == 'stock' && action == 'read';
  bool get isAmarthaRelated => category == 'amartha';
  bool get isOtherQuery => category == 'other';
}

class ParsedTransactionItem {
  final int? productId;
  final String productName;
  final double? quantity;
  final String unit;
  final double? pricePerUnit;
  final double? stock;

  ParsedTransactionItem({
    this.productId,
    required this.productName,
    this.quantity,
    required this.unit,
    this.pricePerUnit,
    this.stock,
  });

  factory ParsedTransactionItem.fromJson(Map<String, dynamic> json) {
    return ParsedTransactionItem(
      productId: json['product_id']?.toInt(),
      productName: json['product_name'],
      quantity: json['quantity']?.toDouble(),
      unit: json['unit'] ?? 'pcs',
      pricePerUnit: json['price_per_unit']?.toDouble(),
      stock: json['stock']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'stock': stock,
    };
  }

  ParsedTransactionItem copyWith({
    int? productId,
    String? productName,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? stock,
  }) {
    return ParsedTransactionItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      stock: stock ?? this.stock,
    );
  }

  double get subtotal {
    if (quantity == null || pricePerUnit == null) return 0;
    return quantity! * pricePerUnit!;
  }

  // Convert to TransactionItem for saving
  TransactionItem toTransactionItem() {
    return TransactionItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? 0,
      unit: unit,
      pricePerUnit: pricePerUnit ?? 0,
      subtotal: subtotal,
    );
  }
}
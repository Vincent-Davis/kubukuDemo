enum TransactionType {
  sell, // Penjualan
  buy, // Pembelian
}

class Transaction {
  final int id;
  final String userId;
  final TransactionType type;
  final DateTime timestamp;
  final double totalAmount;
  final String? originalText;
  final String? sessionId;
  final List<TransactionItem> items;
  final int? itemCount;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.totalAmount,
    this.originalText,
    this.sessionId,
    this.items = const [],
    this.itemCount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    TransactionType type;
    if (json['type'] == 'sell' || json['type'] == 'TransactionType.sell') {
      type = TransactionType.sell;
    } else if (json['type'] == 'buy' || json['type'] == 'TransactionType.buy') {
      type = TransactionType.buy;
    } else {
      type = TransactionType.sell;
    }

    List<TransactionItem> items = [];
    if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) => TransactionItem.fromJson(item))
          .toList();
    }

    return Transaction(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id']?.toString() ?? '',
      type: type,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      originalText: json['original_text'],
      sessionId: json['session_id'],
      items: items,
      itemCount: json['item_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'total_amount': totalAmount,
      'original_text': originalText,
      'session_id': sessionId,
      'items': items.map((item) => item.toJson()).toList(),
      'item_count': itemCount ?? items.length,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'type': type.toString().split('.').last,
      'items': items.map((item) => item.toCreateJson()).toList(),
      'original_text': originalText,
      'session_id': sessionId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'user_id': userId,
      'type': type.toString().split('.').last,
      'items': items.map((item) => item.toCreateJson()).toList(),
    };
  }

  Transaction copyWith({
    int? id,
    String? userId,
    TransactionType? type,
    DateTime? timestamp,
    double? totalAmount,
    String? originalText,
    String? sessionId,
    List<TransactionItem>? items,
    int? itemCount,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      totalAmount: totalAmount ?? this.totalAmount,
      originalText: originalText ?? this.originalText,
      sessionId: sessionId ?? this.sessionId,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}

class TransactionItem {
  final int? id;
  final int? productId;
  final String productName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final double subtotal;

  TransactionItem({
    this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? json['product_name_snapshot'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pcs',
      pricePerUnit:
          (json['price_per_unit'] ?? json['actual_price_per_unit'] ?? 0)
              .toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'subtotal': subtotal,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
    };
  }

  TransactionItem copyWith({
    int? id,
    int? productId,
    String? productName,
    double? quantity,
    String? unit,
    double? pricePerUnit,
    double? subtotal,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
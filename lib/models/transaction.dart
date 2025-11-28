enum TransactionType {
  income, // Pemasukan
  expense, // Pengeluaran
}

class Transaction {
  final String id;
  final DateTime date;
  final TransactionType type;
  final double amount;
  final String description;
  final String? productName;
  final int? quantity;
  final double? unitPrice;
  final String? category;
  final String? notes;
  final String? receiptImageUrl;

  Transaction({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.description,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.category,
    this.notes,
    this.receiptImageUrl,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
      ),
      amount: json['amount'].toDouble(),
      description: json['description'],
      productName: json['productName'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice']?.toDouble(),
      category: json['category'],
      notes: json['notes'],
      receiptImageUrl: json['receiptImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.toString().split('.').last,
      'amount': amount,
      'description': description,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'category': category,
      'notes': notes,
      'receiptImageUrl': receiptImageUrl,
    };
  }
}

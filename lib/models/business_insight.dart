class BusinessInsight {
  final String title;
  final String description;
  final InsightType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  BusinessInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  factory BusinessInsight.fromJson(Map<String, dynamic> json) {
    return BusinessInsight(
      title: json['title'],
      description: json['description'],
      type: InsightType.values.firstWhere(
        (e) => e.toString() == 'InsightType.${json['type']}',
      ),
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum InsightType {
  bestSelling,
  lowStock,
  profitAnalysis,
  salesTrend,
  recommendation,
}

class SalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalExpenses;
  final double profit;
  final int transactionCount;
  final List<ProductSales> topProducts;
  final Map<String, double> categoryBreakdown;

  SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.profit,
    required this.transactionCount,
    required this.topProducts,
    required this.categoryBreakdown,
  });

  double get profitMargin =>
      totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0;
}

class ProductSales {
  final String productName;
  final int quantity;
  final double revenue;

  ProductSales({
    required this.productName,
    required this.quantity,
    required this.revenue,
  });
}

import '../models/transaction.dart';
import '../models/product.dart';
import '../models/business_insight.dart';

class DummyDataService {
  static List<Transaction> getDummyTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 1,
        userId: 'user_1',
        type: TransactionType.sell,
        timestamp: now.subtract(const Duration(hours: 2)),
        totalAmount: 25000,
        originalText: 'Jual beras 5kg',
        items: [
          TransactionItem(
            productId: 1,
            productName: 'Beras Premium',
            quantity: 5,
            unit: 'kg',
            pricePerUnit: 5000,
            subtotal: 25000,
          ),
        ],
      ),
      Transaction(
        id: 2,
        userId: 'user_1',
        type: TransactionType.sell,
        timestamp: now.subtract(const Duration(hours: 4)),
        totalAmount: 15000,
        originalText: 'Jual minyak goreng 2 botol',
        items: [
          TransactionItem(
            productId: 2,
            productName: 'Minyak Goreng Tropical',
            quantity: 2,
            unit: 'botol',
            pricePerUnit: 7500,
            subtotal: 15000,
          ),
        ],
      ),
      Transaction(
        id: 3,
        userId: 'user_1',
        type: TransactionType.buy,
        timestamp: now.subtract(const Duration(hours: 6)),
        totalAmount: 100000,
        originalText: 'Beli stok dari distributor',
        items: [
          TransactionItem(
            productName: 'Stok Beras',
            quantity: 20,
            unit: 'kg',
            pricePerUnit: 4000,
            subtotal: 80000,
          ),
          TransactionItem(
            productName: 'Stok Minyak',
            quantity: 10,
            unit: 'botol',
            pricePerUnit: 2000,
            subtotal: 20000,
          ),
        ],
      ),
      Transaction(
        id: 4,
        userId: 'user_1',
        type: TransactionType.sell,
        timestamp: now.subtract(const Duration(days: 1)),
        totalAmount: 35000,
        originalText: 'Jual gula pasir dan telur',
        items: [
          TransactionItem(
            productId: 3,
            productName: 'Gula Pasir',
            quantity: 2,
            unit: 'kg',
            pricePerUnit: 12000,
            subtotal: 24000,
          ),
          TransactionItem(
            productId: 4,
            productName: 'Telur Ayam',
            quantity: 1,
            unit: 'kg',
            pricePerUnit: 11000,
            subtotal: 11000,
          ),
        ],
      ),
      Transaction(
        id: 5,
        userId: 'user_1',
        type: TransactionType.sell,
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        totalAmount: 12000,
        originalText: 'Jual sabun cuci 3 pcs',
        items: [
          TransactionItem(
            productId: 5,
            productName: 'Sabun Cuci Rinso',
            quantity: 3,
            unit: 'pcs',
            pricePerUnit: 4000,
            subtotal: 12000,
          ),
        ],
      ),
    ];
  }

  static List<Product> getDummyProducts() {
    return [
      Product(
        id: 1,
        userId: 'user_1',
        name: 'Beras Premium',
        unit: 'kg',
        basePrice: 4000,
        defaultSellPrice: 5000,
        currentStock: 25,
      ),
      Product(
        id: 2,
        userId: 'user_1',
        name: 'Minyak Goreng Tropical',
        unit: 'botol',
        basePrice: 6000,
        defaultSellPrice: 7500,
        currentStock: 12,
      ),
      Product(
        id: 3,
        userId: 'user_1',
        name: 'Gula Pasir',
        unit: 'kg',
        basePrice: 11000,
        defaultSellPrice: 12000,
        currentStock: 8,
      ),
      Product(
        id: 4,
        userId: 'user_1',
        name: 'Telur Ayam',
        unit: 'kg',
        basePrice: 20000,
        defaultSellPrice: 22000,
        currentStock: 15,
      ),
      Product(
        id: 5,
        userId: 'user_1',
        name: 'Sabun Cuci Rinso',
        unit: 'pcs',
        basePrice: 3000,
        defaultSellPrice: 4000,
        currentStock: 3,
      ),
      Product(
        id: 6,
        userId: 'user_1',
        name: 'Kopi Sachet',
        unit: 'pcs',
        basePrice: 1000,
        defaultSellPrice: 1500,
        currentStock: 50,
      ),
    ];
  }

  static List<BusinessInsight> getDummyInsights() {
    return [
      BusinessInsight(
        title: 'Produk Terlaris Hari Ini',
        description:
            'Beras Premium adalah produk yang paling laku hari ini dengan 5 penjualan',
        type: InsightType.bestSelling,
        data: {'product': 'Beras Premium', 'sales': 5},
        createdAt: DateTime.now(),
      ),
      BusinessInsight(
        title: 'Stok Hampir Habis',
        description: 'Sabun Cuci Rinso tinggal 3 pcs. Segera tambah stok!',
        type: InsightType.lowStock,
        data: {'product': 'Sabun Cuci Rinso', 'stock': 3, 'threshold': 5},
        createdAt: DateTime.now(),
      ),
      BusinessInsight(
        title: 'Keuntungan Hari Ini',
        description: 'Alhamdulillah! Keuntungan hari ini Rp 87.000',
        type: InsightType.profitAnalysis,
        data: {'profit': 87000, 'margin': 65.2},
        createdAt: DateTime.now(),
      ),
    ];
  }

  static SalesReport getDummyWeeklyReport() {
    final now = DateTime.now();
    return SalesReport(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      totalRevenue: 520000,
      totalExpenses: 320000,
      profit: 200000,
      transactionCount: 23,
      topProducts: [
        ProductSales(
          productName: 'Beras Premium',
          quantity: 15,
          revenue: 75000,
        ),
        ProductSales(productName: 'Minyak Goreng', quantity: 8, revenue: 60000),
        ProductSales(productName: 'Telur Ayam', quantity: 6, revenue: 120000),
      ],
      categoryBreakdown: {
        'Sembako': 380000,
        'Kebutuhan Rumah': 85000,
        'Minuman': 55000,
      },
    );
  }

  static List<String> getAmarthaRecommendations() {
    return [
      'Modal Usaha: Tingkatkan stok dengan pinjaman modal usaha Amartha',
      'Celengan Digital: Mulai menabung keuntungan harian di Celengan Amartha',
      'Agen Listrik: Jadikan toko sebagai agen pembayaran listrik untuk income tambahan',
      'AmarthaLink: Bergabung dengan komunitas UMKM Amartha untuk tips bisnis',
    ];
  }
}

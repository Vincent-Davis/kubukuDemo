import '../models/transaction.dart';
import '../models/product.dart';
import '../models/business_insight.dart';

class DummyDataService {
  static List<Transaction> getDummyTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: '1',
        date: now.subtract(const Duration(hours: 2)),
        type: TransactionType.income,
        amount: 25000,
        description: 'Jual beras 5kg',
        productName: 'Beras Premium',
        quantity: 5,
        unitPrice: 5000,
        category: 'Sembako',
      ),
      Transaction(
        id: '2',
        date: now.subtract(const Duration(hours: 4)),
        type: TransactionType.income,
        amount: 15000,
        description: 'Jual minyak goreng 2 botol',
        productName: 'Minyak Goreng Tropical',
        quantity: 2,
        unitPrice: 7500,
        category: 'Sembako',
      ),
      Transaction(
        id: '3',
        date: now.subtract(const Duration(hours: 6)),
        type: TransactionType.expense,
        amount: 100000,
        description: 'Beli stok dari distributor',
        category: 'Modal',
      ),
      Transaction(
        id: '4',
        date: now.subtract(const Duration(days: 1)),
        type: TransactionType.income,
        amount: 35000,
        description: 'Jual gula pasir dan telur',
        productName: 'Paket Gula + Telur',
        quantity: 1,
        unitPrice: 35000,
        category: 'Sembako',
      ),
      Transaction(
        id: '5',
        date: now.subtract(const Duration(days: 1, hours: 3)),
        type: TransactionType.income,
        amount: 12000,
        description: 'Jual sabun cuci 3 pcs',
        productName: 'Sabun Cuci Rinso',
        quantity: 3,
        unitPrice: 4000,
        category: 'Kebutuhan Rumah',
      ),
    ];
  }

  static List<Product> getDummyProducts() {
    return [
      Product(
        id: '1',
        name: 'Beras Premium',
        price: 5000,
        stock: 25,
        category: 'Sembako',
        description: 'Beras premium kualitas terbaik per kg',
      ),
      Product(
        id: '2',
        name: 'Minyak Goreng Tropical',
        price: 7500,
        stock: 12,
        category: 'Sembako',
        description: 'Minyak goreng 500ml',
      ),
      Product(
        id: '3',
        name: 'Gula Pasir',
        price: 15000,
        stock: 8,
        category: 'Sembako',
        description: 'Gula pasir 1kg',
      ),
      Product(
        id: '4',
        name: 'Telur Ayam',
        price: 20000,
        stock: 15,
        category: 'Sembako',
        description: 'Telur ayam segar 1kg',
      ),
      Product(
        id: '5',
        name: 'Sabun Cuci Rinso',
        price: 4000,
        stock: 3,
        category: 'Kebutuhan Rumah',
        description: 'Sabun cuci bubuk sachet',
      ),
      Product(
        id: '6',
        name: 'Kopi Sachet',
        price: 1500,
        stock: 50,
        category: 'Minuman',
        description: 'Kopi instan sachet',
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

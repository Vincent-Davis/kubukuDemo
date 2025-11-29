import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import '../models/business_insight.dart';
import '../services/dummy_data_service.dart';
import 'transaction_entry_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'opportunities_screen.dart';
import 'product_list_screen.dart';
import 'transaction_list_screen.dart';
import 'product_form_screen.dart';
import 'transaction_form_screen.dart';
import 'ai_chat_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentTabIndex = 0;
  List<Transaction> transactions = [];
  List<Product> products = [];
  List<BusinessInsight> insights = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      transactions = DummyDataService.getDummyTransactions();
      products = DummyDataService.getDummyProducts();
      insights = DummyDataService.getDummyInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'images/logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.book, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('KuBuku'),
          ],
        ),
        backgroundColor: const Color(0xFF5c2d91),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIChatScreen(),
                ),
              );
            },
            tooltip: 'Asisten AI',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Keluar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            icon: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5c2d91),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Catat'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stok'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Peluang'),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showQuickAddOptions(),
              backgroundColor: const Color(0xFF5c2d91),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTabIndex) {
      case 0:
        return TransactionEntryScreen(
          transactions: transactions,
          onTransactionAdded: (transaction) {
            setState(() {
              transactions.insert(0, transaction);
            });
          },
        );
      case 1:
        return const InventoryScreen();
      case 2:
        return const ReportsScreen();
      case 3:
        return OpportunitiesScreen(insights: insights);
      default:
        return const Center(child: Text('Screen not found'));
    }
  }

  void _showQuickAddOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Catat Transaksi Cepat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildQuickAddOption(
              Icons.smart_toy,
              'Chat AI',
              'Ngobrol dengan AI: "jual 5 telur 10rb"',
              () => _handleAIChat(),
            ),
            _buildQuickAddOption(
              Icons.mic,
              'Rekam Suara',
              'Bilang aja: "Jual beras 5kg dapat 25 ribu"',
              () => _handleVoiceEntry(),
            ),
            _buildQuickAddOption(
              Icons.camera_alt,
              'Foto Struk',
              'Foto struk belanja, biar otomatis tercatat',
              () => _handlePhotoEntry(),
            ),
            _buildQuickAddOption(
              Icons.keyboard,
              'Ketik Manual',
              'Tulis transaksi langsung di sini',
              () => _handleManualEntry(),
            ),
            _buildQuickAddOption(
              Icons.add_business,
              'Tambah Produk',
              'Daftarkan produk baru ke inventori',
              () => _handleAddProduct(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5c2d91).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF5c2d91)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _handleAIChat() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIChatScreen(),
      ),
    );
  }

  void _handleVoiceEntry() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIChatScreen(),
      ),
    );
  }

  void _handlePhotoEntry() {
    Navigator.pop(context);
    _showComingSoonDialog('Fitur Foto Struk');
  }

  void _handleManualEntry() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );
  }

  void _handleAddProduct() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem(
              Icons.trending_up,
              'Penjualan Hari Ini',
              'Alhamdulillah! Penjualan hari ini mencapai Rp 87.000',
              '2 jam lalu',
            ),
            _buildNotificationItem(
              Icons.warning_amber,
              'Stok Menipis',
              'Sabun Cuci Rinso tinggal 3 pcs',
              '4 jam lalu',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    IconData icon,
    String title,
    String message,
    String time,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5c2d91)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text(
          '$feature akan segera hadir! Terima kasih atas kesabarannya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF5c2d91),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KuBuku',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kelola Bisnis Anda',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentTabIndex = 0;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Kelola Produk'),
            subtitle: const Text('Tambah, edit, hapus produk'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Kelola Transaksi'),
            subtitle: const Text('Lihat semua transaksi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('Asisten AI'),
            subtitle: const Text('Chat dengan AI untuk catat transaksi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIChatScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Laporan'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentTabIndex = 2;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.flash_on),
            title: const Text('Peluang'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentTabIndex = 3;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              _showComingSoonDialog('Pengaturan');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin mau keluar dari KuBuku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle actual logout logic here
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

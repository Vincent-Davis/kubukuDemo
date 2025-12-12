import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  List<Transaction> transactions = [];
  List<Transaction> filteredTransactions = [];
  final TextEditingController _searchController = TextEditingController();
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTransactions() async {
    try {
      setState(() {
        // You might want to add a loading state here
      });
      
      final loadedTransactions = await TransactionService.getTransactions();
      setState(() {
        transactions = loadedTransactions;
        filteredTransactions = transactions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Fallback to empty list
      setState(() {
        transactions = [];
        filteredTransactions = [];
      });
    }
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        final matchesSearch = transaction.originalText?.toLowerCase().contains(query) ?? false ||
            transaction.items.any((item) => item.productName.toLowerCase().contains(query));
        final matchesType = _selectedType == null || transaction.type == _selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _navigateToTransactionForm([Transaction? transaction]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      _loadTransactions();
    }
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await TransactionService.deleteTransaction(transaction.id);
                setState(() {
                  transactions.removeWhere((t) => t.id == transaction.id);
                  _filterTransactions();
                });
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaksi berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting transaction: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.sell:
        return Colors.green;
      case TransactionType.buy:
        return Colors.orange;
    }
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.sell:
        return 'Penjualan';
      case TransactionType.buy:
        return 'Pembelian';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        backgroundColor: const Color(0xFF5c2d91),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TransactionType?>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Filter Tipe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: [
                          const DropdownMenuItem<TransactionType?>(
                            value: null,
                            child: Text('Semua Transaksi'),
                          ),
                          ...TransactionType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeLabel(type)),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                            _filterTransactions();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final typeColor = _getTypeColor(transaction.type);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: typeColor.withOpacity(0.1),
                            child: Icon(
                              transaction.type == TransactionType.sell 
                                  ? Icons.trending_up 
                                  : Icons.trending_down,
                              color: typeColor,
                            ),
                          ),
                          title: Text(
                            _getTypeLabel(transaction.type),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCurrency(transaction.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${transaction.items.length} item(s)',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} ${transaction.timestamp.hour.toString().padLeft(2, '0')}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (transaction.originalText != null)
                                Text(
                                  transaction.originalText!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _navigateToTransactionForm(transaction);
                                  break;
                                case 'delete':
                                  _deleteTransaction(transaction);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTransactionForm(),
        backgroundColor: const Color(0xFF5c2d91),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/parsed_transaction.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class TransactionValidationDialog extends StatefulWidget {
  final ParsedTransaction parsedTransaction;
  final String originalMessage;

  const TransactionValidationDialog({
    super.key,
    required this.parsedTransaction,
    required this.originalMessage,
  });

  @override
  State<TransactionValidationDialog> createState() => _TransactionValidationDialogState();
}

class _TransactionValidationDialogState extends State<TransactionValidationDialog> {
  late List<ParsedTransactionItem> _editableItems;
  bool _isProcessing = false;
  String? _correctedType; // Store corrected type

  @override
  void initState() {
    super.initState();
    // Create editable copies of parsed items
    _editableItems = widget.parsedTransaction.items
        .map((item) => item.copyWith())
        .toList();
    
    // Fix transaction type based on edge cases
    _correctedType = _detectCorrectTransactionType();
  }

  // Fix transaction type based on keywords in original message
  String _detectCorrectTransactionType() {
    final message = widget.originalMessage.toLowerCase();
    
    // Strong sell indicators (prioritize these)
    final strongSellKeywords = ['jual', 'laku', 'terjual', 'penjualan', 'laris', 'dapat dari jual'];
    
    // Strong buy indicators  
    final strongBuyKeywords = ['beli', 'kulakan', 'modal', 'buat stok', 'tambah stok'];
    
    // Edge case buy phrases (specific combinations)
    final buyPhrases = ['habis beli', 'beli habis', 'abis beli', 'beli untuk stok'];
    
    // Check for strong sell indicators first
    bool hasStrongSell = strongSellKeywords.any((keyword) => message.contains(keyword));
    
    // Check for strong buy indicators
    bool hasStrongBuy = strongBuyKeywords.any((keyword) => message.contains(keyword));
    
    // Check for specific buy phrases (edge cases)
    bool hasBuyPhrase = buyPhrases.any((phrase) => message.contains(phrase));
    
    // Decision logic with priority
    if (hasStrongSell && !hasBuyPhrase) {
      return 'sell';
    } else if (hasStrongBuy || hasBuyPhrase) {
      return 'buy';
    }
    
    // Return original type if no clear indicators
    return widget.parsedTransaction.type ?? 'sell';
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = _correctedType ?? widget.parsedTransaction.type;
    final isValidTransaction = widget.parsedTransaction.isStockTransaction;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isValidTransaction ? Icons.shopping_cart : Icons.info,
            color: isValidTransaction ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValidTransaction 
                  ? 'Konfirmasi ${transactionType == 'sell' ? 'Penjualan' : 'Pembelian'}'
                  : 'Hasil Parsing',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          // Show indicator if transaction type was corrected
          if (_correctedType != null && _correctedType != widget.parsedTransaction.type)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Auto-corrected',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Original message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesan Asli:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    widget.originalMessage,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Items list
            if (_editableItems.isNotEmpty) ...[
              const Text(
                'Item yang Dideteksi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _editableItems.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(index);
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Total (only for transaction items with prices)
              if (isValidTransaction && _editableItems.any((item) => item.pricePerUnit != null))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5c2d91).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${_calculateTotal().toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5c2d91),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              const Text(
                'Tidak ada item yang terdeteksi.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        if (isValidTransaction && _editableItems.isNotEmpty) ...[
          TextButton(
            onPressed: _isProcessing ? null : _processTransaction,
            child: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Konfirmasi'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _editableItems[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            TextFormField(
              initialValue: item.productName,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _editableItems[index] = item.copyWith(productName: value);
                });
              },
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                // Quantity - Always show
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity?.toString() ?? '0',
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      final quantity = double.tryParse(value) ?? 0;
                      setState(() {
                        _editableItems[index] = item.copyWith(quantity: quantity);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Unit
                Expanded(
                  child: TextFormField(
                    initialValue: item.unit,
                    decoration: const InputDecoration(
                      labelText: 'Satuan',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _editableItems[index] = item.copyWith(unit: value);
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // Price per unit - Always show
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.pricePerUnit?.toStringAsFixed(0) ?? '0',
              decoration: const InputDecoration(
                labelText: 'Harga per Unit',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0;
                setState(() {
                  _editableItems[index] = item.copyWith(pricePerUnit: price);
                });
              },
            ),
            const SizedBox(height: 8),
            
            // Subtotal - Always show
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                    Text(
                      'Rp ${item.subtotal.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]}.',
                      )}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateTotal() {
    return _editableItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _processTransaction() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Convert parsed items to transaction items
      final transactionItems = _editableItems
          .where((item) => item.quantity != null && item.pricePerUnit != null)
          .map((item) => item.toTransactionItem())
          .toList();

      if (transactionItems.isEmpty) {
        throw Exception('Tidak ada item valid untuk diproses');
      }

      // Create transaction
      final correctedType = _correctedType ?? widget.parsedTransaction.type;
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: TransactionService.getCurrentUserId(),
        type: correctedType == 'sell' 
            ? TransactionType.sell 
            : TransactionType.buy,
        timestamp: DateTime.now(),
        totalAmount: _calculateTotal(),
        originalText: widget.originalMessage,
        items: transactionItems,
      );

      // Save transaction
      await TransactionService.createTransaction(transaction);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaksi ${correctedType == 'sell' ? 'penjualan' : 'pembelian'} berhasil disimpan',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
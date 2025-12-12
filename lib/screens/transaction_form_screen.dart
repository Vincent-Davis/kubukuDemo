import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/transaction_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originalTextController = TextEditingController();
  
  TransactionType _type = TransactionType.sell;
  List<TransactionItem> _items = [];
  List<Product> _products = [];
  bool _isLoadingProducts = false;

  bool get isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (isEdit) {
      _type = widget.transaction!.type;
      _originalTextController.text = widget.transaction!.originalText ?? '';
      _items = List.from(widget.transaction!.items);
    } else {
      _addNewItem();
    }
  }

  @override
  void dispose() {
    _originalTextController.dispose();
    super.dispose();
  }

  void _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });
    
    try {
      final products = await ProductService.getProducts();
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewItem() {
    setState(() {
      _items.add(TransactionItem(
        productName: '',
        quantity: 1,
        unit: 'pcs',
        pricePerUnit: 0,
        subtotal: 0,
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _updateItem(int index, TransactionItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  double _calculateTotal() {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_items.any((item) => item.productName.isEmpty || item.quantity <= 0 || item.pricePerUnit <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pastikan semua item memiliki data yang lengkap'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final transaction = Transaction(
          id: isEdit ? widget.transaction!.id : DateTime.now().millisecondsSinceEpoch,
          userId: TransactionService.getCurrentUserId(),
          type: _type,
          timestamp: DateTime.now(),
          totalAmount: _calculateTotal(),
          originalText: _originalTextController.text.trim().isNotEmpty 
              ? _originalTextController.text.trim() 
              : null,
          items: _items,
        );

        if (isEdit) {
          await TransactionService.updateTransaction(transaction);
        } else {
          await TransactionService.createTransaction(transaction);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit
                    ? 'Transaksi berhasil diperbarui'
                    : 'Transaksi berhasil ditambahkan',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        backgroundColor: const Color(0xFF5c2d91),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveTransaction,
            child: const Text(
              'SIMPAN',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<TransactionType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tipe Transaksi',
                          border: OutlineInputBorder(),
                        ),
                        items: TransactionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type == TransactionType.sell ? 'Penjualan' : 'Pembelian'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _originalTextController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (Opsional)',
                          hintText: 'Deskripsi transaksi',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Item Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _addNewItem,
                    icon: const Icon(Icons.add_circle, color: Color(0xFF5c2d91)),
                  ),
                ],
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _TransactionItemCard(
                    item: _items[index],
                    products: _products,
                    isLoadingProducts: _isLoadingProducts,
                    canRemove: _items.length > 1,
                    onUpdate: (item) => _updateItem(index, item),
                    onRemove: () => _removeItem(index),
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF5c2d91).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${_calculateTotal().toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        )}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5c2d91),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5c2d91),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'PERBARUI TRANSAKSI' : 'TAMBAH TRANSAKSI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionItemCard extends StatefulWidget {
  final TransactionItem item;
  final List<Product> products;
  final bool isLoadingProducts;
  final bool canRemove;
  final Function(TransactionItem) onUpdate;
  final VoidCallback onRemove;

  const _TransactionItemCard({
    required this.item,
    required this.products,
    required this.isLoadingProducts,
    required this.canRemove,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_TransactionItemCard> createState() => _TransactionItemCardState();
}

class _TransactionItemCardState extends State<_TransactionItemCard> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.productName);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _priceController = TextEditingController(text: widget.item.pricePerUnit.toStringAsFixed(0));
    _unitController = TextEditingController(text: widget.item.unit);
    
    // Try to find matching product
    if (widget.item.productId != null) {
      _selectedProduct = widget.products.firstWhere(
        (p) => p.id == widget.item.productId,
        orElse: () => widget.products.first,
      );
    }

    _nameController.addListener(_updateItem);
    _quantityController.addListener(_updateItem);
    _priceController.addListener(_updateItem);
    _unitController.addListener(_updateItem);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final subtotal = quantity * price;

    final updatedItem = widget.item.copyWith(
      productId: _selectedProduct?.id,
      productName: _nameController.text,
      quantity: quantity,
      pricePerUnit: price,
      unit: _unitController.text,
      subtotal: subtotal,
    );

    widget.onUpdate(updatedItem);
  }

  void _selectProduct(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _nameController.text = product.name;
        _unitController.text = product.unit;
        _priceController.text = product.defaultSellPrice.toStringAsFixed(0);
      }
    });
    _updateItem();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.canRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Product?>(
              value: _selectedProduct,
              decoration: InputDecoration(
                labelText: 'Pilih Produk',
                border: const OutlineInputBorder(),
                suffixIcon: widget.isLoadingProducts 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              ),
              items: widget.isLoadingProducts 
                ? [
                    const DropdownMenuItem<Product?>(
                      value: null,
                      child: Text('Memuat produk...'),
                    )
                  ]
                : [
                    const DropdownMenuItem<Product?>(
                      value: null,
                      child: Text('Produk Baru'),
                    ),
                    if (widget.products.isNotEmpty) 
                      ...widget.products.map((product) => DropdownMenuItem(
                        value: product,
                        child: Text(product.name),
                      )),
                    if (widget.products.isEmpty)
                      const DropdownMenuItem<Product?>(
                        value: null,
                        child: Text('Tidak ada produk tersimpan'),
                      ),
                  ],
              onChanged: widget.isLoadingProducts ? null : _selectProduct,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama produk harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      final quantity = double.tryParse(value ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Jumlah harus > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Satuan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga per Unit',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                final price = double.tryParse(value ?? '');
                if (price == null || price <= 0) {
                  return 'Harga harus > 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(
                    'Rp ${widget.item.subtotal.toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.',
                    )}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
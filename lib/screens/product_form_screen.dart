import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameController.text = widget.product!.name;
      _unitController.text = widget.product!.unit;
      _basePriceController.text = widget.product!.basePrice.toStringAsFixed(0);
      _sellPriceController.text = widget.product!.defaultSellPrice.toStringAsFixed(0);
      _stockController.text = widget.product!.currentStock.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _basePriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final product = Product(
          id: isEdit ? widget.product!.id : DateTime.now().millisecondsSinceEpoch,
          userId: ProductService.getCurrentUserId(),
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
          basePrice: double.parse(_basePriceController.text),
          defaultSellPrice: double.parse(_sellPriceController.text),
          currentStock: int.parse(_stockController.text),
        );

        if (isEdit) {
          await ProductService.updateProduct(product);
        } else {
          await ProductService.createProduct(product);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit
                    ? 'Produk berhasil diperbarui'
                    : 'Produk berhasil ditambahkan',
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
              content: Text('Gagal menyimpan produk: $e'),
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
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
        backgroundColor: const Color(0xFF5c2d91),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProduct,
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          hintText: 'Contoh: Beras Premium',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan *',
                          hintText: 'Contoh: kg, pcs, liter',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Satuan harus diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _basePriceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Beli *',
                          hintText: '0',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga beli harus diisi';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Harga beli harus berupa angka positif';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sellPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual *',
                          hintText: '0',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga jual harus diisi';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Harga jual harus berupa angka positif';
                          }
                          final basePrice = double.tryParse(_basePriceController.text);
                          if (basePrice != null && price < basePrice) {
                            return 'Harga jual sebaiknya tidak kurang dari harga beli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal *',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Stok awal harus diisi';
                          }
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Stok harus berupa angka positif';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!isEdit)
                const Text(
                  '* Field wajib diisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5c2d91),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'PERBARUI PRODUK' : 'TAMBAH PRODUK',
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
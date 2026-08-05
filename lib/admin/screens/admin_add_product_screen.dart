import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/mock_data_source.dart';
import '../../domain/entities/product.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AdminAddProductScreen extends ConsumerStatefulWidget {
  /// Pass a full Product object (from the products list) when editing.
  final Product? product;

  /// Legacy: pass just the ID; screen will load from Firestore.
  final String? productId;

  const AdminAddProductScreen({super.key, this.product, this.productId});

  @override
  ConsumerState<AdminAddProductScreen> createState() =>
      _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends ConsumerState<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerYardController = TextEditingController();
  final _pricePerMeterController = TextEditingController();
  final _pricePerPieceController = TextEditingController();
  final _colorsController = TextEditingController();

  String? _selectedCategory;
  bool _inStock = true;
  bool _isLoading = false;

  // Images
  final List<XFile> _newImages = []; // picked from device
  List<String> _existingImageUrls = []; // already uploaded URLs

  Product? _loadedProduct;
  bool get isEditing => widget.product != null || widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _prefillFrom(widget.product!);
    } else if (widget.productId != null) {
      _loadFromFirestore(widget.productId!);
    }
  }

  void _prefillFrom(Product p) {
    _loadedProduct = p;
    _nameController.text = p.name;
    _descriptionController.text = p.description;
    _pricePerYardController.text = p.pricePerYard.toStringAsFixed(0);
    _pricePerMeterController.text =
        p.pricePerMeter > 0 ? p.pricePerMeter.toStringAsFixed(0) : '';
    _pricePerPieceController.text =
        p.pricePerPiece > 0 ? p.pricePerPiece.toStringAsFixed(0) : '';
    _colorsController.text = p.colors.join(', ');
    _selectedCategory = p.categoryId;
    _inStock = p.inStock;
    _existingImageUrls = List.from(p.imageUrls);
  }

  Future<void> _loadFromFirestore(String id) async {
    final p = await FirestoreService.instance.getProductById(id);
    if (p != null && mounted) {
      setState(() => _prefillFrom(p));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pricePerYardController.dispose();
    _pricePerMeterController.dispose();
    _pricePerPieceController.dispose();
    _colorsController.dispose();
    super.dispose();
  }

  // ─── Image picking ───────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _newImages.add(picked));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Save ────────────────────────────────────────────────────────

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productId = _loadedProduct?.id ?? const Uuid().v4();

      // Upload new images to Firebase Storage
      final uploadedUrls = <String>[];
      for (final img in _newImages) {
        final url = await StorageService.instance
            .uploadProductImage(File(img.path), productId);
        uploadedUrls.add(url);
      }

      final allImageUrls = [..._existingImageUrls, ...uploadedUrls];

      final category = MockDataSource.categories
          .firstWhere((c) => c.id == _selectedCategory!);

      final product = Product(
        id: productId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategory!,
        categoryName: category.name,
        imageUrls: allImageUrls,
        pricePerYard:
            double.tryParse(_pricePerYardController.text) ?? 0,
        pricePerMeter:
            double.tryParse(_pricePerMeterController.text) ?? 0,
        pricePerPiece:
            double.tryParse(_pricePerPieceController.text) ?? 0,
        inStock: _inStock,
        colors: _colorsController.text
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList(),
        availableUnits: const ['Yard', 'Meter', 'Piece'],
      );

      if (isEditing) {
        await FirestoreService.instance.updateProduct(product);
      } else {
        await FirestoreService.instance.addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Product updated successfully!'
                : 'Product added — customers can now see it!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Images ──
              const Text('Product Images',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor)),
              const SizedBox(height: 4),
              const Text(
                'Add clear photos of the fabric. Customers see these on the product page.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildImageGrid(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _showImageSourceSheet,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Image'),
              ),
              const SizedBox(height: 24),

              // ── Product Name ──
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. Royal Ankara Print',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
              ),
              const SizedBox(height: 16),

              // ── Category ──
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: MockDataSource.categories
                    .map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              // ── Description ──
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe the fabric, pattern, and ideal uses...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter description' : null,
              ),
              const SizedBox(height: 24),

              // ── Pricing ──
              const Text('Pricing',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerYardController,
                      decoration: const InputDecoration(
                        labelText: 'Per Yard *',
                        prefixText: '₦ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pricePerMeterController,
                      decoration: const InputDecoration(
                        labelText: 'Per Meter',
                        prefixText: '₦ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2 - 22,
                child: TextFormField(
                  controller: _pricePerPieceController,
                  decoration: const InputDecoration(
                    labelText: 'Per Piece',
                    prefixText: '₦ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 24),

              // ── Colors ──
              const Text('Available Colors',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorsController,
                decoration: const InputDecoration(
                  labelText: 'Colors',
                  hintText: 'Red & Gold, Blue & White, Green',
                ),
              ),
              const SizedBox(height: 4),
              Text('Separate colors with commas',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 24),

              // ── Stock ──
              SwitchListTile(
                title: const Text('In Stock'),
                subtitle: Text(_inStock
                    ? 'Available for customers to buy'
                    : 'Hidden from customers'),
                value: _inStock,
                onChanged: (v) => setState(() => _inStock = v),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEditing ? 'Update Product' : 'Add Product to Store',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages == 0) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('No images yet', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing uploaded images
          ..._existingImageUrls.asMap().entries.map((entry) {
            return _ImageTile(
              child: Image.network(entry.value, fit: BoxFit.cover),
              onRemove: () =>
                  setState(() => _existingImageUrls.removeAt(entry.key)),
            );
          }),
          // Newly picked images (not yet uploaded)
          ..._newImages.asMap().entries.map((entry) {
            return _ImageTile(
              child: Image.file(File(entry.value.path), fit: BoxFit.cover),
              onRemove: () => setState(() => _newImages.removeAt(entry.key)),
              badge: const Icon(Icons.upload, size: 16, color: Colors.white),
            );
          }),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  final Widget? badge;

  const _ImageTile(
      {required this.child, required this.onRemove, this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.expand(child: child),
          ),
          if (badge != null)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: badge,
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

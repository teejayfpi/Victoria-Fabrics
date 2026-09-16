import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/category.dart';
import '../../services/firestore_service.dart';
import '../../presentation/providers/category_provider.dart';
import '../../presentation/providers/product_provider.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final products = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(categoriesStreamProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) return const _EmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final productCount =
                  products.where((p) => p.categoryId == category.id).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Image.network(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image),
                      ),
                    ),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.description),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$productCount products',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCategoryDialog(context, category);
                      } else if (value == 'delete') {
                        _confirmDelete(context, category);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  /// Add ([existing] == null) or edit a category. Writes go straight to
  /// Firestore; the list rebuilds from its snapshot stream.
  void _showCategoryDialog(BuildContext context, Category? existing) {
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        title: isEditing ? 'Edit Category' : 'Add Category',
        initialName: existing?.name ?? '',
        initialDescription: existing?.description ?? '',
        initialImageUrl: existing?.imageUrl ?? '',
        initialIconName: existing?.iconName ?? 'checkroom',
        submitLabel: isEditing ? 'Update' : 'Add',
        successMessage: isEditing ? 'Category updated' : 'Category added',
        onSubmit: (values) async {
          final category = Category(
            id: existing?.id ?? const Uuid().v4(),
            name: values.name,
            description: values.description,
            imageUrl: values.imageUrl,
            iconName: values.iconName,
          );

          if (isEditing) {
            await FirestoreService.instance.updateCategory(category);
          } else {
            await FirestoreService.instance.addCategory(category);
          }
        },
      ),
    ).then((message) {
      if (message is String && context.mounted) _showSnack(context, message);
    });
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${category.name}"? Products in this category keep their '
            'category reference and will need reassigning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirestoreService.instance.deleteCategory(category.id);
      if (context.mounted) _showSnack(context, '${category.name} deleted');
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Delete failed: $e', isError: true);
      }
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}

/// Field values collected by [_CategoryDialog].
class _CategoryFormValues {
  final String name;
  final String description;
  final String imageUrl;
  final String iconName;

  const _CategoryFormValues({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.iconName,
  });
}

/// Keeps itself open while saving so a failed write reports an error instead
/// of closing as though it had succeeded. Pops the success message on save.
class _CategoryDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String successMessage;
  final String initialName;
  final String initialDescription;
  final String initialImageUrl;
  final String initialIconName;
  final Future<void> Function(_CategoryFormValues values) onSubmit;

  const _CategoryDialog({
    required this.title,
    required this.submitLabel,
    required this.successMessage,
    required this.initialName,
    required this.initialDescription,
    required this.initialImageUrl,
    required this.initialIconName,
    required this.onSubmit,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _iconName;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _description = TextEditingController(text: widget.initialDescription);
    _imageUrl = TextEditingController(text: widget.initialImageUrl);
    _iconName = TextEditingController(text: widget.initialIconName);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _iconName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        _CategoryFormValues(
          name: _name.text.trim(),
          description: _description.text.trim(),
          imageUrl: _imageUrl.text.trim(),
          iconName: _iconName.text.trim().isEmpty
              ? 'checkroom'
              : _iconName.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.pop(context, widget.successMessage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a category name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _iconName,
                decoration: const InputDecoration(
                  labelText: 'Icon name',
                  helperText: 'e.g. checkroom, texture, spa',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('No categories yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Add your first category so customers can browse your fabrics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Could not load categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
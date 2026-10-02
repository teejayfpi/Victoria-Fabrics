import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/error_mapper.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/product_image.dart';
import '../../domain/entities/category.dart';
import '../../presentation/providers/category_provider.dart';
import '../../presentation/providers/product_provider.dart';
import '../providers/admin_auth_provider.dart';

/// Category management. Reads come from the live Firestore stream and writes
/// are guarded by the administrator role check.
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final products = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _ErrorState(
          message: ErrorMapper.map(e, st).message,
          onRetry: () => ref.invalidate(categoriesStreamProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final productCount =
                  products.where((p) => p.categoryId == category.id).length;
              return _CategoryTile(
                category: category,
                productCount: productCount,
                onEdit: () => _showEditor(context, ref, category: category),
                onDelete: () => _confirmDelete(context, ref, category),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController =
        TextEditingController(text: category?.description ?? '');
    final imageController =
        TextEditingController(text: category?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    final isNew = category == null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isNew ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(isNew ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    final base = category ??
        const Category(
          id: '',
          name: '',
          description: '',
          imageUrl: '',
          iconName: 'checkroom',
        );
    final draft = base.copyWith(
      name: nameController.text.trim(),
      description: descController.text.trim(),
      imageUrl: imageController.text.trim(),
    );

    final entity = isNew
        ? Category(
            id: const Uuid().v4(),
            name: draft.name,
            description: draft.description,
            imageUrl: draft.imageUrl,
            iconName: draft.iconName,
          )
        : draft;
    await _save(context, ref, entity, isNew: isNew);
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Category category, {
    required bool isNew,
  }) async {
    try {
      requireAdmin(ref.read(currentAdminProvider), minimum: AdminRole.staff);
      final result = await ref
          .read(categoryRepositoryProvider)
          .save(category, isNew: isNew);
      if (result case Error<void>(failure: final failure)) {
        throw AppException(message: failure.message, code: failure.code);
      }
      AppLogger.info(isNew ? 'Category created' : 'Category updated',
          tag: 'admin_categories', context: {'id': category.id});
      if (context.mounted) {
        _snack(context, isNew ? 'Category added' : 'Category updated',
            success: true);
      }
    } catch (e, st) {
      AppLogger.error('Category save failed',
          tag: 'admin_categories', error: e, stackTrace: st);
      if (context.mounted) {
        _snack(context, ErrorMapper.map(e, st).message);
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"? Existing products keep their category '
          'name but will no longer be grouped under a category.',
        ),
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
      requireAdmin(ref.read(currentAdminProvider), minimum: AdminRole.staff);
      final result =
          await ref.read(categoryRepositoryProvider).delete(category.id);
      if (result case Error<void>(failure: final failure)) {
        throw AppException(message: failure.message, code: failure.code);
      }
      if (context.mounted) _snack(context, 'Category deleted', success: true);
    } catch (e, st) {
      AppLogger.error('Category delete failed',
          tag: 'admin_categories', error: e, stackTrace: st);
      if (context.mounted) _snack(context, ErrorMapper.map(e, st).message);
    }
  }

  void _snack(BuildContext context, String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.productCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int productCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            color: Colors.grey[200],
            child: ProductImage(
              imageUrl: category.imageUrl,
              fallback: const Icon(Icons.image),
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
            if (category.description.isNotEmpty) Text(category.description),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$productCount product${productCount == 1 ? '' : 's'}',
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
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: category.description.isNotEmpty,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No categories yet. Tap “Add Category” to create one.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

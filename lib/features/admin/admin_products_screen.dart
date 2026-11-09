import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/api/product_api.dart';
import '../../data/models/api_error.dart';
import '../../data/models/product.dart';
import '../../state/async_controller.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_placeholder.dart';
import '../../widgets/status_badge.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final AsyncController<List<ProductResponse>> _products;
  final _search = TextEditingController();
  String _query = '';
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _products = AsyncController(context.read<ProductApi>().list)..load();
  }

  @override
  void dispose() {
    _products.dispose();
    _search.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.danger : null,
        ),
      );
  }

  Future<void> _openForm({ProductResponse? product}) async {
    final path = product == null
        ? '/admin/products/new'
        : '/admin/products/${product.id}/edit';
    final message = await context.push<String>(path, extra: product);
    if (!mounted || message == null) return;
    _snack(message);
    await _products.load();
  }

  Future<void> _confirmDelete(ProductResponse product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
        title: const Text('Delete product?'),
        content: Text(
          '"${product.name}" (${product.sku}) will be permanently deleted. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting.add(product.id));
    try {
      final result = await context.read<ProductApi>().delete(product.id);
      if (!mounted) return;
      _snack(
        result.message.isEmpty
            ? 'Product deleted successfully'
            : result.message,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.kind) {
        case ApiErrorKind.conflict:
          _snack(
            'This product is used in orders. Set it inactive instead.',
            error: true,
          );
        case ApiErrorKind.notFound:
          _snack('This product no longer exists.', error: true);
        case ApiErrorKind.forbidden:
          _snack('Access denied: you can\'t delete products.', error: true);
        case ApiErrorKind.sessionExpired:
          return;
        default:
          _snack(ErrorInfo.from(e).message, error: true);
      }
    } catch (e) {
      if (mounted) _snack(ErrorInfo.from(e).message, error: true);
    } finally {
      if (mounted) setState(() => _deleting.remove(product.id));
    }
    if (mounted) await _products.load();
  }

  List<ProductResponse> _filter(List<ProductResponse> all) {
    final q = _query.trim().toLowerCase();
    final list =
        all
            .where(
              (p) =>
                  q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name or SKU',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _products.load,
              child: ListenableBuilder(
                listenable: _products,
                builder: (context, _) => _buildList(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final data = _products.data;
    final error = _products.error;

    Widget scrollableFill(Widget child) => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: child),
      ),
    );

    if (error != null && !_products.isLoading) {
      return scrollableFill(ErrorView(error: error, onRetry: _products.load));
    }
    if (data == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: ListSkeleton(rows: 6),
          ),
        ),
      );
    }

    final products = _filter(data);
    if (products.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return scrollableFill(
        EmptyView(
          icon: searching ? Icons.search_off : Icons.inventory_2_outlined,
          title: searching ? 'No matching products' : 'No products yet',
          message: searching
              ? 'Try another name or SKU.'
              : 'Create your first product to get started.',
          action: searching
              ? null
              : FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('New product'),
                ),
        ),
      );
    }

    final activeCount = data.where((p) => p.active).length;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: products.length + 1,
      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 4 : 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Text(
            '${data.length} products · $activeCount active'
            '${_query.trim().isEmpty ? '' : ' · ${products.length} shown'}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
          );
        }
        final p = products[i - 1];
        return _ProductTile(
          product: p,
          deleting: _deleting.contains(p.id),
          onEdit: () => _openForm(product: p),
          onDelete: () => _confirmDelete(p),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductResponse product;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: deleting ? null : onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Opacity(
                  opacity: product.active ? 1 : 0.5,
                  child: ProductImage(
                    url: product.coverImage,
                    seed: product.id,
                    name: product.name,
                    size: PlaceholderSize.avatar,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${product.sku} · ${Formatters.currency(product.unitPrice)}'
                      ' · ${Formatters.integer(product.quantityInStock)} in stock',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusBadge.active(product.active),
                        StatusBadge.stock(product),
                      ],
                    ),
                  ],
                ),
              ),
              if (deleting)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<String>(
                  tooltip: 'Actions for ${product.name}',
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

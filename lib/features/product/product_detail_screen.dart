import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../data/api/product_api.dart';
import '../../data/models/api_error.dart';
import '../../core/config.dart';
import '../../data/models/product.dart';
import '../../state/async_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/cart_controller.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_placeholder.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/status_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  AsyncController<ProductResponse>? _product;

  bool get _validId => Validators.isUuid(widget.productId);

  @override
  void initState() {
    super.initState();
    if (_validId) {
      final api = context.read<ProductApi>();
      _product = AsyncController(() => api.get(widget.productId))..load();
    }
  }

  @override
  void dispose() {
    _product?.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _product;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: const Text('Product details'),
        actions: const [CartButton(), SizedBox(width: 4)],
      ),
      body: controller == null
          ? _NotFound(onBack: () => context.go('/'))
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final product = controller.data;
                final error = controller.error;
                if (product == null && error == null) {
                  return const _DetailSkeleton();
                }
                if (error != null && !controller.isLoading) {
                  if (error is ApiException &&
                      error.kind == ApiErrorKind.notFound) {
                    return _NotFound(onBack: () => context.go('/'));
                  }
                  return ErrorView(
                    error: error,
                    publicRequest: true,
                    onRetry: controller.load,
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: _DetailBody(product: product!),
                );
              },
            ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: Icons.search_off,
      title: 'Product not found',
      message: 'This product doesn\'t exist or may have been removed.',
      action: FilledButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.storefront_outlined),
        label: const Text('Back to products'),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.product});

  final ProductResponse product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = product.description?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final art = AspectRatio(
          aspectRatio: wide ? 1 : 16 / 10,
          child: _Gallery(product: product),
        );

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusBadge.stock(product),
                if (!product.active) StatusBadge.active(false),
              ],
            ),
            const SizedBox(height: 12),
            Text(product.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            SelectableText(
              'SKU: ${product.sku}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Formatters.currency(product.unitPrice),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Availability',
                      value: product.quantityInStock > 0
                          ? '${Formatters.integer(product.quantityInStock)} in stock'
                          : 'Out of stock',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.toggle_on_outlined,
                      label: 'Status',
                      value: product.active ? 'Active' : 'Inactive',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.update,
                      label: 'Last updated',
                      value: Formatters.dateTime(product.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text('Description', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 6),
            Text(
              (description == null || description.isEmpty)
                  ? 'No description'
                  : description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: (description == null || description.isEmpty)
                    ? AppColors.inkMuted
                    : null,
                fontStyle: (description == null || description.isEmpty)
                    ? FontStyle.italic
                    : null,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            _AddToCart(product: product),
          ],
        );

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: art),
                  const SizedBox(width: 24),
                  Expanded(child: info),
                ],
              )
            else ...[
              art,
              const SizedBox(height: 20),
              info,
            ],
          ],
        );
      },
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final ProductResponse product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final urls = product.galleryImages;
    final radius = BorderRadius.circular(20);

    if (urls.length <= 1) {
      return Hero(
        tag: 'product-art-${product.id}',
        child: ProductImage(
          url: urls.isEmpty ? null : urls.first,
          seed: product.id,
          name: product.name,
          size: PlaceholderSize.hero,
          borderRadius: radius,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _page,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final image = ProductImage(
                url: urls[i],
                seed: product.id,
                name: '${product.name}, image ${i + 1} of ${urls.length}',
                size: PlaceholderSize.hero,
                borderRadius: radius,
              );
              return i == 0
                  ? Hero(tag: 'product-art-${product.id}', child: image)
                  : image;
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < urls.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddToCart extends StatefulWidget {
  const _AddToCart({required this.product});

  final ProductResponse product;

  @override
  State<_AddToCart> createState() => _AddToCartState();
}

class _AddToCartState extends State<_AddToCart> {
  int _quantity = 1;
  bool _adding = false;

  Future<void> _add() async {
    final product = widget.product;
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      final from = Uri.encodeComponent('/products/${product.id}');
      context.go('/login?from=$from');
      return;
    }
    final cart = context.read<CartController>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _adding = true);
    try {
      await cart.add(product.id, _quantity);
      if (!mounted) return;
      final added = _quantity;
      setState(() => _quantity = 1);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Added $added × ${product.name} to your cart'),
            action: SnackBarAction(
              label: 'View cart',
              onPressed: () => router.push('/cart'),
            ),
          ),
        );
    } on ApiException catch (e) {
      if (!mounted || e.kind == ApiErrorKind.sessionExpired) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(ErrorInfo.from(e).message),
            backgroundColor: AppColors.danger,
          ),
        );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(ErrorInfo.from(e).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final inCart = context.watch<CartController>().quantityOf(product.id);

    if (!product.active || product.quantityInStock <= 0) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: null,
          icon: const Icon(Icons.block),
          label: Text(
            product.active ? 'Out of stock' : 'Currently unavailable',
          ),
        ),
      );
    }

    final cap = product.quantityInStock < AppConfig.maxCartQuantity
        ? product.quantityInStock
        : AppConfig.maxCartQuantity;
    final remaining = cap - inCart;
    if (remaining <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => context.push('/cart'),
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text('In your cart: $inCart · View cart'),
          ),
          const SizedBox(height: 8),
          Text(
            'You already have the maximum available quantity in your cart.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      );
    }
    final quantity = _quantity.clamp(1, remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            QuantityStepper(
              value: quantity,
              min: 1,
              max: remaining,
              enabled: !_adding,
              onChanged: (v) => setState(() => _quantity = v),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _adding
                    ? null
                    : () {
                        _quantity = quantity;
                        _add();
                      },
                icon: _adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Adding to cart',
                        ),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: const Text('Add to cart'),
              ),
            ),
          ],
        ),
        if (inCart > 0) ...[
          const SizedBox(height: 8),
          Text(
            'In your cart: $inCart',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: const [
        AspectRatio(aspectRatio: 16 / 10, child: SkeletonBox(radius: 20)),
        SizedBox(height: 20),
        SkeletonBox(height: 20, width: 90, radius: 999),
        SizedBox(height: 14),
        SkeletonBox(height: 26),
        SizedBox(height: 10),
        SkeletonBox(height: 14, width: 140),
        SizedBox(height: 20),
        SkeletonBox(height: 32, width: 150),
        SizedBox(height: 20),
        SkeletonBox(height: 140, radius: 16),
      ],
    );
  }
}

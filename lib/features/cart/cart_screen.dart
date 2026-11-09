import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/formatters.dart';
import '../../data/models/cart.dart';
import '../../state/cart_controller.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_placeholder.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/snackbars.dart';
import '../../widgets/status_badge.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartController>().load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (e) {
      if (mounted) showErrorSnackBar(messenger, e);
    }
  }

  Future<void> _confirmClear(CartController controller) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed from your cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (ok == true) await _run(controller.clear);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CartController>();
    final cart = controller.cart;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('Your cart'),
        actions: [
          if (cart != null && !cart.isEmpty)
            TextButton(
              onPressed: controller.isBusy
                  ? null
                  : () => _confirmClear(controller),
              child: const Text('Clear cart'),
            ),
        ],
        bottom: controller.isBusy || (controller.isLoading && cart != null)
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _body(context, controller),
      bottomNavigationBar: cart == null || cart.isEmpty
          ? null
          : _CheckoutBar(cart: cart, busy: controller.isBusy),
    );
  }

  Widget _body(BuildContext context, CartController controller) {
    final cart = controller.cart;
    if (cart == null) {
      if (controller.error != null && !controller.isLoading) {
        return ErrorView(error: controller.error!, onRetry: controller.load);
      }
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ListSkeleton(rows: 4),
      );
    }

    if (cart.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            EmptyView(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Browse products and add something you like.',
              action: FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Browse products'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (controller.error != null && !controller.isLoading) ...[
            ErrorView(
              error: controller.error!,
              onRetry: controller.load,
              compact: true,
            ),
            const SizedBox(height: 12),
          ],
          if (cart.hasUnavailableItems) ...[
            const _Notice(
              text:
                  'Some items are unavailable or exceed the stock. '
                  'Update or remove them to check out.',
            ),
            const SizedBox(height: 12),
          ],
          for (final item in cart.items) ...[
            Dismissible(
              key: ValueKey(item.id),
              direction: controller.isBusy
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
              ),
              confirmDismiss: (_) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await controller.remove(item.productId);
                  return false;
                } catch (e) {
                  if (mounted) showErrorSnackBar(messenger, e);
                  return false;
                }
              },
              child: _CartItemTile(
                item: item,
                busy: controller.isBusy,
                onQuantity: (q) =>
                    _run(() => controller.setQuantity(item.productId, q)),
                onRemove: () => _run(() => controller.remove(item.productId)),
                onOpen: () => context.push('/products/${item.productId}'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Prices are current product prices; they are locked in when you '
            'check out.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.busy,
    required this.onQuantity,
    required this.onRemove,
    required this.onOpen,
  });

  final CartItem item;
  final bool busy;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cap = item.quantityInStock < AppConfig.maxCartQuantity
        ? item.quantityInStock
        : AppConfig.maxCartQuantity;
    final max = cap < item.quantity ? item.quantity : cap;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Opacity(
                  opacity: item.available ? 1 : 0.55,
                  child: ProductImage(
                    url: item.thumbnail,
                    seed: item.productId,
                    name: item.productName,
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
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item.sku} · ${Formatters.currency(item.unitPrice)} each',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    if (!item.available) ...[
                      const SizedBox(height: 6),
                      StatusBadge(
                        icon: Icons.warning_amber_rounded,
                        label: item.quantityInStock <= 0
                            ? 'Unavailable'
                            : item.quantity > item.quantityInStock
                            ? 'Only ${item.quantityInStock} in stock'
                            : 'Unavailable',
                        foreground: AppColors.danger,
                        background: AppColors.dangerBg,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        QuantityStepper(
                          value: item.quantity,
                          min: 1,
                          max: max < 1 ? 1 : max,
                          enabled: !busy,
                          onChanged: onQuantity,
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            Formatters.currency(item.lineTotal),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${item.productName}',
                onPressed: busy ? null : onRemove,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart, required this.busy});

  final Cart cart;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocked = cart.hasUnavailableItems;
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.totalQuantity} item${cart.totalQuantity == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Text(
                      Formatters.currency(cart.totalAmount),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: busy || blocked || cart.isEmpty
                    ? null
                    : () => context.push('/checkout'),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

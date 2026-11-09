import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../data/api/order_api.dart';
import '../../data/models/api_error.dart';
import '../../data/models/order.dart';
import '../../state/async_controller.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_placeholder.dart';
import '../../widgets/section_card.dart';
import '../../widgets/snackbars.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.initial});

  final String orderId;

  final OrderResponse? initial;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  AsyncController<OrderResponse>? _order;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    if (Validators.isUuid(widget.orderId)) {
      final api = context.read<OrderApi>();
      _order = AsyncController(
        () => api.myOrder(widget.orderId),
        initialData: widget.initial,
      )..load();
    }
  }

  @override
  void dispose() {
    _order?.dispose();
    super.dispose();
  }

  Future<void> _cancel(OrderResponse order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Text(
          'Order ${order.orderNumber} will be cancelled. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final api = context.read<OrderApi>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _cancelling = true);
    try {
      await api.cancel(order.id);
      if (mounted) {
        showInfoSnackBar(messenger, 'Order ${order.orderNumber} cancelled');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(messenger, e);
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
        _order?.load();
      }
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _order;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: const Text('Order details'),
      ),
      body: controller == null
          ? _notFound(context)
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final order = controller.data;
                final error = controller.error;
                if (error != null && !controller.isLoading) {
                  if (error is ApiException &&
                      error.kind == ApiErrorKind.notFound) {
                    return _notFound(context);
                  }
                  if (order == null) {
                    return ErrorView(error: error, onRetry: controller.load);
                  }
                }
                if (order == null) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: ListSkeleton(rows: 4),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.load,
                  child: _OrderBody(
                    order: order,
                    error: error,
                    onRetry: controller.load,
                    cancelling: _cancelling,
                    onCancel: () => _cancel(order),
                  ),
                );
              },
            ),
    );
  }

  Widget _notFound(BuildContext context) => EmptyView(
    icon: Icons.search_off,
    title: 'Order not found',
    message: 'This order doesn\'t exist or doesn\'t belong to your account.',
    action: FilledButton(
      onPressed: () => context.go('/orders'),
      child: const Text('Back to my orders'),
    ),
  );
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({
    required this.order,
    required this.error,
    required this.onRetry,
    required this.cancelling,
    required this.onCancel,
  });

  final OrderResponse order;
  final Object? error;
  final VoidCallback onRetry;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = order.customer;
    final phone = customer.phone?.trim();
    final address = customer.address?.trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (error != null) ...[
          ErrorView(error: error!, onRetry: onRetry, compact: true),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: SelectableText(
                order.orderNumber,
                style: theme.textTheme.titleLarge,
              ),
            ),
            StatusBadge.order(order.status),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Placed ${Formatters.dateTime(order.orderDate)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        if (order.isPending) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pending: the store will complete this order. No payment was taken.',
              style: TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          title: 'Items',
          icon: Icons.shopping_bag_outlined,
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0) const Divider(height: 16),
                _ItemRow(item: order.items[i]),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text('Total', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    Formatters.currency(order.totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Contact',
          icon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(customer.fullName, style: theme.textTheme.bodyLarge),
              Text(customer.email, style: theme.textTheme.bodyMedium),
              if (phone != null && phone.isNotEmpty) Text(phone),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(address),
              ],
            ],
          ),
        ),
        if (order.isPending) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: cancelling ? null : onCancel,
            icon: cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Cancelling order',
                    ),
                  )
                : const Icon(Icons.cancel_outlined),
            label: const Text('Cancel order'),
          ),
        ],
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItemResponse item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/products/${item.productId}'),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ProductImage(
              url: item.thumbnail,
              seed: item.productId,
              name: item.productName,
              size: PlaceholderSize.avatar,
              borderRadius: BorderRadius.circular(10),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${item.quantity} × ${Formatters.currency(item.unitPrice)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(item.lineTotal),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

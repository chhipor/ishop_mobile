import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/api/order_api.dart';
import '../../data/models/order.dart';
import '../../state/async_controller.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_placeholder.dart';
import '../../widgets/status_badge.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final AsyncController<List<OrderResponse>> _orders;

  @override
  void initState() {
    super.initState();
    final api = context.read<OrderApi>();
    _orders = AsyncController(api.myOrders)..load();
  }

  @override
  void dispose() {
    _orders.dispose();
    super.dispose();
  }

  Future<void> _open(OrderResponse order) async {
    await context.push('/orders/${order.id}', extra: order);
    if (mounted) _orders.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('My orders'),
      ),
      body: ListenableBuilder(
        listenable: _orders,
        builder: (context, _) {
          final orders = _orders.data;
          final error = _orders.error;
          if (orders == null) {
            if (error != null && !_orders.isLoading) {
              return ErrorView(error: error, onRetry: _orders.load);
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ListSkeleton(rows: 5),
            );
          }
          return RefreshIndicator(
            onRefresh: _orders.load,
            child: orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      EmptyView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders yet',
                        message: 'Orders you place will show up here.',
                        action: FilledButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Browse products'),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: orders.length + (error != null ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (error != null) {
                        if (i == 0) {
                          return ErrorView(
                            error: error,
                            onRetry: _orders.load,
                            compact: true,
                          );
                        }
                        i--;
                      }
                      final order = orders[i];
                      return _OrderCard(
                        order: order,
                        onTap: () => _open(order),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderResponse order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = order.items.take(4).toList();
    final extra = order.items.length - shown.length;
    final count = order.totalQuantity;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusBadge.order(order.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${Formatters.dateTime(order.orderDate)} · '
                '$count item${count == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final item in shown) ...[
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: ProductImage(
                        url: item.thumbnail,
                        seed: item.productId,
                        name: item.productName,
                        size: PlaceholderSize.avatar,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (extra > 0)
                    Text(
                      '+$extra',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    Formatters.currency(order.totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
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

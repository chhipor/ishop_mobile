import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../data/api/product_api.dart';
import '../../data/models/product.dart';
import '../../state/async_controller.dart';
import '../../widgets/account_menu.dart';
import '../../widgets/cart_button.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/product_card.dart';

enum ProductSort { name, priceLowHigh, priceHighLow }

extension on ProductSort {
  String get label => switch (this) {
    ProductSort.name => 'Name (A–Z)',
    ProductSort.priceLowHigh => 'Price: low to high',
    ProductSort.priceHighLow => 'Price: high to low',
  };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AsyncController<List<ProductResponse>> _products;
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  ProductSort _sort = ProductSort.name;

  int _page = 0;

  @override
  void initState() {
    super.initState();
    final api = context.read<ProductApi>();
    _products = AsyncController(api.list)..load();
  }

  @override
  void dispose() {
    _products.dispose();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  List<ProductResponse> _visible(List<ProductResponse> all) {
    final q = _query.trim().toLowerCase();
    final list = all
        .where((p) => p.active)
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q),
        )
        .toList();
    switch (_sort) {
      case ProductSort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case ProductSort.priceLowHigh:
        list.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
      case ProductSort.priceHighLow:
        list.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _Brand(),
        actions: const [CartButton(), AccountMenu()],
      ),
      body: RefreshIndicator(
        onRefresh: _products.load,
        child: ListenableBuilder(
          listenable: _products,
          builder: (context, _) => CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _HeroBanner()),
              SliverToBoxAdapter(child: _buildToolbar(context)),
              ..._buildContent(context),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _query = v;
                _page = 0;
              }),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _page = 0;
                          });
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<ProductSort>(
            tooltip: 'Sort products',
            initialValue: _sort,
            onSelected: (s) => setState(() {
              _sort = s;
              _page = 0;
            }),
            itemBuilder: (_) => [
              for (final s in ProductSort.values)
                CheckedPopupMenuItem(
                  value: s,
                  checked: s == _sort,
                  child: Text(s.label),
                ),
            ],
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.sort),
            ),
          ),
        ],
      ),
    );
  }

  SliverGridDelegate get _gridDelegate =>
      const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      );

  List<Widget> _buildContent(BuildContext context) {
    final data = _products.data;

    if (data == null && _products.error == null) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (_, _) => const ProductCardSkeleton(),
              childCount: AppConfig.productsPerPage,
            ),
          ),
        ),
      ];
    }

    if (_products.error != null && !_products.isLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            error: _products.error!,
            publicRequest: true,
            onRetry: _products.load,
          ),
        ),
      ];
    }

    final all = data ?? const <ProductResponse>[];
    final visible = _visible(all);
    if (visible.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: searching ? Icons.search_off : Icons.inventory_2_outlined,
            title: searching ? 'No matching products' : 'No products yet',
            message: searching
                ? 'Nothing matches "${_query.trim()}". Try another name or SKU.'
                : 'Check back soon — new electronics are on the way.',
          ),
        ),
      ];
    }

    const perPage = AppConfig.productsPerPage;
    final pageCount = (visible.length + perPage - 1) ~/ perPage;
    final page = _page.clamp(0, pageCount - 1);
    final start = page * perPage;
    final end = (start + perPage).clamp(0, visible.length);
    final pageItems = visible.sublist(start, end);
    final total = visible.length;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: Text(
            pageCount > 1
                ? 'Showing ${start + 1}–$end of $total products'
                : '$total product${total == 1 ? '' : 's'}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate((context, i) {
            final p = pageItems[i];
            return ProductCard(
              product: p,
              onTap: () => context.push('/products/${p.id}'),
            );
          }, childCount: pageItems.length),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverToBoxAdapter(
          child: PaginationBar(
            page: page,
            pageCount: pageCount,
            onChanged: _goToPage,
          ),
        ),
      ),
    ];
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'iShop',
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'iShop',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF38BDF8)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The latest electronics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Phones, laptops, audio and more — '
                    'add them to your cart and order online.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.laptop_mac,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -4,
                    child: Icon(
                      Icons.smartphone,
                      size: 34,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
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

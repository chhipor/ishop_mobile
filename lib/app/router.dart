import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/order.dart';
import '../data/models/product.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_products_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/product_form_screen.dart';
import '../features/auth/forbidden_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/my_orders_screen.dart';
import '../features/orders/order_detail_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../state/auth_controller.dart';
import '../widgets/empty_view.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) => _guard(auth, state),
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to products'),
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(
          key: ValueKey(state.pathParameters['id']),
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const MyOrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final extra = state.extra;
              return OrderDetailScreen(
                key: ValueKey(id),
                orderId: id,
                initial: extra is OrderResponse && extra.id == id
                    ? extra
                    : null,
              );
            },
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/admin/products',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminProductsScreen()),
            routes: [
              GoRoute(
                path: 'new',
                parentNavigatorKey: _rootKey,
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                parentNavigatorKey: _rootKey,
                builder: (context, state) {
                  final extra = state.extra;
                  final id = state.pathParameters['id']!;
                  return ProductFormScreen(
                    productId: id,
                    initial: extra is ProductResponse && extra.id == id
                        ? extra
                        : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String postLoginLocation(AuthController auth, String? from) {
  if (from != null && from.startsWith('/') && !from.startsWith('/login')) {
    return from;
  }
  return auth.isAdmin ? '/admin' : '/';
}

bool _isCustomerRoute(String path) =>
    path == '/cart' ||
    path == '/checkout' ||
    path == '/orders' ||
    path.startsWith('/orders/');

String? _guard(AuthController auth, GoRouterState state) {
  final path = state.matchedLocation;

  if (_isCustomerRoute(path) && !auth.isLoggedIn) {
    final from = Uri.encodeComponent(state.uri.toString());
    return '/login?from=$from';
  }

  if (path == '/admin' || path.startsWith('/admin/')) {
    if (!auth.isLoggedIn) {
      final from = Uri.encodeComponent(state.uri.toString());
      return '/login?from=$from';
    }
    if (!auth.isAdmin) return '/forbidden';
    return null;
  }

  if (path == '/login' && auth.isLoggedIn) {
    return postLoginLocation(auth, state.uri.queryParameters['from']);
  }

  if (path == '/forbidden' && auth.isAdmin) return '/admin';

  return null;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/api/admin_api.dart';
import 'data/api/api_client.dart';
import 'data/api/auth_api.dart';
import 'data/api/cart_api.dart';
import 'data/api/customer_api.dart';
import 'data/api/order_api.dart';
import 'data/api/product_api.dart';
import 'data/storage/token_storage.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US');

  final storage = await TokenStorage.create();
  final client = ApiClient(storage: storage);
  final authApi = AuthApi(client);
  final auth = AuthController(
    storage: storage,
    client: client,
    authApi: authApi,
  );

  runApp(
    IShopApp(
      auth: auth,
      cart: CartController(api: CartApi(client), auth: auth),
      productApi: ProductApi(client),
      adminApi: AdminApi(client),
      orderApi: OrderApi(client),
      customerApi: CustomerApi(client),
    ),
  );
}

class IShopApp extends StatefulWidget {
  const IShopApp({
    super.key,
    required this.auth,
    required this.cart,
    required this.productApi,
    required this.adminApi,
    required this.orderApi,
    required this.customerApi,
  });

  final AuthController auth;
  final CartController cart;
  final ProductApi productApi;
  final AdminApi adminApi;
  final OrderApi orderApi;
  final CustomerApi customerApi;

  @override
  State<IShopApp> createState() => _IShopAppState();
}

class _IShopAppState extends State<IShopApp> {
  late final GoRouter _router = buildRouter(widget.auth);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: widget.auth),
        Provider<ProductApi>.value(value: widget.productApi),
        ChangeNotifierProvider<CartController>.value(value: widget.cart),
        Provider<AdminApi>.value(value: widget.adminApi),
        Provider<OrderApi>.value(value: widget.orderApi),
        Provider<CustomerApi>.value(value: widget.customerApi),
      ],
      child: MaterialApp.router(
        title: 'iShop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}

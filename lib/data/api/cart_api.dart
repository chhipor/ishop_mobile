import '../models/cart.dart';
import '../models/order.dart';
import 'api_client.dart';

class CartApi {
  CartApi(this._client);

  final ApiClient _client;

  static const _base = '/api/operations/cart';

  Future<Cart> get() async => _cart(await _client.get(_base, auth: true));

  Future<Cart> clear() async => _cart(await _client.delete(_base, auth: true));

  Future<Cart> addItem(String productId, int quantity) async => _cart(
    await _client.post(
      '$_base/items',
      body: {'productId': productId, 'quantity': quantity},
      auth: true,
    ),
  );

  Future<Cart> setQuantity(String productId, int quantity) async => _cart(
    await _client.put(
      '$_base/items/$productId',
      body: {'quantity': quantity},
      auth: true,
    ),
  );

  Future<Cart> removeItem(String productId) async =>
      _cart(await _client.delete('$_base/items/$productId', auth: true));

  Future<OrderResponse> checkout() async {
    final json = await _client.post('$_base/checkout', auth: true);
    return OrderResponse.fromJson(json as Map<String, dynamic>);
  }

  static Cart _cart(Object? json) =>
      Cart.fromJson(json as Map<String, dynamic>);
}

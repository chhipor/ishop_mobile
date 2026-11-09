import '../models/order.dart';
import 'api_client.dart';

class OrderApi {
  OrderApi(this._client);

  final ApiClient _client;

  static const _base = '/api/operations/orders/me';

  Future<List<OrderResponse>> myOrders() async {
    final json = await _client.get(_base, auth: true) as List<dynamic>;
    return json
        .map((e) => OrderResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderResponse> myOrder(String id) async => OrderResponse.fromJson(
    await _client.get('$_base/$id', auth: true) as Map<String, dynamic>,
  );

  Future<OrderResponse> cancel(String id) async => OrderResponse.fromJson(
    await _client.post('$_base/$id/cancel', auth: true) as Map<String, dynamic>,
  );
}

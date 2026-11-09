import '../models/product.dart';
import 'api_client.dart';

class ProductApi {
  ProductApi(this._client);

  final ApiClient _client;

  static const _base = '/api/operations/products';

  Future<List<ProductResponse>> list() async {
    final json = await _client.get(_base) as List<dynamic>;
    return json
        .map((e) => ProductResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductResponse> get(String id) async {
    final json = await _client.get('$_base/$id');
    return ProductResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<ProductResponse> create(ProductRequest request) async {
    final json = await _client.post(_base, body: request.toJson(), auth: true);
    return ProductResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<ProductResponse> update(String id, ProductRequest request) async {
    final json = await _client.put(
      '$_base/$id',
      body: request.toJson(),
      auth: true,
    );
    return ProductResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<MessageResponse> delete(String id) async {
    final json = await _client.delete('$_base/$id', auth: true);
    return json is Map<String, dynamic>
        ? MessageResponse.fromJson(json)
        : const MessageResponse(message: 'Product deleted successfully');
  }
}

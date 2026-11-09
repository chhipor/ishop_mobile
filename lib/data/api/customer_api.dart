import '../models/order.dart';
import 'api_client.dart';

class CustomerApi {
  CustomerApi(this._client);

  final ApiClient _client;

  static const _me = '/api/operations/customers/me';

  Future<CustomerResponse> me() async => CustomerResponse.fromJson(
    await _client.get(_me, auth: true) as Map<String, dynamic>,
  );

  Future<CustomerResponse> updateMe(CustomerProfileRequest request) async =>
      CustomerResponse.fromJson(
        await _client.put(_me, body: request.toJson(), auth: true)
            as Map<String, dynamic>,
      );
}

import '../models/auth_response.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResponse> login(LoginRequest request) async {
    final json = await _client.post('/api/auth/login', body: request.toJson());
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }
}

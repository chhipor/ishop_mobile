import 'package:flutter/foundation.dart';

import '../data/api/api_client.dart';
import '../data/api/auth_api.dart';
import '../data/models/auth_response.dart';
import '../data/models/user.dart';
import '../data/storage/token_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required TokenStorage storage,
    required ApiClient client,
    required this.authApi,
  }) : _storage = storage,
       _user = storage.hasSession ? storage.user : null {
    client.onSessionUpdated = (session) {
      _user = session.user;
      notifyListeners();
    };
    client.onSessionExpired = () {
      _user = null;
      _sessionExpired = true;
      notifyListeners();
    };
  }

  final TokenStorage _storage;
  final AuthApi authApi;

  UserResponse? _user;
  bool _sessionExpired = false;

  UserResponse? get user => _user;
  bool get isLoggedIn => _user != null && _storage.accessToken != null;
  bool get isAdmin => isLoggedIn && _user!.roles.contains('ADMIN');

  bool get sessionExpired => _sessionExpired;

  void acknowledgeSessionExpired() => _sessionExpired = false;

  Future<UserResponse> login(String email, String password) async {
    final session = await authApi.login(
      LoginRequest(email: email.trim(), password: password),
    );
    await _storage.save(session);
    _user = session.user;
    _sessionExpired = false;
    notifyListeners();
    return session.user;
  }

  Future<void> logout() async {
    await _storage.clear();
    _user = null;
    _sessionExpired = false;
    notifyListeners();
  }
}

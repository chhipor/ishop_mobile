import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/user.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  static const _kAccessToken = 'ishop.accessToken';
  static const _kRefreshToken = 'ishop.refreshToken';
  static const _kUser = 'ishop.user';

  final SharedPreferences _prefs;

  String? _accessToken;
  String? _refreshToken;
  UserResponse? _user;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  UserResponse? get user => _user;
  bool get hasSession => _accessToken != null && _user != null;

  static Future<TokenStorage> create() async {
    final storage = TokenStorage(await SharedPreferences.getInstance());
    await storage.read();
    return storage;
  }

  Future<void> read() async {
    _accessToken = _prefs.getString(_kAccessToken);
    _refreshToken = _prefs.getString(_kRefreshToken);
    final rawUser = _prefs.getString(_kUser);
    try {
      _user = rawUser == null
          ? null
          : UserResponse.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return;
    }
    if (_accessToken == null || _user == null) {
      if (_accessToken != null || _refreshToken != null || _user != null) {
        await clear();
      }
    }
  }

  Future<void> save(AuthResponse session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _user = session.user;
    await Future.wait([
      _prefs.setString(_kAccessToken, session.accessToken),
      _prefs.setString(_kRefreshToken, session.refreshToken),
      _prefs.setString(_kUser, jsonEncode(session.user.toJson())),
    ]);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    await Future.wait([
      _prefs.remove(_kAccessToken),
      _prefs.remove(_kRefreshToken),
      _prefs.remove(_kUser),
    ]);
  }
}

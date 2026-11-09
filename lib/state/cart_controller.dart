import 'package:flutter/foundation.dart';

import '../data/api/cart_api.dart';
import '../data/models/cart.dart';
import '../data/models/order.dart';
import 'auth_controller.dart';

class CartController extends ChangeNotifier {
  CartController({required this.api, required AuthController auth})
    : _auth = auth {
    _userId = auth.isLoggedIn ? auth.user?.id : null;
    auth.addListener(_onAuthChanged);
    if (_userId != null) load();
  }

  final CartApi api;
  final AuthController _auth;

  String? _userId;
  Cart? _cart;
  Object? _error;
  bool _loading = false;
  bool _busy = false;
  int _generation = 0;

  Cart? get cart => _cart;
  Object? get error => _error;
  bool get isLoading => _loading;

  bool get isBusy => _busy;

  int get totalQuantity => _cart?.totalQuantity ?? 0;

  int quantityOf(String productId) => _cart?.quantityOf(productId) ?? 0;

  void _onAuthChanged() {
    final id = _auth.isLoggedIn ? _auth.user?.id : null;
    if (id == _userId) return;
    _userId = id;
    _generation++;
    _cart = null;
    _error = null;
    _loading = false;
    _busy = false;
    notifyListeners();
    if (id != null) load();
  }

  Future<void> load() async {
    if (_userId == null) return;
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cart = await api.get();
      if (generation != _generation) return;
      _cart = cart;
    } catch (e) {
      if (generation != _generation) return;
      _error = e;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> add(String productId, int quantity) =>
      _mutate(() => api.addItem(productId, quantity));

  Future<void> setQuantity(String productId, int quantity) =>
      _mutate(() => api.setQuantity(productId, quantity));

  Future<void> remove(String productId) =>
      _mutate(() => api.removeItem(productId));

  Future<void> clear() => _mutate(api.clear);

  Future<OrderResponse> checkout() async {
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      return await api.checkout();
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
        load();
      }
    }
  }

  Future<void> _mutate(Future<Cart> Function() op) async {
    final generation = _generation;
    _busy = true;
    notifyListeners();
    try {
      final cart = await op();
      if (generation != _generation) return;
      _cart = cart;
      _error = null;
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

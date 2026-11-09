import 'package:flutter/foundation.dart';

class AsyncController<T> extends ChangeNotifier {
  AsyncController(this._loader, {T? initialData}) : _data = initialData;

  final Future<T> Function() _loader;

  T? _data;
  Object? _error;
  bool _loading = false;
  bool _disposed = false;
  int _generation = 0;

  T? get data => _data;
  Object? get error => _error;
  bool get isLoading => _loading;
  bool get hasData => _data != null;

  Future<void> load() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    _notify();
    try {
      final result = await _loader();
      if (generation != _generation) return;
      _data = result;
    } catch (e) {
      if (generation != _generation) return;
      _error = e;
    } finally {
      if (generation == _generation) {
        _loading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

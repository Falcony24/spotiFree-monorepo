
class ApiCache {
  static final ApiCache _instance = ApiCache._();
  factory ApiCache() => _instance;
  ApiCache._();

  final Map<String, _CacheEntry> _store = {};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > entry.expiresAt) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(seconds: 30)}) {
    _store[key] = _CacheEntry(
      value: value,
      expiresAt:
          DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds,
    );
  }

  void invalidate({String? key, String? prefix}) {
    if (key != null) {
      _store.remove(key);
    }
    if (prefix != null) {
      _store.removeWhere((k, _) => k.startsWith(prefix));
    }
  }

  void clear() {
    _store.clear();
  }
}

class _CacheEntry {
  final dynamic value;
  final int expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});
}

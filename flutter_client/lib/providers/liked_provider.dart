import 'package:flutter/foundation.dart';
import 'package:spotifree/domain/repositories/i_get_liked_use_case.dart';
import 'package:spotifree/domain/repositories/i_likeable_entity.dart';
import 'package:spotifree/domain/repositories/i_toggle_like_use_case.dart';
import 'package:spotifree/providers/mode_provider.dart';

class LikedProvider<V extends ILikeableEntity> extends ChangeNotifier {
  final IGetLikedUseCase<V> getLikedUseCase;
  final IToggleLikeUseCase<V> toggleLikeUseCase;
  final ModeProvider modeProvider;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get items => _items;
  List<V> get objects => _items.map((item) => item['entity'] as V).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  LikedProvider({
    required this.getLikedUseCase,
    required this.toggleLikeUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    fetchLikedObjects(forceRefresh: true);
  }

  Future<void> fetchLikedObjects({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await getLikedUseCase.execute(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLiked(String objectId) => objects.any((obj) => obj.id == objectId);

  String? getFavoriteId(String objectId) {
    for (final item in _items) {
      final entity = item['entity'] as V;
      if (entity.id == objectId) return item['favoriteId'] as String?;
    }
    return null;
  }

  Future<void> toggleLike(V object) async {
    await toggleLikeUseCase.execute(object);
    await fetchLikedObjects(forceRefresh: true);
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}
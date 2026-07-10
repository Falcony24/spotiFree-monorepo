import 'package:spotifree/data/services/offline_storage.dart';
import 'package:spotifree/domain/repositories/i_favorites_repository.dart';
import 'package:spotifree/domain/repositories/i_toggle_like_use_case.dart';
import 'package:spotifree/domain/repositories/toggle_like_strategy.dart';
import 'package:spotifree/domain/repositories/i_likeable_entity.dart';
import 'package:spotifree/providers/mode_provider.dart';

class ToggleLikeUseCase<T extends ILikeableEntity> implements IToggleLikeUseCase<T> {
  final IFavoritesRepository repository;
  final ModeProvider modeProvider;
  final OfflineStorage storage;
  final ToggleLikeStrategy<T> strategy;

  ToggleLikeUseCase({
    required this.repository,
    required this.modeProvider,
    required this.strategy,
    OfflineStorage? storage,
  }) : storage = storage ?? OfflineStorage();

  @override
  Future<void> execute(T item) async {
    final id = _getId(item);
    final isCurrentlyLiked = await strategy.isLiked(id);

    if (isCurrentlyLiked) {
      await _handleUnlike(id);
    } else {
      await _handleLike(id, item);
    }
  }

  Future<void> _handleUnlike(String id) async {
    if (!modeProvider.isOfflineMode) {
      final favId = await strategy.getFavoriteId(id);
      if (favId != null) await strategy.unlike(favId);
    } else {
      await storage.addToSyncQueue(strategy.syncQueueType, 'remove', id);
    }
    await strategy.removeFromLocal(id);
    await strategy.additionalCleanup?.call(id);
  }

  Future<void> _handleLike(String id, T item) async {
    String newFavId;
    if (!modeProvider.isOfflineMode) {
      newFavId = await strategy.like(id);
    } else {
      newFavId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      await storage.addToSyncQueue(
        strategy.syncQueueType,
        'add',
        id,
        payload: strategy.getAddPayload?.call(item),
      );
    }
    await strategy.saveToLocal(newFavId, item);
  }

  String _getId(T item) => (item as dynamic).id as String;
}
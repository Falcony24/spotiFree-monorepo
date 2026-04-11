import 'package:frontend/domain/repositories/i_likeable_entity.dart';

typedef IsLikedCallback = Future<bool> Function(String id);
typedef GetFavoriteIdCallback = Future<String?> Function(String id);
typedef UnlikeCallback = Future<void> Function(String favId);
typedef LikeCallback = Future<String> Function(String id);
typedef SaveLocalCallback<T> = Future<void> Function(String favId, T item);
typedef RemoveLocalCallback = Future<void> Function(String id);
typedef AdditionalCleanupCallback = Future<void> Function(String id)?;
typedef GetAddPayloadCallback<T> = String? Function(T item)?;

class ToggleLikeStrategy<T extends ILikeableEntity> {
  final IsLikedCallback isLiked;
  final GetFavoriteIdCallback getFavoriteId;
  final UnlikeCallback unlike;
  final LikeCallback like;
  final SaveLocalCallback<T> saveToLocal;
  final RemoveLocalCallback removeFromLocal;
  final String syncQueueType;
  final GetAddPayloadCallback<T> getAddPayload;
  final AdditionalCleanupCallback additionalCleanup;

  ToggleLikeStrategy({
    required this.isLiked,
    required this.getFavoriteId,
    required this.unlike,
    required this.like,
    required this.saveToLocal,
    required this.removeFromLocal,
    required this.syncQueueType,
    this.getAddPayload,
    this.additionalCleanup,
  });
}
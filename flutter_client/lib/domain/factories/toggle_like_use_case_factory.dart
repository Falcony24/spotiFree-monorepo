import 'package:spotifree/data/services/offline_storage.dart';
import 'package:spotifree/domain/repositories/i_favorites_repository.dart';
import 'package:spotifree/domain/repositories/toggle_like_strategy.dart';
import 'package:spotifree/domain/usecases/toggle_like_use_case.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/domain/repositories/i_likeable_entity.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/mode_provider.dart';

class ToggleLikeUseCaseFactory {
  static ToggleLikeUseCase<T> create<T extends ILikeableEntity>({
    required IFavoritesRepository repository,
    required ModeProvider modeProvider,
    OfflineStorage? storage,
  }) {
    final s = storage ?? OfflineStorage();
    late ToggleLikeStrategy<T> strategy;

    if (T == Artist) {
      strategy = ToggleLikeStrategy<T>(
        isLiked: (id) => repository.isArtistLiked(id),
        getFavoriteId: (id) => repository.getFavoriteIdForArtist(id),
        unlike: (favId) => repository.unlikeArtist(favId),
        like: (id) => repository.likeArtist(id),
        saveToLocal: (favId, item) => s.addLikedArtist(favId, item as Artist),
        removeFromLocal: (id) => s.removeLikedArtist(id),
        syncQueueType: 'liked_artist',
      );
    } else if (T == Track) {
      strategy = ToggleLikeStrategy<T>(
        isLiked: (id) => repository.isTrackLiked(id),
        getFavoriteId: (id) => repository.getFavoriteIdForTrack(id),
        unlike: (favId) => repository.unlikeTrack(favId),
        like: (id) => repository.likeTrack(id),
        saveToLocal: (favId, item) => s.addLikedTrack(favId, item as Track),
        removeFromLocal: (id) => s.removeLikedTrack(id),
        syncQueueType: 'liked_track',
        getAddPayload: (item) => (item as Track).toJson().toString(),
      );
    } else if (T == Album) {
      strategy = ToggleLikeStrategy<T>(
        isLiked: (id) => repository.isAlbumLiked(id),
        getFavoriteId: (id) => repository.getFavoriteIdForAlbum(id),
        unlike: (favId) => repository.unlikeAlbum(favId),
        like: (id) => repository.likeAlbum(id),
        saveToLocal: (favId, item) => s.addLikedAlbum(favId, item as Album),
        removeFromLocal: (id) => s.removeLikedAlbum(id),
        syncQueueType: 'liked_album',
        getAddPayload: (item) => (item as Album).toJson().toString(),
        additionalCleanup: (id) => s.removeLikedAlbumTracks(id),
      );
    } else {
      throw ArgumentError('Unsupported type: $T');
    }

    return ToggleLikeUseCase<T>(
      repository: repository,
      modeProvider: modeProvider,
      strategy: strategy,
      storage: s,
    );
  }
}
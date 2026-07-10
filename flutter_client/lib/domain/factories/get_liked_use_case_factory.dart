import 'package:spotifree/utils/constants.dart';
import 'package:spotifree/domain/repositories/i_favorites_repository.dart';
import 'package:spotifree/domain/repositories/get_liked_strategy.dart';
import 'package:spotifree/domain/usecases/get_liked_use_case.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/domain/repositories/i_likeable_entity.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/mode_provider.dart';

class GetLikedUseCaseFactory {
  static GetLikedUseCase<T> create<T extends ILikeableEntity>({
    required IFavoritesRepository repository,
    required ModeProvider modeProvider,
  }) {
    if (T == Track) {
      return _createTrack(repository, modeProvider) as GetLikedUseCase<T>;
    } else if (T == Album) {
      return _createAlbum(repository, modeProvider) as GetLikedUseCase<T>;
    } else if (T == Artist) {
      return _createArtist(repository, modeProvider) as GetLikedUseCase<T>;
    } else {
      throw ArgumentError('Unsupported type $T for GetLikedUseCaseFactory');
    }
  }

  static GetLikedUseCase<Track> _createTrack(
    IFavoritesRepository repository,
    ModeProvider modeProvider,
  ) {
    final strategy = GetLikedStrategy<Track>(
      fetch: ({
        required DataSource source,
        bool forceRefresh = false,
      }) => repository.getLikedTracks(source: source, forceRefresh: forceRefresh),
    );
    return GetLikedUseCase<Track>(
      modeProvider: modeProvider,
      strategy: strategy,
    );
  }

  static GetLikedUseCase<Album> _createAlbum(
    IFavoritesRepository repository,
    ModeProvider modeProvider,
  ) {
    final strategy = GetLikedStrategy<Album>(
      fetch: ({
        required DataSource source,
        bool forceRefresh = false,
      }) => repository.getLikedAlbums(source: source, forceRefresh: forceRefresh)
    );
    return GetLikedUseCase<Album>(
      modeProvider: modeProvider,
      strategy: strategy,
    );
  }

  static GetLikedUseCase<Artist> _createArtist(
    IFavoritesRepository repository,
    ModeProvider modeProvider,
  ) {
    final strategy = GetLikedStrategy<Artist>(
      fetch: ({
        required DataSource source,
        bool forceRefresh = false,
      }) => repository.getLikedArtists(source: source, forceRefresh: forceRefresh),
    );
    return GetLikedUseCase<Artist>(
      modeProvider: modeProvider,
      strategy: strategy,
    );
  }
}
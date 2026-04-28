import 'package:frontend/utils/constants.dart';
import 'package:frontend/domain/repositories/i_favorites_repository.dart';
import 'package:frontend/domain/repositories/get_liked_strategy.dart';
import 'package:frontend/domain/usecases/get_liked_use_case.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/domain/repositories/i_likeable_entity.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/mode_provider.dart';

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
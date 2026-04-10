import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/providers/liked_tracks_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_storage.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/track.dart';

@GenerateMocks([ApiService, OfflineStorage, ModeProvider])
import 'liked_tracks_provider_test.mocks.dart';

void main() {
  late MockApiService mockApi;
  late MockOfflineStorage mockStorage;
  late MockModeProvider mockModeProvider;
  late LikedTracksProvider provider;

  setUp(() {
    mockApi = MockApiService();
    mockStorage = MockOfflineStorage();
    mockModeProvider = MockModeProvider();
    provider = LikedTracksProvider(
      api: mockApi,
      storage: mockStorage,
    );
    provider.setModeProvider(mockModeProvider);
  });

  group('fetchLikedTracks - online mode', () {
    test('should load from API and cache to storage', () async {
      when(mockModeProvider.isOfflineMode).thenReturn(false);
      final apiItems = [
        {'id': 'fav1', 'track': Track(id: 't1', title: 'Song1', artist: 'A1')},
        {'id': 'fav2', 'track': Track(id: 't2', title: 'Song2', artist: 'A2')}
      ];
      when(mockApi.getLikedTracks()).thenAnswer((_) async => apiItems);
      when(mockStorage.getLikedTracks()).thenAnswer((_) async => []);

      await provider.fetchLikedTracks();

      expect(provider.likedItems.length, 2);
      verify(mockStorage.addLikedTrack('fav1', any)).called(1);
      verify(mockStorage.addLikedTrack('fav2', any)).called(1);
    });

    test('should fallback to offline on API error', () async {
      when(mockModeProvider.isOfflineMode).thenReturn(false);
      when(mockApi.getLikedTracks()).thenThrow(Exception('Network error'));
      final offlineItems = [
        {'id': 'off1', 'track': Track(id: 't3', title: 'OfflineSong', artist: 'OfflineArtist')}
      ];
      when(mockStorage.getLikedTracks()).thenAnswer((_) async => offlineItems);

      await provider.fetchLikedTracks();

      expect(provider.likedItems.length, 1);
      expect(provider.error, isNotNull);
    });
  });

  group('toggleLike', () {
    test('should add like in online mode', () async {
      when(mockModeProvider.isOfflineMode).thenReturn(false);
      final track = Track(id: 't4', title: 'New', artist: 'NewArtist');
      when(mockApi.likeTrack('t4')).thenAnswer((_) async => {'id': 'fav_new'});
      when(mockStorage.isTrackLiked('t4')).thenAnswer((_) async => false);
      when(mockStorage.getLikedTracks()).thenAnswer((_) async => []);

      await provider.toggleLike(track);

      verify(mockApi.likeTrack('t4')).called(1);
      verify(mockStorage.addLikedTrack('fav_new', track)).called(1);
    });

    test('should remove like in online mode', () async {
      when(mockModeProvider.isOfflineMode).thenReturn(false);
      final track = Track(id: 't5', title: 'ToUnlike', artist: 'Artist');
      when(mockStorage.isTrackLiked('t5')).thenAnswer((_) async => true);
      when(mockStorage.getFavoriteIdForTrack('t5')).thenAnswer((_) async => 'fav_old');
      when(mockApi.unlikeTrack('fav_old')).thenAnswer((_) async => {});
      when(mockStorage.getLikedTracks()).thenAnswer((_) async => []); // po odświeżeniu pusta

      await provider.toggleLike(track);

      verify(mockApi.unlikeTrack('fav_old')).called(1);
      verify(mockStorage.removeLikedTrack('t5')).called(1);
    });
  });
}
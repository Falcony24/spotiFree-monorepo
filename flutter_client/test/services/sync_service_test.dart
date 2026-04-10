import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/services/sync_service.dart';
import 'package:frontend/services/offline_storage.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/track.dart';

@GenerateMocks([OfflineStorage, ApiService])
import 'sync_service_test.mocks.dart';

void main() {
  late MockOfflineStorage mockStorage;
  late MockApiService mockApi;
  late SyncService syncService;

  setUp(() {
    mockStorage = MockOfflineStorage();
    mockApi = MockApiService();
    syncService = SyncService(storage: mockStorage, api: mockApi);
  });

  group('_pushLocalChanges', () {
    test('should push liked_track add', () async {
      final pending = [
        {
          'id': 1,
          'entity_type': 'liked_track',
          'action': 'add',
          'entity_id': 'track1',
          'payload': '{"id":"track1","title":"Test","artist":"Test"}'
        }
      ];
      when(mockStorage.getPendingSyncItems()).thenAnswer((_) async => pending);
      when(mockApi.likeTrack('track1')).thenAnswer((_) async => {'id': 'fav_123'});
      when(mockStorage.removeSyncItem(1)).thenAnswer((_) async => {});

      await syncService.syncAll();

      verify(mockApi.likeTrack('track1')).called(1);
      verify(mockStorage.removeSyncItem(1)).called(1);
    });

    test('should push liked_track remove', () async {
      final pending = [
        {
          'id': 2,
          'entity_type': 'liked_track',
          'action': 'remove',
          'entity_id': 'track2',
          'payload': null
        }
      ];
      when(mockStorage.getPendingSyncItems()).thenAnswer((_) async => pending);
      when(mockStorage.getFavoriteIdForTrack('track2'))
          .thenAnswer((_) async => 'fav_456');
      when(mockApi.unlikeTrack('fav_456')).thenAnswer((_) async => {});
      when(mockStorage.removeSyncItem(2)).thenAnswer((_) async => {});

      await syncService.syncAll();

      verify(mockApi.unlikeTrack('fav_456')).called(1);
    });
  });
}
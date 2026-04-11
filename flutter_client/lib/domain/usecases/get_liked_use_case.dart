import 'package:frontend/constants.dart';
import 'package:frontend/domain/repositories/i_get_liked_use_case.dart';
import 'package:frontend/domain/repositories/get_liked_strategy.dart';
import 'package:frontend/domain/repositories/i_likeable_entity.dart';
import 'package:frontend/providers/mode_provider.dart';

class GetLikedUseCase<T extends ILikeableEntity> implements IGetLikedUseCase<T> {
  final ModeProvider modeProvider;
  final GetLikedStrategy<T> strategy;

  GetLikedUseCase({
    required this.modeProvider,
    required this.strategy,
  });

  @override
  Future<List<Map<String, dynamic>>> execute({bool forceRefresh = false}) async {
    final isOfflineMode = modeProvider.isOfflineMode;
    final source = isOfflineMode ? DataSource.local : DataSource.remote;

    try {
      final items = await strategy.fetch(
        source: source,
        forceRefresh: forceRefresh,
      );
      return items.map((item) => {
        'favoriteId': item['id'],
        'entity': item['entity'] as T,
      }).toList();
    } catch (e) {
      if (!isOfflineMode && source == DataSource.remote) {
        final items = await strategy.fetch(
          source: DataSource.local,
          forceRefresh: forceRefresh,
        );
        return items.map((item) => {
          'favoriteId': item['id'],
          'entity': item['entity'] as T,
        }).toList();
      }
      rethrow;
    }
  }
}
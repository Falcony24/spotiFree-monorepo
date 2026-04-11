import 'package:frontend/domain/repositories/i_likeable_entity.dart';

abstract class IGetLikedUseCase<V extends ILikeableEntity> {
  Future<List<Map<String, dynamic>>> execute({bool forceRefresh = false});
}
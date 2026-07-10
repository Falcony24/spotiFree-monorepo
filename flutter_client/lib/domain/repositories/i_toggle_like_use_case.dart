import 'package:spotifree/domain/repositories/i_likeable_entity.dart';

abstract class IToggleLikeUseCase<V extends ILikeableEntity> {
  Future<void> execute(V entity);
}
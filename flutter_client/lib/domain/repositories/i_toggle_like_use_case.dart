import 'package:frontend/models/i_likeable_entity.dart';

abstract class IToggleLikeUseCase<V extends ILikeableEntity> {
  Future<void> execute(V entity);
}
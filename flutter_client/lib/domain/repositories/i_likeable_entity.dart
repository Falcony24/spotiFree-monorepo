enum LikeType {
  track,
  album,
  artist;

  String get apiString => this == LikeType.track ? 'track' : (this == LikeType.album ? 'album' : 'artist');
  String get syncQueueEntityType => 'liked_$apiString';
}

abstract class ILikeableEntity {
  String get id;
  Map<String, dynamic> toJson(); 
}

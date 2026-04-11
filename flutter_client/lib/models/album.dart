import 'package:frontend/domain/repositories/i_likeable_entity.dart';

class Album implements ILikeableEntity {
  @override
  final String id;      //MBID
  final String title;
  final String? artist;
  final String? coverUrl; 

  Album({
    required this.id,
    required this.title,
    this.artist,
    this.coverUrl,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? json['mbid'] ?? '',
      title: json['title'] ?? 'Nieznany tytuł',
      artist: json['artist'] ?? json['artist_name'],
      coverUrl: json['cover_url'],
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'cover_url': coverUrl,
    };
  }
}
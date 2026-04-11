import 'package:frontend/domain/repositories/i_likeable_entity.dart';

class Artist implements ILikeableEntity {
  @override
  final String id;       //MBID
  final String name;
  final String? sortName;

  Artist({
    required this.id, 
    required this.name, 
    this.sortName
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Nieznany artysta',
      sortName: json['sort_name'],
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sort_name': sortName,
    };
  }
}
class Playlist {
  final String id;     //GUID
  final String name;
  final String? description;
  final bool isPublic;
  final int userId;
  final String? ownerName; 

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.isPublic,
    required this.userId,
    this.ownerName,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'].toString(),   
      name: json['name'],
      description: json['description'],
      isPublic: json['is_public'],
      userId: json['user_id'],
      ownerName: json['owner_name'],
    );
  }
}
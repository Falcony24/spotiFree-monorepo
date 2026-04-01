class Artist {
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
}
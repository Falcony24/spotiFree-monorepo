class Track {
  final String id;  //MBID
  final String title;
  final String artist;
  final int? duration;
  final String? artistId; //MBID of the main artist

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.duration,
    this.artistId,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: (json['id'] ?? json['mbid'] ?? '').toString(),
      title: (json['title'] ?? 'Nieznany tytuł').toString(),
      artist: (json['artist'] ?? '').toString(),
      duration: json['duration'],
      artistId: (json['artist_id'] ?? json['artistId'])?.toString(),
    );
  }
}
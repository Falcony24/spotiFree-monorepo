import 'package:frontend/constants.dart';

class GetLikedStrategy<T> {
  final Future<List<Map<String, dynamic>>> Function({
    required DataSource source,
    bool forceRefresh,
  }) fetch;


  GetLikedStrategy({
    required this.fetch,
  });
}
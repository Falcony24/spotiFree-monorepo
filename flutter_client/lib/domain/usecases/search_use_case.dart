import 'package:frontend/data/services/search_service.dart';

class SearchUseCase {
  final SearchService searchService;

  SearchUseCase({required this.searchService});

  Future<Map<String, dynamic>> execute(String query, {String? type, int limit = 20, int offset = 0}) async {
    return await searchService.search(query, type: type, limit: limit, offset: offset);
  }
}
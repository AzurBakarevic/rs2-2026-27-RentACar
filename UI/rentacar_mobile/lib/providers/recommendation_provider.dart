import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recommendation.dart';
import 'base_provider.dart';

class RecommendationProvider extends BaseProvider<Recommendation> {
  RecommendationProvider() : super('Recommendations');

  @override
  Recommendation fromJson(data) {
    return Recommendation.fromJson(data);
  }

  Future<List<Recommendation>> getRecommendations() async {
    final uri = BaseProvider.buildUri(endpoint);
    final response = await BaseProvider.send(() => http.get(uri, headers: BaseProvider.createHeaders()));
    return List<Recommendation>.from((jsonDecode(response.body) as List).map(fromJson));
  }
}

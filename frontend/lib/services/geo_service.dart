import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchResult {
  final String speciesName;
  final double latitude;
  final double longitude;
  final String? description;

  SearchResult({
    required this.speciesName,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      speciesName: json['speciesName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}

class GeoService {
  static const String _baseUrl = 'http://localhost:8080/gateway';

  static Future<List<SearchResult>> search(String query) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {'q': query});
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> creategitSighting(
    double latitude,
    double longitude,
    String speciesName,
    String? description,
  ) async {
    final uri = Uri.parse('$_baseUrl/sightings');
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'speciesName': speciesName,
      if (description != null) 'description': description,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Create sighting failed: ${response.statusCode}');
    }
  }
}
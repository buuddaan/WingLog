import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart'; // För JWT-headern /EF

// Modell som speglar backend SightingResponse /EF
class Sighting {
  final String id;
  final String userId;
  final String speciesName;
  final double latitude;
  final double longitude;
  final String? description;
  final DateTime createdAt;
  final bool isPublic;

  Sighting({
    required this.id,
    required this.userId,
    required this.speciesName,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.createdAt,
    required this.isPublic,
  });

  factory Sighting.fromJson(Map<String, dynamic> json) {
    return Sighting(
      id: json['id'] as String,
      userId: json['userId'] as String,
      speciesName: json['speciesName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isPublic: (json['public'] ?? json['isPublic']) as bool? ?? true,
    );
  }
}

class GeoService {
  static const String _baseUrl = 'http://localhost:8080/gateway';

  // Bygger headers med JWT-token för autentiserade anrop /EF
  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Inte inloggad — ingen token tillgänglig');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Hämtar alla sparade observationer — visas som pins på kartan vid start
  static Future<List<Sighting>> getSightings() async {
    final uri = Uri.parse('$_baseUrl/sightings');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      throw Exception('Get sightings failed: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Sighting.fromJson(item as Map<String, dynamic>)).toList();
  }

  // Hämtar alla pins för en specifik fågelart /EF
  static Future<List<Sighting>> searchBySpecies(String speciesName) async {
    final uri = Uri.parse('$_baseUrl/sightings').replace(
      queryParameters: {'species': speciesName},
    );
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Sighting.fromJson(item as Map<String, dynamic>)).toList();
  }

  // Tar bort en observation via DELETE /sightings/{id}
  static Future<void> deleteSighting(String id) async {
    final uri = Uri.parse('$_baseUrl/sightings/$id');
    final response = await http.delete(uri, headers: await _authHeaders());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Delete sighting failed: ${response.statusCode}');
    }
  }

  // Skapar en ny sighting och returnerar den skapade pinnen /EF
  static Future<Sighting> createSighting({
    required double latitude,
    required double longitude,
    required String speciesName,
    String? description,
    bool isPublic = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/sightings');
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'speciesName': speciesName,
      'description': description,
      'isPublic': isPublic,
    };

    final response = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Create sighting failed: ${response.statusCode}');
    }

    return Sighting.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

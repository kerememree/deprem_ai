import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../core/exceptions/app_exceptions.dart';

/// Deprem verisi modeli
class DepremVerisi {
  final double lat;
  final double lng;
  final double magnitude; // Büyüklük
  final double depth; // Derinlik (km)
  final DateTime date;
  final String location; // Yer
  final String? id;

  DepremVerisi({
    required this.lat,
    required this.lng,
    required this.magnitude,
    required this.depth,
    required this.date,
    required this.location,
    this.id,
  });

  factory DepremVerisi.fromJson(Map<String, dynamic> json) {
    return DepremVerisi(
      lat: (json['lat'] ?? json['latitude'] ?? 0.0) as double,
      lng: (json['lng'] ?? json['longitude'] ?? json['lon'] ?? 0.0) as double,
      magnitude: (json['magnitude'] ?? json['mag'] ?? 0.0) as double,
      depth: (json['depth'] ?? 0.0) as double,
      date: DateTime.parse(json['date'] ?? json['time'] ?? DateTime.now().toIso8601String()),
      location: (json['location'] ?? json['place'] ?? json['title'] ?? 'Bilinmeyen') as String,
      id: json['id']?.toString(),
    );
  }
}

/// Deprem API servisi - Gerçek zamanlı deprem verileri
class DepremApiService {
  // Ücretsiz deprem API'leri
  // 1. USGS (Global, Türkiye dahil)
  static const String _usgsApiUrl = 'https://earthquake.usgs.gov/fdsnws/event/1/query';
  
  // 2. EMSC (European-Mediterranean Seismological Centre) - Türkiye'ye yakın
  static const String _emscApiUrl = 'https://www.seismicportal.eu/fdsnws/event/1/query';

  /// Son 24 saatteki depremleri getir (Türkiye ve çevresi)
  static Future<List<DepremVerisi>> getSon24SaatDepremler() async {
    try {
      // Türkiye sınırları (kabaca)
      // Latitude: 35.8 - 42.1
      // Longitude: 25.7 - 44.8
      final minLat = 35.8;
      final maxLat = 42.1;
      final minLng = 25.7;
      final maxLng = 44.8;
      
      // USGS API'den son 24 saatteki depremleri al
      final uri = Uri.parse(_usgsApiUrl).replace(queryParameters: {
        'format': 'geojson',
        'starttime': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'minlatitude': minLat.toString(),
        'maxlatitude': maxLat.toString(),
        'minlongitude': minLng.toString(),
        'maxlongitude': maxLng.toString(),
        'minmagnitude': '2.0', // 2.0 ve üzeri büyüklükteki depremler
        'orderby': 'time', // Zaman sırasına göre
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw NetworkException(
            'API isteği zaman aşımına uğradı',
            code: 'TIMEOUT',
          );
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Deprem verileri alınamadı: HTTP ${response.statusCode}',
          code: 'API_ERROR',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final features = jsonData['features'] as List<dynamic>?;

      if (features == null) {
        return [];
      }

      final List<DepremVerisi> depremler = [];

      for (final feature in features) {
        try {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final deprem = DepremVerisi(
            lat: (coordinates[1] as num).toDouble(),
            lng: (coordinates[0] as num).toDouble(),
            magnitude: (properties['mag'] as num?)?.toDouble() ?? 0.0,
            depth: (coordinates[2] as num?)?.toDouble() ?? 0.0,
            date: DateTime.fromMillisecondsSinceEpoch(
              (properties['time'] as int) ?? DateTime.now().millisecondsSinceEpoch,
            ),
            location: (properties['place'] ?? properties['title'] ?? 'Bilinmeyen') as String,
            id: feature['id']?.toString(),
          );

          depremler.add(deprem);
        } catch (e) {
          // Bozuk veriyi atla
          debugPrint('UYARI: Deprem verisi parse edilemedi: $e');
        }
      }

      // Büyüklüğe göre sırala (büyükten küçüğe)
      depremler.sort((a, b) => b.magnitude.compareTo(a.magnitude));

      return depremler;
    } on NetworkException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Deprem verileri alınırken hata oluştu: ${e.toString()}',
        code: 'API_ERROR',
        originalError: e,
      );
    }
  }

  /// Son 7 gündeki depremleri getir
  static Future<List<DepremVerisi>> getSon7GunDepremler() async {
    try {
      final minLat = 35.8;
      final maxLat = 42.1;
      final minLng = 25.7;
      final maxLng = 44.8;

      final uri = Uri.parse(_usgsApiUrl).replace(queryParameters: {
        'format': 'geojson',
        'starttime': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'minlatitude': minLat.toString(),
        'maxlatitude': maxLat.toString(),
        'minlongitude': minLng.toString(),
        'maxlongitude': maxLng.toString(),
        'minmagnitude': '2.0',
        'orderby': 'time',
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw NetworkException(
            'API isteği zaman aşımına uğradı',
            code: 'TIMEOUT',
          );
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Deprem verileri alınamadı: HTTP ${response.statusCode}',
          code: 'API_ERROR',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final features = jsonData['features'] as List<dynamic>?;

      if (features == null) {
        return [];
      }

      final List<DepremVerisi> depremler = [];

      for (final feature in features) {
        try {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final deprem = DepremVerisi(
            lat: (coordinates[1] as num).toDouble(),
            lng: (coordinates[0] as num).toDouble(),
            magnitude: (properties['mag'] as num?)?.toDouble() ?? 0.0,
            depth: (coordinates[2] as num?)?.toDouble() ?? 0.0,
            date: DateTime.fromMillisecondsSinceEpoch(
              (properties['time'] as int) ?? DateTime.now().millisecondsSinceEpoch,
            ),
            location: (properties['place'] ?? properties['title'] ?? 'Bilinmeyen') as String,
            id: feature['id']?.toString(),
          );

          depremler.add(deprem);
        } catch (e) {
          debugPrint('UYARI: Deprem verisi parse edilemedi: $e');
        }
      }

      depremler.sort((a, b) => b.magnitude.compareTo(a.magnitude));
      return depremler;
    } catch (e) {
      if (e is NetworkException || e is ApiException) rethrow;
      throw ApiException(
        'Deprem verileri alınırken hata oluştu: ${e.toString()}',
        code: 'API_ERROR',
        originalError: e,
      );
    }
  }

  /// Minimum büyüklük filtresi ile depremleri getir
  static Future<List<DepremVerisi>> getDepremler({
    required DateTime startTime,
    double minMagnitude = 2.0,
  }) async {
    try {
      final minLat = 35.8;
      final maxLat = 42.1;
      final minLng = 25.7;
      final maxLng = 44.8;

      final uri = Uri.parse(_usgsApiUrl).replace(queryParameters: {
        'format': 'geojson',
        'starttime': startTime.toIso8601String(),
        'minlatitude': minLat.toString(),
        'maxlatitude': maxLat.toString(),
        'minlongitude': minLng.toString(),
        'maxlongitude': maxLng.toString(),
        'minmagnitude': minMagnitude.toString(),
        'orderby': 'time',
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw NetworkException(
            'API isteği zaman aşımına uğradı',
            code: 'TIMEOUT',
          );
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Deprem verileri alınamadı: HTTP ${response.statusCode}',
          code: 'API_ERROR',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final features = jsonData['features'] as List<dynamic>?;

      if (features == null) {
        return [];
      }

      final List<DepremVerisi> depremler = [];

      for (final feature in features) {
        try {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final deprem = DepremVerisi(
            lat: (coordinates[1] as num).toDouble(),
            lng: (coordinates[0] as num).toDouble(),
            magnitude: (properties['mag'] as num?)?.toDouble() ?? 0.0,
            depth: (coordinates[2] as num?)?.toDouble() ?? 0.0,
            date: DateTime.fromMillisecondsSinceEpoch(
              (properties['time'] as int) ?? DateTime.now().millisecondsSinceEpoch,
            ),
            location: (properties['place'] ?? properties['title'] ?? 'Bilinmeyen') as String,
            id: feature['id']?.toString(),
          );

          depremler.add(deprem);
        } catch (e) {
          debugPrint('UYARI: Deprem verisi parse edilemedi: $e');
        }
      }

      depremler.sort((a, b) => b.magnitude.compareTo(a.magnitude));
      return depremler;
    } catch (e) {
      if (e is NetworkException || e is ApiException) rethrow;
      throw ApiException(
        'Deprem verileri alınırken hata oluştu: ${e.toString()}',
        code: 'API_ERROR',
        originalError: e,
      );
    }
  }
}





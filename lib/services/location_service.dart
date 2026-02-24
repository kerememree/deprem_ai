import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/exceptions/app_exceptions.dart';

/// Konum servisi - Kullanıcı konumu ve adres bilgileri
class LocationService {
  /// Konum izinlerini kontrol et ve iste
  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw NetworkException(
        'Konum servisleri kapalı. Lütfen konum servislerini açın.',
        code: 'LOCATION_DISABLED',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw NetworkException(
          'Konum izni reddedildi. Uygulamayı kullanmak için konum izni gereklidir.',
          code: 'PERMISSION_DENIED',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw NetworkException(
        'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
        code: 'PERMISSION_DENIED_FOREVER',
      );
    }

    return true;
  }

  /// Kullanıcının mevcut konumunu al
  static Future<Position> getCurrentLocation() async {
    try {
      await checkAndRequestPermission();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Konum alınamadı: ${e.toString()}',
        code: 'LOCATION_ERROR',
        originalError: e,
      );
    }
  }

  /// Koordinatlardan adres bilgisi al (reverse geocoding)
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Bilinmeyen konum';
      }

      Placemark place = placemarks[0];
      
      // Türkçe format: Şehir, İlçe
      String address = '';
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        address = place.administrativeArea!;
      }
      if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.subAdministrativeArea!;
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.locality!;
      }

      return address.isNotEmpty ? address : 'Bilinmeyen konum';
    } catch (e) {
      return 'Konum bilgisi alınamadı';
    }
  }

  /// İki konum arasındaki mesafeyi hesapla (km)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km cinsinden
  }

  /// En yakın konumu bul
  static Map<String, dynamic> findNearestLocation(
    double userLat,
    double userLon,
    List<Map<String, dynamic>> locations,
  ) {
    if (locations.isEmpty) {
      throw Exception('Konum listesi boş');
    }

    double minDistance = double.infinity;
    Map<String, dynamic>? nearest;

    for (final location in locations) {
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;
      final distance = calculateDistance(userLat, userLon, lat, lng);

      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
        nearest!['distance'] = distance;
      }
    }

    return nearest!;
  }
}


import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/exceptions/app_exceptions.dart';

/// İnternet bağlantısı kontrol servisi
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isConnected = true; // Varsayılan olarak bağlı kabul et

  /// İnternet bağlantısını kontrol et
  static Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result.any((r) => 
        r == ConnectivityResult.mobile || 
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet
      );
      return _isConnected;
    } catch (e) {
      // DÜZELTME: Hata durumunda mevcut durumu koru (değiştirme)
      debugPrint('Connectivity kontrolü hatası: $e');
      // Varsayılan durumu değil, mevcut _isConnected değerini döndür
      return _isConnected;
    }
  }

  /// Gerçek internet bağlantısını kontrol et (yalnızca WiFi/Mobil kontrolü yeterli değil)
  /// Bağlantı var ama gerçekten internete erişim var mı?
  static Future<bool> checkInternetAccess() async {
    try {
      // Basit bir kontrol - DNS lookup veya HTTP request
      // Bu daha detaylı bir kontrol için kullanılabilir
      final hasConnection = await checkConnection();
      if (!hasConnection) return false;

      // Gerçek internet erişimi için ekstra kontrol yapılabilir
      // Şimdilik connectivity sonucuna güveniyoruz
      return true;
    } catch (e) {
      debugPrint('Internet erişim kontrolü hatası: $e');
      return false;
    }
  }

  /// Bağlantı durumu değişikliklerini dinle
  static StreamSubscription<List<ConnectivityResult>> listenToChanges(
    Function(bool isConnected) onConnectionChanged,
  ) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => 
        r == ConnectivityResult.mobile || 
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet
      );
      _isConnected = isConnected;
      onConnectionChanged(isConnected);
    });
    return _subscription!;
  }

  /// Dinlemeyi durdur
  static void cancelListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Mevcut bağlantı durumu (cache'lenmiş)
  static bool get isConnected => _isConnected;

  /// Analiz yapılabilir mi? (Bağlantı kontrolü)
  static Future<void> ensureConnectionForAnalysis() async {
    final hasConnection = await checkConnection();
    if (!hasConnection) {
      throw NetworkException(
        'İnternet bağlantısı yok. Analiz yapmak için internete bağlanmanız gerekiyor.',
        code: 'NO_CONNECTION',
      );
    }
  }
}





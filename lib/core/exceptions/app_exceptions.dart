/// Uygulama genelinde kullanılan özel exception sınıfları
/// 
/// Bu sınıflar hata yönetimini merkezi ve tutarlı hale getirir.

/// Base exception sınıfı - tüm özel exception'lar bundan türetilir
abstract class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    required this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Kullanıcı dostu hata mesajı (UI'da gösterilecek)
  String get userMessage => message;

  @override
  String toString() => '[$code] $message';
}

/// API ile ilgili hatalar (API key, quota, vb.)
class ApiException extends AppException {
  const ApiException(
    super.message, {
    required super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    switch (code) {
      case 'QUOTA_EXCEEDED':
        return 'API kotası aşıldı. Lütfen Google AI Studio\'dan API key limitinizi kontrol edin veya daha sonra tekrar deneyin. Alternatif olarak, uygulama şu anda daha yüksek kota limitine sahip bir model kullanıyor.';
      case 'INVALID_API_KEY':
        return 'API key geçersiz veya bulunamadı. Lütfen .env dosyasını kontrol edin.';
      default:
        return message;
    }
  }
}

/// Network/İnternet bağlantı hataları
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    required super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
}

/// Dosya işlemleri ile ilgili hatalar
class FileException extends AppException {
  const FileException(
    super.message, {
    required super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (code == 'PDF_READ_ERROR') {
      return 'PDF dosyası okunamadı. Lütfen dosyanın geçerli olduğundan emin olun.';
    } else if (code == 'IMAGE_READ_ERROR') {
      return 'Fotoğraf okunamadı. Lütfen geçerli bir fotoğraf seçin.';
    }
    return 'Dosya işleme hatası: $message';
  }
}

/// JSON parsing/veri işleme hataları
class DataException extends AppException {
  const DataException(
    super.message, {
    required super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Veri işleme hatası: $message';
}

/// JSON parse hataları için (DataException alias)
class JsonParseException extends DataException {
  const JsonParseException(
    super.message, {
    required super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Analiz sonucu işlenirken hata oluştu. Lütfen tekrar deneyin.';
}

/// Kimlik doğrulama hataları
class AuthException extends AppException {
  const AuthException(
    super.message, {
    required super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => message;
}


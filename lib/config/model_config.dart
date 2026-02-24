/// Model Yapılandırması
/// 
/// Kullanılabilir ve Aktif Modeller:
/// - gemini-2.0-flash          ✅ GA, stabil, ücretsiz tier var
/// - gemini-2.5-flash-preview  ✅ En güçlü flash, düşünme yeteneği var
/// - gemini-2.0-flash-lite     ✅ En hızlı ve ucuz
/// - gemini-3-flash-preview    ✅ En yeni Gemini 3 preview
class ModelConfig {
  // ✅ Aktif model — gemini-3-flash-preview
  static const String MODEL_ADI = 'gemini-3-flash-preview';

  // Alternatifler:
  // static const String MODEL_ADI = 'gemini-2.5-flash-preview-05-20'; // Çok güçlü
  // static const String MODEL_ADI = 'gemini-2.0-flash';               // Stabil GA
  // static const String MODEL_ADI = 'gemini-2.0-flash-lite';          // En hızlı/ucuz

  /// Model açıklaması (debug için)
  static String get modelAciklama {
    if (MODEL_ADI.contains('3-flash')) {
      return 'Gemini 3 Flash Preview (En Yeni)';
    } else if (MODEL_ADI.contains('2.5')) {
      return 'Gemini 2.5 Flash (En Güçlü)';
    } else if (MODEL_ADI.contains('2.0-flash-lite')) {
      return 'Gemini 2.0 Flash-Lite (En Hızlı)';
    } else if (MODEL_ADI.contains('2.0-flash')) {
      return 'Gemini 2.0 Flash (Stabil, GA)';
    }
    return 'Model: $MODEL_ADI';
  }

  /// Tüm Gemini 2.0+ modelleri PDF ve görsel destekler
  static bool get pdfDestegiVar => true;
}

import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/analiz_kaydi.dart';
import '../core/exceptions/app_exceptions.dart';

/// Analiz geçmişi servisi — her kullanıcı kendi Hive box'ında saklanır
class AnalizGecmisiService {
  static const String _boxPrefix = 'analiz_';
  static bool _hiveInitialized = false;
  static final Map<String, Box> _openBoxes = {};

  // ── Hive Başlatma (sadece initFlutter; box'lar lazy açılır) ─────────────────

  static Future<void> init() async {
    if (_hiveInitialized) return;
    try {
      await Hive.initFlutter();
      _hiveInitialized = true;
    } catch (e) {
      throw DataException(
        'Analiz geçmişi başlatılamadı: $e',
        code: 'DATABASE_INIT_ERROR',
        originalError: e,
      );
    }
  }

  // ── Kullanıcıya özel yardımcılar ─────────────────────────────────────────────

  /// Mevcut kullanıcının UID'sine göre box adı döndür
  static String _getUserBoxName() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    return '$_boxPrefix$uid';
  }

  /// Kullanıcıya özel box'ı lazy aç ve döndür
  static Future<Box> _getBox() async {
    if (!_hiveInitialized) await init();
    final boxName = _getUserBoxName();
    if (!_openBoxes.containsKey(boxName) || !(_openBoxes[boxName]?.isOpen ?? false)) {
      _openBoxes[boxName] = await Hive.openBox(boxName);
    }
    return _openBoxes[boxName]!;
  }

  /// Kullanıcıya özel dosya dizini
  static Future<String> _getUserDirPath(String analizId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'default';
    return '${appDir.path}/analizler/$uid/$analizId';
  }

  // ── CRUD Operasyonları ────────────────────────────────────────────────────────

  /// Tüm analizleri getir (tarih sırasına göre — yeni en üstte)
  static Future<List<AnalizKaydi>> tumAnalizleriGetir() async {
    try {
      final box = await _getBox();
      final List<AnalizKaydi> analizler = [];

      for (var key in box.keys) {
        try {
          final jsonString = box.get(key) as String?;
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            analizler.add(AnalizKaydi.fromJson(json));
          }
        } catch (e) {
          debugPrint('UYARI: Analiz kaydı okunamadı (key: $key): $e');
        }
      }

      analizler.sort((a, b) => b.tarih.compareTo(a.tarih));
      return analizler;
    } catch (e) {
      throw DataException(
        'Analizler yüklenirken hata oluştu: $e',
        code: 'LOAD_ERROR',
        originalError: e,
      );
    }
  }

  /// Belirli bir analizi getir
  static Future<AnalizKaydi?> analizGetir(String id) async {
    try {
      final box = await _getBox();
      final jsonString = box.get(id) as String?;
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AnalizKaydi.fromJson(json);
    } catch (e) {
      throw DataException(
        'Analiz yüklenirken hata oluştu: $e',
        code: 'LOAD_ERROR',
        originalError: e,
      );
    }
  }

  /// Yeni analiz kaydet
  static Future<String> analizKaydet(AnalizKaydi kayit) async {
    try {
      final box = await _getBox();
      final json = jsonEncode(kayit.toJson());
      await box.put(kayit.id, json);
      return kayit.id;
    } catch (e) {
      throw DataException(
        'Analiz kaydedilirken hata oluştu: $e',
        code: 'SAVE_ERROR',
        originalError: e,
      );
    }
  }

  /// Analiz sil (dosyalarıyla birlikte)
  static Future<void> analizSil(String id) async {
    try {
      final box = await _getBox();

      final kayit = await analizGetir(id);
      if (kayit != null) {
        // Fotoğrafları sil
        if (kayit.fotografPathleri != null) {
          for (var path in kayit.fotografPathleri!) {
            try {
              final file = File(path);
              if (file.existsSync()) await file.delete();
            } catch (e) {
              debugPrint('UYARI: Fotoğraf silinemedi ($path): $e');
            }
          }
        }
        // PDF'i sil
        if (kayit.pdfPath != null) {
          try {
            final file = File(kayit.pdfPath!);
            if (file.existsSync()) await file.delete();
          } catch (e) {
            debugPrint('UYARI: PDF silinemedi (${kayit.pdfPath}): $e');
          }
        }
      }

      await box.delete(id);
    } catch (e) {
      throw DataException(
        'Analiz silinirken hata oluştu: $e',
        code: 'DELETE_ERROR',
        originalError: e,
      );
    }
  }

  // ── Dosya Operasyonları ───────────────────────────────────────────────────────

  /// Fotoğrafları kullanıcıya özel dizine kaydet
  static Future<List<String>> fotografKaydet(
      List<File> fotografDosyalari, String analizId) async {
    try {
      final dirPath = await _getUserDirPath(analizId);
      final analizDir = Directory(dirPath);
      if (!analizDir.existsSync()) {
        await analizDir.create(recursive: true);
      }

      final List<String> kaydedilenPathler = [];
      for (int i = 0; i < fotografDosyalari.length; i++) {
        final yeniPath = '${analizDir.path}/foto_$i.jpg';
        await fotografDosyalari[i].copy(yeniPath);
        kaydedilenPathler.add(yeniPath);
      }
      return kaydedilenPathler;
    } catch (e) {
      throw FileException(
        'Fotoğraflar kaydedilirken hata oluştu: $e',
        code: 'PHOTO_SAVE_ERROR',
        originalError: e,
      );
    }
  }

  /// PDF'i kullanıcıya özel dizine kaydet
  static Future<String?> pdfKaydet(File pdfDosya, String analizId) async {
    try {
      final dirPath = await _getUserDirPath(analizId);
      final analizDir = Directory(dirPath);
      if (!analizDir.existsSync()) {
        await analizDir.create(recursive: true);
      }
      final yeniPath = '${analizDir.path}/belge.pdf';
      await pdfDosya.copy(yeniPath);
      return yeniPath;
    } catch (e) {
      throw FileException(
        'PDF kaydedilirken hata oluştu: $e',
        code: 'PDF_SAVE_ERROR',
        originalError: e,
      );
    }
  }

  // ── Özet & Temizlik ───────────────────────────────────────────────────────────

  /// Mevcut kullanıcının toplam analiz sayısı
  static Future<int> toplamAnalizSayisi() async {
    try {
      final box = await _getBox();
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Mevcut kullanıcının tüm geçmişini temizle
  static Future<void> tumGecmisiTemizle() async {
    try {
      final analizler = await tumAnalizleriGetir();
      for (var analiz in analizler) {
        await analizSil(analiz.id);
      }
    } catch (e) {
      throw DataException(
        'Geçmiş temizlenirken hata oluştu: $e',
        code: 'CLEAR_ERROR',
        originalError: e,
      );
    }
  }
}

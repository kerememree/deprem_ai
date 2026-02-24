import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:ui' show PlatformDispatcher;
import 'services/gemini_service.dart';
import 'services/auth_service.dart';
import 'models/risk_analizi.dart';
import 'core/exceptions/app_exceptions.dart';
import 'widgets/risk_karti.dart';
import 'widgets/fotograf_listesi.dart';
import 'widgets/loading_overlay.dart';
import 'services/pdf_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/deprem_bilgilendirme_screen.dart';
import 'screens/deprem_haritasi_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/analiz_gecmisi_screen.dart';
import 'services/analiz_gecmisi_service.dart';
import 'services/connectivity_service.dart';
import 'services/tracking_service.dart';
import 'services/notification_service.dart';
import 'models/analiz_kaydi.dart';
import 'l10n/app_strings.dart';
import 'screens/bildirim_ayarlari_screen.dart';
import 'widgets/fotograf_rehberi.dart';
import 'services/demo_service.dart';

// ─── Global Tema Yönetimi (ValueNotifier — Riverpod'suz) ──────────────────────
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

Future<void> _loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('theme_mode') ?? 'system';
  themeModeNotifier.value = switch (saved) {
    'light' => ThemeMode.light,
    'dark'  => ThemeMode.dark,
    _       => ThemeMode.system,
  };
}

Future<void> _saveTheme(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', switch (mode) {
    ThemeMode.light  => 'light',
    ThemeMode.dark   => 'dark',
    ThemeMode.system => 'system',
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kaydedilmiş tema ve dil tercihini yükle
  await _loadSavedTheme();
  await loadSavedLanguage();
  
  // Firebase'i başlat
  try {
    await Firebase.initializeApp();

    // ── Crashlytics ────────────────────────────────────────────────────────
    // Debug modunda Crashlytics'i devre dışı bırak (sadece production'da aktif)
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Flutter framework hatalarını Crashlytics'e ilet
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Dart async hatalarını Crashlytics'e ilet
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // ── Analytics ──────────────────────────────────────────────────────────
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('Firebase Analytics & Crashlytics başlatıldı.');
  } catch (e) {
    debugPrint('UYARI: Firebase başlatılamadı! Authentication çalışmayabilir.');
    debugPrint('Lütfen FIREBASE_KURULUM_REHBERI.md dosyasındaki adımları takip edin.');
    debugPrint('Hata detayı: $e');
  }
  
  // .env dosyasını yükle (güvenlik için API key'i buradan okuyoruz)
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    // .env dosyası yoksa uyarı ver ama devam et (production'da hata fırlatılacak)
    debugPrint('UYARI: .env dosyası bulunamadı! API key yüklenemedi.');
    debugPrint('Lütfen assets/.env dosyasını oluşturup GEMINI_API_KEY değerini ekleyin.');
    debugPrint('Hata detayı: $e');
  }
  
  // Hive database'i başlat (analiz geçmişi için)
  try {
    await AnalizGecmisiService.init();
  } catch (e) {
    debugPrint('UYARI: Analiz geçmişi servisi başlatılamadı: $e');
  }
  
  // Notification servisini başlat (periyodik takip için)
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('UYARI: Bildirim servisi başlatılamadı: $e');
  }
  
  // Mevcut analizler için hatırlatmaları zamanla
  try {
    await TrackingService.scheduleAllReminders();
  } catch (e) {
    debugPrint('UYARI: Hatırlatmalar zamanlanamadı: $e');
  }
  
  runApp(const MimarAIApp());
}

class MimarAIApp extends StatelessWidget {
  const MimarAIApp({super.key});

  // Analytics navigasyon gözlemcisi
  static final FirebaseAnalyticsObserver _analyticsObserver =
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Mimar-AI',
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          themeMode: themeMode,
          // ── Aydınlık tema ───────────────────────────────────────────────
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          // ── Karanlık tema ───────────────────────────────────────────────
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          navigatorObservers: [_analyticsObserver],
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/email-login': (context) => const EmailLoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/verify-email': (context) => const EmailVerificationScreen(),
            '/home': (context) => const MimarAIHome(),
            '/bilgilendirme': (context) => const DepremBilgilendirmeScreen(),
            '/harita': (context) => const DepremHaritasiScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/gecmis': (context) => const AnalizGecmisiScreen(),
            '/bildirimler': (context) => const BildirimAyarlariScreen(),
          },
        );
      },
    );
  }
}

/// Authentication kontrolü yapan wrapper
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  static Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboarding(),
      builder: (context, onboardingSnapshot) {
        if (!onboardingSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Onboarding henüz tamamlanmadıysa göster
        if (!onboardingSnapshot.data!) {
          return const OnboardingScreen();
        }

        // Firebase auth state'ini stream ile takip et.
        // Bu sayede currentUser her zaman gerçek Firebase oturumunu yansıtır
        // ve farklı kullanıcılar arasında analiz geçmişi karışmaz.
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = authSnapshot.data;
            if (user != null) {
              return const MimarAIHome();
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}

class MimarAIHome extends StatefulWidget {
  const MimarAIHome({super.key});

  @override
  State<MimarAIHome> createState() => _MimarAIHomeState();
}

class _MimarAIHomeState extends State<MimarAIHome> {
  final GeminiService _gemini = GeminiService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _binaAdiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? _pdfDosya;
  List<File> _fotograflar = [];
  RiskAnalizi? _analizSonucu;
  bool _yukleniyor = false;
  bool _pdfYukleniyor = false;  // PDF export loading state
  int _analizAdimi = 0;        // Aktif analiz adımı (0: dosyalar, 1: AI, 2: kayıt)
  bool _analizIptalEdildi = false; // Kullanıcı iptali bayrağı
  String? _hataMesaji;
  bool _internetVar = true; // Bağlantı durumu
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Alt navigasyon çubuğu seçili sekme
  int _selectedIndex = 0;
  // Analiz sonucu kaydırma için GlobalKey
  final GlobalKey _riskKartiKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Yeni API key veya model değişikliği için model'i sıfırla
    _gemini.resetModel();
    _checkInitialConnection();
    _listenToConnectivityChanges();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _binaAdiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// İlk bağlantı kontrolü
  Future<void> _checkInitialConnection() async {
    final isConnected = await ConnectivityService.checkConnection();
    if (mounted) {
      setState(() {
        _internetVar = isConnected;
      });
    }
  }

  // ── Otomatik bina adı ─────────────────────────────────────────────────────────
  static const List<String> _ayKisaltmalari = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  String _otomatikBinaAdi() {
    final now = DateTime.now();
    final ay = _ayKisaltmalari[now.month - 1];
    return 'Bina Analizi — ${now.day} $ay';
  }

  /// Demo modunu çalıştır — API çağrısı yapmadan örnek sonuç yükler
  Future<void> _demoModuCalistir() async {
    FirebaseAnalytics.instance.logEvent(name: 'demo_modu_kullanildi');
    setState(() {
      _yukleniyor = true;
      _analizAdimi = 1;
      _hataMesaji = null;
      _analizSonucu = null;
      _analizIptalEdildi = false;
    });
    // Gerçekçi yükleme süresi simülasyonu
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _analizIptalEdildi) return;
    setState(() {
      _analizSonucu = DemoService.demoAnaliz();
      _yukleniyor = false;
    });
    // Risk kartına kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_riskKartiKey.currentContext != null) {
        Scrollable.ensureVisible(
          _riskKartiKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }

  /// Bağlantı değişikliklerini dinle
  void _listenToConnectivityChanges() {
    _connectivitySubscription = ConnectivityService.listenToChanges((isConnected) {
      if (mounted) {
        setState(() {
          _internetVar = isConnected;
        });
        // Bağlantı geri geldiğinde bilgi ver
        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('connection_restored')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // ── Dosya boyutu sabitleri ──────────────────────────────────────────────────
  static const int _maxPdfBytes = 10 * 1024 * 1024;    // 10 MB
  static const int _maxPhotoBytes = 5 * 1024 * 1024;   // 5 MB

  Future<void> _pdfSec() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > _maxPdfBytes) {
          final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          setState(() {
            _hataMesaji = t('pdf_too_large').replaceAll('{size}', sizeMb);
          });
          return;
        }

        setState(() {
          _pdfDosya = file;
          _hataMesaji = null;
          // PDF seçildiğinde önceki analiz sonucunu temizle
          _analizSonucu = null;
        });
      }
    } on FileException catch (e) {
      setState(() {
        _hataMesaji = e.userMessage;
      });
    } catch (e) {
      setState(() {
        _hataMesaji = t('pdf_error');
      });
      debugPrint('PDF seçme hatası: $e');
    }
  }

  Future<void> _fotografSec() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        // Boyut kontrolü — her fotoğraf max 5 MB
        final List<File> gecerliDosyalar = [];
        final List<String> buyukDosyalar = [];

        for (final xFile in images) {
          final file = File(xFile.path);
          final fileSize = await file.length();
          if (fileSize > _maxPhotoBytes) {
            final name = xFile.name;
            final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            buyukDosyalar.add('$name (${sizeMb}MB)');
          } else {
            gecerliDosyalar.add(file);
          }
        }

        if (buyukDosyalar.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t('photo_too_large').replaceAll('{files}', buyukDosyalar.join(', ')),
              ),
              backgroundColor: Colors.orange[700],
              duration: const Duration(seconds: 4),
            ),
          );
        }

        if (gecerliDosyalar.isNotEmpty) {
          setState(() {
            _fotograflar = gecerliDosyalar;
            _hataMesaji = null;
            _analizSonucu = null;
          });
        }
      }
    } on FileException catch (e) {
      setState(() {
        _hataMesaji = e.userMessage;
      });
    } catch (e) {
      setState(() {
        _hataMesaji = t('photo_error');
      });
      debugPrint('Fotoğraf seçme hatası: $e');
    }
  }

  Future<void> _kameradanCek() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (photo != null) {
        final file = File(photo.path);
        final fileSize = await file.length();

        if (fileSize > _maxPhotoBytes) {
          final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
          setState(() {
            _hataMesaji = t('photo_camera_too_large').replaceAll('{size}', sizeMb);
          });
          return;
        }

        setState(() {
          _fotograflar.add(file);
          _hataMesaji = null;
          // Yeni fotoğraf eklendiğinde önceki analiz sonucunu temizle
          _analizSonucu = null;
        });
      }
    } on FileException catch (e) {
      setState(() {
        _hataMesaji = e.userMessage;
      });
    } catch (e) {
      setState(() {
        _hataMesaji = t('camera_error');
      });
      debugPrint('Kamera çekim hatası: $e');
    }
  }

  Future<void> _analizYap() async {
    if (_pdfDosya == null && _fotograflar.isEmpty) {
      setState(() {
        _hataMesaji = t('select_file_first');
      });
      return;
    }

    // İnternet bağlantısı kontrolü
    try {
      await ConnectivityService.ensureConnectionForAnalysis();
    } on NetworkException catch (e) {
      setState(() {
        _hataMesaji = e.userMessage;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ── Adım 0: Dosyalar hazırlanıyor ─────────────────────────────────────────
    setState(() {
      _yukleniyor = true;
      _analizAdimi = 0;
      _analizIptalEdildi = false;
      _hataMesaji = null;
      _analizSonucu = null;
    });

    // Adım 0 kullanıcıya görünsün diye kısa bekleme
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted || _analizIptalEdildi) return;

    // ── Adım 1: AI analizi başlıyor ────────────────────────────────────────────
    setState(() { _analizAdimi = 1; });

    try {
      final sonuc = await _gemini.analizYap(
        pdfDosya: _pdfDosya,
        fotograflar: _fotograflar,
      );

      // Kullanıcı iptal ettiyse sonucu işleme
      if (_analizIptalEdildi) return;

      // Null kontrolü
      if (sonuc == null || sonuc.isEmpty) {
        throw JsonParseException('Analiz sonucu boş', code: 'EMPTY_RESULT');
      }

      // ── Adım 2: Sonuçlar kaydediliyor ─────────────────────────────────────
      setState(() { _analizAdimi = 2; });

      try {
        // JSON'u parse et
        final jsonString = _extractJson(sonuc);

        if (jsonString.isEmpty || jsonString.trim().isEmpty) {
          throw JsonParseException('JSON string boş', code: 'EMPTY_JSON');
        }

        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        final analiz = RiskAnalizi.fromJson(jsonData);

        // Analizi geçmişe kaydet
        try {
          await _analiziKaydet(analiz);
        } catch (e) {
          debugPrint('UYARI: Analiz geçmişe kaydedilemedi: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t('history_save_error')),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        if (_analizIptalEdildi) return;

        setState(() {
          _analizSonucu = analiz;
          _yukleniyor = false;
          _hataMesaji = null;
        });

        // Analiz tamamlandıktan sonra risk kartının başına kaydır
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_riskKartiKey.currentContext != null) {
            Scrollable.ensureVisible(
              _riskKartiKey.currentContext!,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              alignment: 0.0,
            );
          }
        });

        // Analytics: analiz tamamlandı
        FirebaseAnalytics.instance.logEvent(
          name: 'analiz_tamamlandi',
          parameters: {
            'risk_skoru': analiz.riskSkoru.toInt(),
            'risk_seviyesi': analiz.riskSeviyesi,
            'tespit_sayisi': analiz.tespitler.length,
          },
        );

        // Başarılı analiz sonrası kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('analysis_complete')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (jsonError) {
        // JSON parse hatası
        throw JsonParseException(
          'JSON parse hatası: ${jsonError.toString()}',
          code: 'PARSE_ERROR',
          originalError: jsonError,
        );
      }
    } on AppException catch (e) {
      if (_analizIptalEdildi) return;
      // Quota hatası için temiz, teknik detaysız mesaj — sadece kırmızı kutu, SnackBar yok
      final mesaj = (e is ApiException && e.code == 'QUOTA_EXCEEDED')
          ? t('quota_exceeded_message')
          : e.userMessage;
      setState(() {
        _hataMesaji = mesaj;
        _yukleniyor = false;
      });

      // Debug için console'a yazdır
      debugPrint('Analiz Hatası (${e.runtimeType}): ${e.message}');
      if (e.originalError != null) {
        debugPrint('Orijinal Hata: ${e.originalError}');
      }
    } catch (e) {
      if (_analizIptalEdildi) return;
      // Beklenmeyen hatalar için generic ApiException
      final unknownException = ApiException(
        'Beklenmeyen hata: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      );

      setState(() {
        _hataMesaji = unknownException.userMessage;
        _yukleniyor = false;
      });

      // Debug için console'a yazdır
      debugPrint('Beklenmeyen Analiz Hatası: $e');
    }
  }

  String _extractJson(String text) {
    // JSON'u çıkar (markdown code blocks içinde olabilir)
    // DÜZELTME: Daha robust JSON extraction
    
    // 1. Önce markdown code block içinde JSON var mı kontrol et
    final codeBlockMatch = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```', 
      multiLine: true).firstMatch(text);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)!.trim();
    }
    
    // 2. Tek satırlık code block
    final inlineCodeMatch = RegExp(r'`(\{[^`]+\})`').firstMatch(text);
    if (inlineCodeMatch != null) {
      return inlineCodeMatch.group(1)!.trim();
    }
    
    // 3. En dıştaki JSON objesi ara (nested objects için bracket counting)
    int braceCount = 0;
    int startIndex = -1;
    
    for (int i = 0; i < text.length; i++) {
      if (text[i] == '{') {
        if (braceCount == 0) startIndex = i;
        braceCount++;
      } else if (text[i] == '}') {
        braceCount--;
        if (braceCount == 0 && startIndex != -1) {
          return text.substring(startIndex, i + 1).trim();
        }
      }
    }
    
    // 4. Hiçbir şey bulamazsa orijinal metni döndür
    return text.trim();
  }

  void _temizle() {
    setState(() {
      _pdfDosya = null;
      _fotograflar.clear();
      _analizSonucu = null;
      _hataMesaji = null;
    });
    _binaAdiController.clear();
  }

  /// Analizi geçmişe kaydet
  Future<void> _analiziKaydet(RiskAnalizi analiz) async {
    try {
      // Unique ID oluştur
      final analizId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Fotoğrafları kaydet
      List<String>? fotografPathleri;
      if (_fotograflar.isNotEmpty) {
        fotografPathleri = await AnalizGecmisiService.fotografKaydet(
          _fotograflar,
          analizId,
        );
      }
      
      // PDF'i kaydet
      String? pdfPath;
      if (_pdfDosya != null) {
        pdfPath = await AnalizGecmisiService.pdfKaydet(_pdfDosya!, analizId);
      }
      
      // Analiz kaydı oluştur — bina adı boşsa otomatik isim ata
      final binaAdiText = _binaAdiController.text.trim();
      final kayit = AnalizKaydi(
        id: analizId,
        tarih: DateTime.now(),
        analiz: analiz,
        fotografPathleri: fotografPathleri,
        pdfPath: pdfPath,
        binaAdi: binaAdiText.isEmpty ? _otomatikBinaAdi() : binaAdiText,
      );
      
      // Kaydet
      await AnalizGecmisiService.analizKaydet(kayit);
      
      // Periyodik takip hatırlatması zamanla (3 ay sonra)
      try {
        await TrackingService.onNewAnalysisAdded(kayit);
      } catch (e) {
        // Hatırlatma hatası kritik değil, sadece log'a yaz
        debugPrint('UYARI: Hatırlatma zamanlanamadı: $e');
      }
      
      debugPrint('Analiz başarıyla kaydedildi: $analizId');
    } catch (e) {
      debugPrint('Analiz kaydetme hatası: $e');
      rethrow;
    }
  }

  Future<void> _hesapSilOnayiGoster(BuildContext ctx) async {
    final onay = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(t('delete_account_title')),
          ],
        ),
        content: Text(t('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(t('cancel')),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever, size: 16),
            label: Text(t('delete_account_btn')),
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (onay == true && mounted) {
      try {
        await AuthService.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _pdfExport(RiskAnalizi analiz) async {
    if (_pdfYukleniyor) return;
    setState(() { _pdfYukleniyor = true; });
    try {
      await PdfService.raporOlusturVePaylas(analiz, _fotograflar);

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('pdf_success')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulurken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _pdfYukleniyor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Stack(
        children: [
          Scaffold(
            // AppBar yalnızca Ana Sayfa sekmesinde (Tab 0) görünür
            appBar: _selectedIndex == 0
                ? AppBar(
                    title: Text(
                      t('home_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    actions: [
                      // Hesap menüsü (tema + dil + çıkış) — harita/bilgi/geçmiş BottomNav'a taşındı
                      PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                onSelected: (value) async {
                  if (value == 'logout') {
                    FirebaseAnalytics.instance.logEvent(name: 'kullanici_cikis');
                    await AuthService.logout();
                    if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
                  } else if (value == 'theme_light') {
                    themeModeNotifier.value = ThemeMode.light;
                    _saveTheme(ThemeMode.light);
                  } else if (value == 'theme_dark') {
                    themeModeNotifier.value = ThemeMode.dark;
                    _saveTheme(ThemeMode.dark);
                  } else if (value == 'theme_system') {
                    themeModeNotifier.value = ThemeMode.system;
                    _saveTheme(ThemeMode.system);
                  } else if (value == 'lang_tr') {
                    await saveLanguage('tr');
                  } else if (value == 'lang_en') {
                    await saveLanguage('en');
                  } else if (value == 'notifications') {
                    if (context.mounted) Navigator.of(context).pushNamed('/bildirimler');
                  } else if (value == 'onboarding') {
                    // Onboarding bayrağını sıfırla ve tekrar göster
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_completed', false);
                    if (context.mounted) {
                      Navigator.of(context).pushNamed('/onboarding');
                    }
                  } else if (value == 'delete_account') {
                    _hesapSilOnayiGoster(context);
                  }
                },
                itemBuilder: (context) {
                  final currentTheme = themeModeNotifier.value;
                  final currentLang = languageNotifier.value;
                  return [
                    // ── Dil ──────────────────────────────────────────────
                    PopupMenuItem(
                      enabled: false,
                      child: Text(t('language'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    PopupMenuItem(
                      value: 'lang_tr',
                      child: Row(children: [
                        Text('🇹🇷', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        const Text('Türkçe'),
                        if (currentLang == 'tr') ...[const Spacer(), const Icon(Icons.check, size: 16)],
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'lang_en',
                      child: Row(children: [
                        Text('🇬🇧', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        const Text('English'),
                        if (currentLang == 'en') ...[const Spacer(), const Icon(Icons.check, size: 16)],
                      ]),
                    ),
                    const PopupMenuDivider(),
                    // ── Tema ─────────────────────────────────────────────
                    PopupMenuItem(
                      enabled: false,
                      child: Text(t('theme'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    PopupMenuItem(
                      value: 'theme_light',
                      child: Row(children: [
                        Icon(Icons.light_mode,
                            color: currentTheme == ThemeMode.light ? Colors.orange : Colors.grey),
                        const SizedBox(width: 8),
                        Text(t('light_mode')),
                        if (currentTheme == ThemeMode.light) ...[const Spacer(), const Icon(Icons.check, size: 16)],
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'theme_dark',
                      child: Row(children: [
                        Icon(Icons.dark_mode,
                            color: currentTheme == ThemeMode.dark ? Colors.indigo : Colors.grey),
                        const SizedBox(width: 8),
                        Text(t('dark_mode')),
                        if (currentTheme == ThemeMode.dark) ...[const Spacer(), const Icon(Icons.check, size: 16)],
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'theme_system',
                      child: Row(children: [
                        Icon(Icons.brightness_auto,
                            color: currentTheme == ThemeMode.system ? Colors.blue : Colors.grey),
                        const SizedBox(width: 8),
                        Text(t('system_mode')),
                        if (currentTheme == ThemeMode.system) ...[const Spacer(), const Icon(Icons.check, size: 16)],
                      ]),
                    ),
                    const PopupMenuDivider(),
                    // ── Bildirimler & Çıkış ───────────────────────────────
                    PopupMenuItem(
                      value: 'notifications',
                      child: Row(children: [
                        Icon(Icons.notifications_outlined, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(t('notification_settings')),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    // ── Tanıtım & Hesap ──────────────────────────────────
                    PopupMenuItem(
                      value: 'onboarding',
                      child: Row(children: [
                        Icon(Icons.tour_outlined, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(t('show_onboarding')),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(t('logout')),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete_account',
                      child: Row(children: [
                        Icon(Icons.delete_forever, color: Colors.red[800]),
                        const SizedBox(width: 8),
                        Text(t('delete_account'),
                            style: TextStyle(color: Colors.red[800])),
                      ]),
                    ),
                  ];
                },
              ),
            ],
                  )
                : null,
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                // ── Tab 0: Ana Sayfa ──────────────────────────────────────
                Column(
                  children: [
                    // Offline durum bildirimi
                    if (!_internetVar)
                      Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    color: Colors.orange[700],
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('offline_warning'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Offline uyarısında Geçmiş sekmesine geç
                      setState(() => _selectedIndex = 1);
                    },
                    child: Text(
                      t('go_to_history'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
                ),
              // Ana içerik
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Üst Bilgi Kartı
                      Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.apartment, size: 48, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          t('home_subtitle'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('home_description'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                      ),

                      Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                  // ── Fotoğraf Rehberi Kartı ────────────────────────────
                  _FotografRehberiKarti(),
                  const SizedBox(height: 12),

                  // ── Bina Adı Girişi ───────────────────────────────────
                  TextField(
                    controller: _binaAdiController,
                    enabled: !_yukleniyor,
                    decoration: InputDecoration(
                      labelText: t('building_name_label'),
                      hintText: t('building_name_hint'),
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),

                  // PDF Seç Butonu
                  ElevatedButton.icon(
                    onPressed: _pdfSec,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(_pdfDosya != null
                        ? '${t('pdf_selected')}: ${_pdfDosya!.path.split('/').last}'
                        : t('select_pdf')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[900],
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fotoğraf Seç Butonları
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _fotografSec,
                          icon: const Icon(Icons.photo_library),
                          label: Text(t('gallery')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green[900],
                            side: BorderSide(color: Colors.green[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _kameradanCek,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(t('camera')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[900],
                            side: BorderSide(color: Colors.blue[300]!),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Fotoğraf Listesi
                  if (_fotograflar.isNotEmpty)
                    FotografListesi(
                      fotograflar: _fotograflar,
                      tespitler: _analizSonucu?.tespitler,
                      onRemove: (index) {
                        setState(() {
                          _fotograflar.removeAt(index);
                          // Fotoğraf silindiğinde analiz sonucunu temizle (indeksler değişebilir)
                          if (_analizSonucu != null) {
                            _analizSonucu = null;
                          }
                        });
                      },
                    ),

                  const SizedBox(height: 24),

                  // ── Demo Modu Butonu ──────────────────────────────────
                  TextButton.icon(
                    onPressed: _yukleniyor ? null : _demoModuCalistir,
                    icon: const Text('🎭', style: TextStyle(fontSize: 16)),
                    label: Text(t('demo_try')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple[700],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Analiz Butonu (Animasyonlu)
                  AnimatedLoadingButton(
                    isLoading: _yukleniyor,
                    text: t('analyze'),
                    onPressed: () {
                      FirebaseAnalytics.instance.logEvent(
                        name: 'analiz_basladi',
                        parameters: {
                          'pdf_var': _pdfDosya != null ? 1 : 0,
                          'fotograf_sayisi': _fotograflar.length,
                        },
                      );
                      _analizYap();
                    },
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),

                  // Temizle Butonu
                  if (_pdfDosya != null || _fotograflar.isNotEmpty)
                    TextButton(
                      onPressed: _temizle,
                      child: Text(t('clear_all')),
                    ),

                  // Hata Mesajı
                  if (_hataMesaji != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Text(
                          _hataMesaji!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ),

                  // ── Analiz Sonuçları ─────────────────────────────────
                  // Sıra: 1. RiskKarti → 2. NeYapmaliyim → 3. PDF
                  if (_analizSonucu != null) ...[
                    const SizedBox(height: 16),

                    // 1. Risk Kartı (GlobalKey ile kaydırma hedefi)
                    RiskKarti(
                      key: _riskKartiKey,
                      analiz: _analizSonucu!,
                      fotograflar: _fotograflar,
                    ),
                    const SizedBox(height: 8),

                    // 2. Ne Yapmalıyım? Paneli
                    _NeyapmaliyimPaneli(analiz: _analizSonucu!),
                    const SizedBox(height: 16),

                    // 3. PDF Export Butonu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pdfYukleniyor ? null : () => _pdfExport(_analizSonucu!),
                              icon: _pdfYukleniyor
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.picture_as_pdf),
                              label: Text(_pdfYukleniyor ? t('pdf_creating') : t('create_pdf')),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                      ],
                    ),
                      ),
                    ],
                  ),
                ),
              ),
                  ],  // Tab 0 Column.children kapanış
                ),    // Tab 0 Column kapanış

                // ── Tab 1: Analiz Geçmişi ─────────────────────────────────
                const AnalizGecmisiScreen(),

                // ── Tab 2: Deprem Haritası ────────────────────────────────
                const DepremHaritasiScreen(),

                // ── Tab 3: Deprem Bilgilendirme ───────────────────────────
                const DepremBilgilendirmeScreen(),
              ],  // IndexedStack.children kapanış
            ),    // IndexedStack kapanış
            // ── Alt Navigasyon Çubuğu ──────────────────────────────────────
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue[700],
              onTap: (index) {
                setState(() => _selectedIndex = index);
                FirebaseAnalytics.instance.logEvent(
                  name: 'bottom_nav_tiklandi',
                  parameters: {'tab_index': index},
                );
              },
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: t('nav_home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history),
                  label: t('nav_history'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map_outlined),
                  activeIcon: const Icon(Icons.map),
                  label: t('nav_map'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.info_outline),
                  activeIcon: const Icon(Icons.info),
                  label: t('nav_info'),
                ),
              ],
            ),
          ),  // Scaffold kapanış
        // Loading Overlay — sadece Tab 0 (ana sayfa) yüklenirken göster
        if (_yukleniyor && _selectedIndex == 0)
          LoadingOverlay(
            isLoading: true,
            message: t('analysis_in_progress'),
            steps: [
              t('loading_step_files'),
              t('loading_step_ai'),
              t('loading_step_saving'),
            ],
            currentStep: _analizAdimi,
            onCancel: () {
              setState(() {
                _yukleniyor = false;
                _analizIptalEdildi = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t('analysis_cancelled')),
                  backgroundColor: Colors.orange[700],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    ),   // Stack kapanış
  );     // ValueListenableBuilder kapanış
  }
}

// ─── Fotoğraf Rehberi Kartı ─────────────────────────────────────────────────────

class _FotografRehberiKarti extends StatelessWidget {
  const _FotografRehberiKarti();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FotografRehberi.goster(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_camera_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('photo_guide_title'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 13)),
                Text(t('photo_guide_tip'),
                    style: TextStyle(color: Colors.blue[600], fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(t('photo_guide_btn'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ─── Ne Yapmalıyım? Paneli ──────────────────────────────────────────────────

class _NeyapmaliyimPaneli extends StatefulWidget {
  final RiskAnalizi analiz;
  const _NeyapmaliyimPaneli({required this.analiz});

  @override
  State<_NeyapmaliyimPaneli> createState() => _NeyapmaliyimPaneliState();
}

class _NeyapmaliyimPaneliState extends State<_NeyapmaliyimPaneli> {
  bool _acik = true;

  List<String> get _adimlar {
    final skor = widget.analiz.riskSkoru;
    final base = [
      t('action_emergency_plan'),
      t('action_bag'),
      t('action_insurance'),
      t('action_info'),
    ];
    if (skor > 7) {
      return [
        t('action_very_high_risk'),
        t('action_expert'),
        t('action_municipality'),
        t('action_reinforce'),
        ...base,
      ];
    } else if (skor > 5) {
      return [
        t('action_high_risk'),
        t('action_expert'),
        t('action_reinforce'),
        ...base,
      ];
    } else if (skor > 3) {
      return [
        t('action_medium_risk'),
        t('action_expert'),
        ...base,
      ];
    } else {
      return [
        t('action_good'),
        ...base,
      ];
    }
  }

  Color get _panelRengi {
    final skor = widget.analiz.riskSkoru;
    if (skor > 7) return Colors.red[700]!;
    if (skor > 5) return Colors.orange[700]!;
    if (skor > 3) return Colors.amber[700]!;
    return Colors.green[600]!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _panelRengi.withOpacity(0.4), width: 1.5),
      ),
      child: Column(children: [
        // Başlık
        InkWell(
          onTap: () => setState(() => _acik = !_acik),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _panelRengi.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _panelRengi, shape: BoxShape.circle),
                child: const Icon(Icons.checklist,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('what_to_do'),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _panelRengi,
                            fontSize: 15)),
                    Text(t('what_to_do_subtitle'),
                        style: TextStyle(
                            color: _panelRengi.withOpacity(0.8),
                            fontSize: 11)),
                  ],
                ),
              ),
              Icon(_acik ? Icons.expand_less : Icons.expand_more,
                  color: _panelRengi),
            ]),
          ),
        ),
        // İçerik
        if (_acik)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              children: [
                ..._adimlar.map((adim) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(adim,
                              style: const TextStyle(
                                  fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                // Haritaya git butonu
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/harita'),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: Text(t('go_to_map'),
                        style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _panelRengi,
                      side: BorderSide(color: _panelRengi),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Global Dil Notifier ──────────────────────────────────────────────────────
final ValueNotifier<String> languageNotifier = ValueNotifier('tr');

Future<void> loadSavedLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  languageNotifier.value = prefs.getString('app_language') ?? 'tr';
}

Future<void> saveLanguage(String lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_language', lang);
  languageNotifier.value = lang;
}

// ─── Kısa erişim fonksiyonu ───────────────────────────────────────────────────
String t(String key) {
  final lang = languageNotifier.value;
  final map = lang == 'en' ? _en : _tr;
  return map[key] ?? _tr[key] ?? key;
}

// ─── Türkçe ───────────────────────────────────────────────────────────────────
const Map<String, String> _tr = {
  // Genel
  'app_name': 'Mimar-AI',
  'ok': 'Tamam',
  'cancel': 'İptal',
  'save': 'Kaydet',
  'delete': 'Sil',
  'close': 'Kapat',
  'retry': 'Tekrar Dene',
  'loading': 'Yükleniyor...',
  'error': 'Hata',
  'yes': 'Evet',
  'no': 'Hayır',
  'back': 'Geri',
  'next': 'İleri',
  'finish': 'Bitir',
  'share': 'Paylaş',
  'search': 'Ara...',
  'clear': 'Temizle',
  'settings': 'Ayarlar',
  'language': 'Dil',
  'theme': 'Tema',
  'light_mode': 'Aydınlık',
  'dark_mode': 'Karanlık',
  'system_mode': 'Sistem',
  'logout': 'Çıkış Yap',

  // Login
  'login_title': 'Mimar-AI',
  'login_subtitle': 'Deprem Riski Analiz Uygulaması',
  'email': 'Email',
  'email_hint': 'ornek@email.com',
  'password': 'Şifre',
  'password_hint': '••••••',
  'forgot_password': 'Şifremi Unuttum',
  'login_btn': 'Giriş Yap',
  'no_account': 'Hesabınız yok mu?',
  'register': 'Kayıt Olun',
  'guest_btn': 'Misafir Olarak Devam Et',
  'guest_warning': 'Misafir modunda analizler cihazınıza kaydedilir, hesabınıza bağlı olmaz.',
  'email_required': 'Email giriniz',
  'email_invalid': 'Geçerli bir email giriniz',
  'password_required': 'Şifre giriniz',
  'password_short': 'Şifre en az 6 karakter olmalıdır',

  // Şifre sıfırlama
  'reset_password': 'Şifre Sıfırlama',
  'reset_email_sent': 'Şifre sıfırlama emaili gönderildi. Lütfen email kutunuzu kontrol edin.',
  'reset_email_info': 'Email adresinize şifre sıfırlama linki gönderilecektir.',
  'send': 'Gönder',

  // Ana ekran
  'home_title': 'Mimar-AI',
  'home_subtitle': 'Deprem Riski Analizi',
  'home_description': 'PDF ve fotoğraflarınızı yükleyerek binanızın deprem güvenliğini analiz edin',
  'select_pdf': 'PDF Belgesi Seç (Ruhsat/Tapu)',
  'pdf_selected': 'PDF Seçildi',
  'gallery': 'Galeri',
  'camera': 'Kamera',
  'analyze': 'Analiz Yap',
  'clear_all': 'Temizle',
  'offline_warning': 'İnternet bağlantısı yok. Geçmiş analizleri görüntüleyebilirsiniz.',
  'go_to_history': 'Geçmişe Git',
  'analysis_in_progress': 'Bina analizi yapılıyor...\nPDF ve fotoğraflar inceleniyor',
  'analysis_complete': 'Analiz tamamlandı! Sonuçlar aşağıda görüntüleniyor.',
  'pdf_error': 'PDF seçilirken hata oluştu. Lütfen tekrar deneyin.',
  'photo_error': 'Fotoğraf seçilirken hata oluştu. Lütfen tekrar deneyin.',
  'camera_error': 'Kameradan çekim sırasında hata oluştu.',
  'select_file_first': 'Lütfen en az bir PDF veya fotoğraf seçin',
  'create_pdf': 'PDF Rapor Oluştur ve Paylaş',
  'pdf_creating': 'PDF oluşturuluyor...',
  'pdf_success': 'PDF başarıyla oluşturuldu ve paylaşım ekranı açıldı.',
  'guest_mode_badge': 'Misafir Mod',

  // Fotoğraf rehberi
  'photo_guide_title': 'Fotoğraf Rehberi',
  'photo_guide_subtitle': 'Daha doğru analiz için nasıl fotoğraf çekilmeli?',
  'photo_guide_btn': 'Rehberi Gör',
  'photo_guide_tip': 'İyi fotoğraflar = Daha doğru AI analizi',

  // Risk kartı / Ne yapmalıyım
  'risk_score': 'Risk Skoru',
  'what_to_do': 'Ne Yapmalıyım?',
  'what_to_do_subtitle': 'Risk seviyenize göre önerilen adımlar',
  'action_expert': '🏗️ Yetkili inşaat mühendisinden yapısal değerlendirme talep edin',
  'action_municipality': '🏛️ Belediyenizin deprem risk hizmetlerinden faydalanın',
  'action_reinforce': '🔧 Tespit edilen hasarların güçlendirme/onarım planlamasını yapın',
  'action_insurance': '📋 DASK sigortanızı güncel tutun ve kapsamını artırın',
  'action_emergency_plan': '🚨 Aile deprem acil eylem planı hazırlayın',
  'action_bag': '🎒 72 saatlik deprem çantanızı hazırlayın',
  'action_info': 'ℹ️ Deprem bilgilendirme bölümünü inceleyin',
  'action_good': '✅ Binanız genel olarak iyi durumda. Periyodik kontrollere devam edin.',
  'action_low_risk': 'Risk düşük, ancak önlem almak her zaman önerilir.',
  'action_medium_risk': 'Orta risk seviyesinde. Uzman değerlendirmesi yapılmalı.',
  'action_high_risk': 'Yüksek risk! Acil müdahale gerekebilir.',
  'action_very_high_risk': 'Çok yüksek risk! Yapıyı derhal bir uzman incelemeldir.',
  'share_result': 'Sonucu Paylaş',
  'go_to_map': 'Deprem Haritasına Git',

  // Analiz geçmişi
  'history_title': 'Analiz Geçmişi',
  'history_empty': 'Henüz analiz geçmişi yok',
  'history_empty_sub': 'İlk analizinizi yaparak başlayın',
  'history_search': 'Bina adı veya tarih ara...',
  'history_filter': 'Filtrele',
  'history_filter_all': 'Tümü',
  'history_filter_high': 'Yüksek Risk',
  'history_filter_medium': 'Orta Risk',
  'history_filter_low': 'Düşük Risk',
  'history_sort_date': 'Tarihe Göre',
  'history_sort_risk': 'Riske Göre',
  'delete_analysis': 'Analiz Sil',
  'delete_confirm': 'adlı analiz silinsin mi?',
  'delete_all': 'Tüm Geçmişi Temizle',
  'delete_all_confirm': 'Tüm analiz geçmişi silinsin mi? Bu işlem geri alınamaz.',
  'delete_success': 'Analiz silindi',
  'delete_all_success': 'Tüm geçmiş temizlendi',
  'compare': 'Karşılaştır',
  'findings': 'tespit',
  'no_results': 'Arama sonucu bulunamadı',

  // Bildirim ayarları
  'notification_settings': 'Bildirim Ayarları',
  'notification_analysis_reminder': 'Analiz Hatırlatması',
  'notification_analysis_reminder_sub': '3 ayda bir analiz yenileme bildirimi',
  'notification_earthquake_alert': 'Deprem Uyarısı',
  'notification_earthquake_alert_sub': 'Bölgenizdeki önemli depremler için bildirim',
  'notification_tips': 'İpuçları ve Öneriler',
  'notification_tips_sub': 'Deprem güvenliği ipuçları',
  'notification_test': 'Test Bildirimi Gönder',
  'notification_test_sent': 'Test bildirimi gönderildi',
  'notification_reminder_interval': 'Hatırlatma Aralığı',
  'notification_1month': '1 Ay',
  'notification_3months': '3 Ay',
  'notification_6months': '6 Ay',
  'notification_permission_required': 'Bildirim izni gerekli',
  'notification_permission_sub': 'Ayarlardan bildirim iznini etkinleştirin',
  'notification_open_settings': 'Ayarları Aç',

  // Harita
  'map_title': 'Deprem & Fay Haritası',
  'map_last_24h': 'Son 24 saat',
  'map_last_7d': 'Son 7 gün',
  'map_filter_magnitude': 'Büyüklük Filtresi',
  'map_scan_nearby': 'Yakınımı Tara',
  'map_rescan': 'Tekrar Tara',
  'map_assembly': 'Toplanma',
  'map_hospital': 'Hastane',
  'map_police': 'Polis',
  'map_fire': 'İtfaiye',
  'map_select_fault': 'Fay Seç',
  'map_layers': 'Harita Katmanları',
  'map_earthquakes': 'Depremler',
  'map_fault_lines': 'Fay Hatları',
  'map_assembly_areas': 'Toplanma Alanları',
  'map_emergency': 'Acil Servisler',
  'map_my_location': 'Konumum',

  // Deprem bilgilendirme
  'info_title': 'Deprem Bilgilendirme',

  // Onboarding
  'onboarding_skip': 'Atla',
  'onboarding_next': 'İleri',
  'onboarding_start': 'Başlayalım',
  'onboarding_lang_title': 'Dil Seçin',
  'onboarding_lang_sub': 'Uygulamayı hangi dilde kullanmak istersiniz?',
  'onboarding_0_title': 'Deprem Riski Analizi',
  'onboarding_0_desc': 'Binanızın deprem güvenliğini AI destekli analiz ile değerlendirin. PDF belgeleriniz ve fotoğraflarınız ile detaylı rapor alın.',
  'onboarding_1_title': 'Kolay Kullanım',
  'onboarding_1_desc': 'Sadece PDF belgenizi ve binanızın fotoğraflarını yükleyin. Mimar-AI gerisini hallediyor.',
  'onboarding_2_title': 'Bilimsel Tabanlı',
  'onboarding_2_desc': 'Kıdemli inşaat mühendisi ve deprem uzmanı AI\'nız, bilimsel formüllerle risk skoru hesaplıyor ve öneriler sunuyor.',
  'onboarding_3_title': 'Güvenli ve Hızlı',
  'onboarding_3_desc': 'Verileriniz güvende. Analiz sonuçlarınızı PDF olarak paylaşabilir, detaylı raporlar alabilirsiniz.',

  // Giriş ekranı (login_screen)
  'login_welcome_title': 'Haydi Başlayalım! 🚀',
  'login_welcome_subtitle': 'Binanızın deprem güvenliğini\nyapay zeka ile analiz edin',
  'continue_with_google': 'Google ile Devam Et',
  'or': 'veya',
  'continue_as_guest_btn': 'Misafir olarak devam et →',
  'guest_local_save': 'Analizler yalnızca cihazınıza kaydedilir',
  'google_sign_in_error': 'Google ile giriş yapılamadı. Tekrar deneyin.',

  // Kayıt ekranı (register_screen)
  'register_screen_title': 'Hesap Oluştur',
  'register_welcome_title': 'Aramıza katılın! 👋',
  'register_welcome_subtitle': 'Binanızı analiz etmeye başlayın',
  'or_register_with_email': 'veya email ile kayıt ol',
  'full_name': 'Ad Soyad',
  'full_name_hint': 'Adınız Soyadınız',
  'full_name_required': 'Ad soyad giriniz',
  'full_name_short': 'En az 2 karakter olmalıdır',
  'password_min_chars': 'En az 6 karakter',
  'password_confirm_label': 'Şifre Tekrar',
  'password_confirm_hint': 'Şifrenizi tekrar giriniz',
  'password_confirm_required': 'Şifre tekrarını giriniz',
  'password_mismatch': 'Şifreler eşleşmiyor',
  'create_account_btn': 'Hesap Oluştur',
  'have_account': 'Zaten hesabınız var mı? ',
  'sign_in_link': 'Giriş Yapın',
  'register_error_prefix': 'Kayıt olurken hata oluştu: ',

  // Email giriş ekranı (email_login_screen)
  'email_login_screen_title': 'Email ile Giriş',
  'login_welcome_back': 'Tekrar hoş geldiniz 👋',
  'login_sign_in_sub': 'Hesabınıza giriş yapın',
  'reset_email_info_dialog': 'Email adresinize şifre sıfırlama bağlantısı gönderilecek.',
  'reset_email_sent_dialog': 'Şifre sıfırlama bağlantısı gönderildi. Email kutunuzu kontrol edin.',
  'login_error_prefix': 'Giriş yapılırken hata oluştu: ',

  // Email doğrulama ekranı (email_verification_screen)
  'verify_email_title': 'Emailinizi Doğrulayın',
  'verify_email_sent_to': 'Doğrulama bağlantısı şu adrese gönderildi:\n',
  'verify_email_spam': 'Spam / Önemsiz klasörünü de kontrol edin.',
  'verify_confirm_btn': 'Doğruladım, Devam Et',
  'verify_resend_btn': 'Emaili Yeniden Gönder',
  'verify_resend_countdown': 'Yeniden gönder',
  'verify_auto_detect': 'Sayfa email doğrulamasını otomatik olarak algılar.',
  'verify_resent_success': 'Doğrulama emaili tekrar gönderildi!',
  'verify_resend_failed_prefix': 'Email gönderilemedi: ',

  // Analiz detay
  'analysis_date_label': 'Analiz Tarihi',
  'photos_label': 'Fotoğraflar',

  // Ana sayfa ek metinler
  'connection_restored': 'İnternet bağlantısı geri geldi',
  'history_save_error': 'Analiz tamamlandı ancak geçmişe kaydedilemedi',

  // Hesap yönetimi
  'show_onboarding': 'Tanıtımı Tekrar Gör',
  'delete_account': 'Hesabımı Sil',
  'delete_account_title': 'Hesabı Sil',
  'delete_account_confirm': 'Hesabınız ve tüm verileriniz kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misiniz?',
  'delete_account_btn': 'Evet, Sil',

  // Risk skoru formül açıklaması
  'risk_score_formula_title': 'Risk Skoru Nasıl Hesaplanır?',
  'risk_score_formula_desc': 'Risk skoru, AI modelinin yapısal analiz bulgularına dayanarak 0-10 skalasında hesapladığı bütünleşik bir deprem risk puanıdır.',
  'risk_score_factors': 'Dikkate Alınan Faktörler:',
  'factor_age': 'Bina yaşı ve yapım yılı',
  'factor_floors': 'Kat sayısı ve yüksekliği',
  'factor_construction': 'Yapı sistemi türü (betonarme, yığma, çelik)',
  'factor_concrete': 'Beton kalitesi ve sınıfı',
  'factor_damage': 'Mevcut hasar ve çatlakların şiddeti',
  'factor_seismic_zone': 'Deprem bölgesi ve zemin koşulları',
  'risk_score_ranges': 'Skor Aralıkları:',
  'range_very_low': 'Çok Düşük Risk',
  'range_low': 'Düşük Risk',
  'range_medium': 'Orta Risk',
  'range_high': 'Yüksek Risk',
  'range_very_high': 'Çok Yüksek Risk',
  'risk_score_disclaimer': 'Bu puan yalnızca yönlendirme amaçlıdır. Kesin karar için yetkili inşaat mühendisi değerlendirmesi gerekir.',

  // Fotoğraf önizleme & silme
  'photo_preview': 'Fotoğraf',
  'delete_photo_title': 'Fotoğrafı Sil',
  'delete_photo_confirm': 'Bu fotoğraf listeden kaldırılsın mı?',

  // Dosya boyutu hataları
  'pdf_too_large': 'PDF dosyası çok büyük ({size}MB). Maksimum 10MB desteklenmektedir.',
  'photo_too_large': 'Bazı fotoğraflar 5MB sınırını aştığı için atlandı: {files}',
  'photo_camera_too_large': 'Çekilen fotoğraf çok büyük ({size}MB). Maksimum 5MB desteklenmektedir.',

  // Analiz geçmişi hata
  'history_load_error': 'Analizler yüklenirken hata oluştu. Lütfen tekrar deneyin.',

  // Bina adı girişi
  'building_name_label': 'Bina Adı (opsiyonel)',
  'building_name_hint': 'Örn: Ev, Daire, İşyeri...',

  // Risk kartı etiketleri
  'building_info': 'Bina Bilgileri',
  'building_age_label': 'Bina Yaşı',
  'concrete_grade_label': 'Beton Sınıfı',
  'floor_count_label': 'Kat Sayısı',
  'structure_type_label': 'Yapı Tipi',
  'damage_severity_label': 'Hasar Şiddeti',
  'urgency_level_label': 'Aciliyet Seviyesi',
  'estimated_cost_label': 'Tahmini Maliyet',
  'findings_title': 'Tespitler',
  'engineer_advice_title': 'Mühendis Tavsiyesi',
  'tap_to_zoom': 'Büyütmek için tıklayın',
  'photo_label': 'Fotoğraf',

  // Loading overlay adımları
  'loading_please_wait': 'Lütfen bekleyin...',
  'loading_step_files': 'Dosyalar okunuyor...',
  'loading_step_ai': 'AI analizi yapılıyor...',
  'loading_step_saving': 'Sonuçlar kaydediliyor...',
  'cancel_analysis': 'İptal Et',
  'analysis_cancelled': 'Analiz iptal edildi.',

  // Alt navigasyon çubuğu
  'nav_home': 'Ana Sayfa',
  'nav_history': 'Geçmiş',
  'nav_map': 'Harita',
  'nav_info': 'Bilgi',

  // Demo modu
  'demo_try': 'Demo ile Dene',

  // Kota aşımı — temiz mesaj
  'quota_exceeded_message':
      'Günlük analiz limitine ulaşıldı. Lütfen birkaç saat sonra tekrar deneyin.',

  // Fotoğraf rehberi içeriği
  'guide_title': 'Fotoğraf Çekim Rehberi',
  'guide_subtitle': 'AI analizini doğru fotoğrafla güçlendirin',
  'guide_prev': 'Önceki',
  'guide_next': 'Sonraki',
  'guide_start': 'Anladım, Başlayalım',
  // Adım 1: Dış Cephe
  'guide_s1_title': 'Dış Cephe',
  'guide_s1_sub': 'Binanın dört yönünden tam cephe fotoğrafı çekin',
  'guide_s1_m1': 'Binanın tamamı kadraja girsin',
  'guide_s1_m2': 'En az 2 farklı açıdan çekin (ön ve yan)',
  'guide_s1_m3': 'Çatlak, dökülme veya eğim görünür olsun',
  'guide_s1_m4': 'Sabah veya bulutlu havada çekin (gölge azalır)',
  'guide_s1_m5': 'Zoom kullanmaktan kaçının, uzaklaşın',
  'guide_s1_tip': '💡 Tüm bina tek karede görünmüyorsa biraz geri çekilin.',
  // Adım 2: Temel ve Kolon
  'guide_s2_title': 'Temel ve Kolon',
  'guide_s2_sub': 'Yapısal taşıyıcı elemanları yakından fotoğraflayın',
  'guide_s2_m1': 'Kolonların alt ve üst birleşim noktalarını çekin',
  'guide_s2_m2': "Görünür çatlakları 30-50 cm'den fotoğraflayın",
  'guide_s2_m3': 'Pas izleri veya beton dökülmelerini yakın plan çekin',
  'guide_s2_m4': 'Köşe kolonlarına özellikle dikkat edin',
  'guide_s2_m5': 'Bodrum kattaki temeli mutlaka fotoğraflayın',
  'guide_s2_tip': '💡 El feneri veya telefon flaşı kullanarak karanlık köşeleri aydınlatın.',
  // Adım 3: İç Mekân
  'guide_s3_title': 'İç Mekân',
  'guide_s3_sub': 'Duvar, tavan ve döşeme yüzeylerini kaydedin',
  'guide_s3_m1': 'Her odanın bir köşesinden tavan-duvar birleşimini çekin',
  'guide_s3_m2': 'Kapı ve pencere çevrelerindeki çatlakları belgeleyin',
  'guide_s3_m3': 'Tavan sıvasındaki iz veya sarkmayı çekin',
  'guide_s3_m4': 'Döşemedeki eğim veya çökme var mı kontrol edin',
  'guide_s3_m5': 'Islak mekânlarda (banyo, mutfak) nem izini çekin',
  'guide_s3_tip': '💡 Flaş kullanın; aydınlık fotoğraflar AI analizinin doğruluğunu artırır.',
  // Adım 4: Merdiven ve Koridorlar
  'guide_s4_title': 'Merdiven ve Koridorlar',
  'guide_s4_sub': 'Ortak kullanım alanlarındaki hasarları belgeleyin',
  'guide_s4_m1': 'Merdiven basamaklarının yan duvarını boydan çekin',
  'guide_s4_m2': 'Koridor boyunca uzanan çatlakları belgeleyin',
  'guide_s4_m3': 'Asansör boşluğu çevresini (varsa) kontrol edin',
  'guide_s4_m4': 'Yangın merdiveni veya kaçış yolunu belgeleyin',
  'guide_s4_m5': 'Binanın geneli hakkında fikir veren geniş açı çekin',
  'guide_s4_tip': '💡 Kameraya tıklayarak odak noktasını çatlağa sabitleyin.',
  // Adım 5: Son Kontroller
  'guide_s5_title': 'Son Kontroller',
  'guide_s5_sub': 'Fotoğraf setinizi yüklemeden önce doğrulayın',
  'guide_s5_m1': 'En az 4–6 fotoğraf yükleyin (çok az bilgi yetersiz kalabilir)',
  'guide_s5_m2': 'Her fotoğraf net ve odaklı olsun, bulanık olanları silin',
  'guide_s5_m3': 'Karanlık veya aşırı parlak fotoğrafları yeniden çekin',
  'guide_s5_m4': 'Farklı bölgeleri (dış, iç, kolon, tavan) kapsayın',
  'guide_s5_m5': 'Boyut limiti: tek fotoğraf maksimum 5 MB',
  'guide_s5_tip': '✅ Hazırsanız ekranı kapatıp fotoğraflarınızı yükleyin.',
};

// ─── İngilizce ────────────────────────────────────────────────────────────────
const Map<String, String> _en = {
  // General
  'app_name': 'Mimar-AI',
  'ok': 'OK',
  'cancel': 'Cancel',
  'save': 'Save',
  'delete': 'Delete',
  'close': 'Close',
  'retry': 'Retry',
  'loading': 'Loading...',
  'error': 'Error',
  'yes': 'Yes',
  'no': 'No',
  'back': 'Back',
  'next': 'Next',
  'finish': 'Finish',
  'share': 'Share',
  'search': 'Search...',
  'clear': 'Clear',
  'settings': 'Settings',
  'language': 'Language',
  'theme': 'Theme',
  'light_mode': 'Light',
  'dark_mode': 'Dark',
  'system_mode': 'System',
  'logout': 'Log Out',

  // Login
  'login_title': 'Mimar-AI',
  'login_subtitle': 'Earthquake Risk Analysis App',
  'email': 'Email',
  'email_hint': 'example@email.com',
  'password': 'Password',
  'password_hint': '••••••',
  'forgot_password': 'Forgot Password',
  'login_btn': 'Log In',
  'no_account': "Don't have an account?",
  'register': 'Sign Up',
  'guest_btn': 'Continue as Guest',
  'guest_warning': 'In guest mode, analyses are saved locally and not linked to an account.',
  'email_required': 'Enter your email',
  'email_invalid': 'Enter a valid email',
  'password_required': 'Enter your password',
  'password_short': 'Password must be at least 6 characters',

  // Password reset
  'reset_password': 'Password Reset',
  'reset_email_sent': 'Password reset email sent. Please check your inbox.',
  'reset_email_info': 'A password reset link will be sent to your email.',
  'send': 'Send',

  // Home
  'home_title': 'Mimar-AI',
  'home_subtitle': 'Earthquake Risk Analysis',
  'home_description': 'Upload PDF and photos to analyze your building\'s earthquake safety',
  'select_pdf': 'Select PDF Document (Permit/Deed)',
  'pdf_selected': 'PDF Selected',
  'gallery': 'Gallery',
  'camera': 'Camera',
  'analyze': 'Analyze',
  'clear_all': 'Clear',
  'offline_warning': 'No internet connection. You can view past analyses.',
  'go_to_history': 'Go to History',
  'analysis_in_progress': 'Analyzing building...\nReviewing PDF and photos',
  'analysis_complete': 'Analysis complete! Results are shown below.',
  'pdf_error': 'Error selecting PDF. Please try again.',
  'photo_error': 'Error selecting photo. Please try again.',
  'camera_error': 'Error capturing photo from camera.',
  'select_file_first': 'Please select at least one PDF or photo',
  'create_pdf': 'Create & Share PDF Report',
  'pdf_creating': 'Creating PDF...',
  'pdf_success': 'PDF created successfully and share sheet opened.',
  'guest_mode_badge': 'Guest Mode',

  // Photo guide
  'photo_guide_title': 'Photo Guide',
  'photo_guide_subtitle': 'How to take photos for more accurate analysis?',
  'photo_guide_btn': 'View Guide',
  'photo_guide_tip': 'Better photos = More accurate AI analysis',

  // Risk card / What to do
  'risk_score': 'Risk Score',
  'what_to_do': 'What Should I Do?',
  'what_to_do_subtitle': 'Recommended steps based on your risk level',
  'action_expert': '🏗️ Request a structural assessment from a licensed civil engineer',
  'action_municipality': '🏛️ Use your municipality\'s earthquake risk services',
  'action_reinforce': '🔧 Plan reinforcement/repair for identified damage',
  'action_insurance': '📋 Keep your earthquake insurance current and expand coverage',
  'action_emergency_plan': '🚨 Prepare a family earthquake emergency action plan',
  'action_bag': '🎒 Prepare a 72-hour earthquake emergency kit',
  'action_info': 'ℹ️ Review the earthquake information section',
  'action_good': '✅ Your building is generally in good condition. Continue periodic checks.',
  'action_low_risk': 'Low risk, but taking precautions is always recommended.',
  'action_medium_risk': 'Medium risk. An expert assessment should be done.',
  'action_high_risk': 'High risk! Urgent intervention may be required.',
  'action_very_high_risk': 'Very high risk! An expert must inspect the building immediately.',
  'share_result': 'Share Result',
  'go_to_map': 'Go to Earthquake Map',

  // Analysis history
  'history_title': 'Analysis History',
  'history_empty': 'No analysis history yet',
  'history_empty_sub': 'Start by doing your first analysis',
  'history_search': 'Search by building name or date...',
  'history_filter': 'Filter',
  'history_filter_all': 'All',
  'history_filter_high': 'High Risk',
  'history_filter_medium': 'Medium Risk',
  'history_filter_low': 'Low Risk',
  'history_sort_date': 'By Date',
  'history_sort_risk': 'By Risk',
  'delete_analysis': 'Delete Analysis',
  'delete_confirm': 'will be deleted. Are you sure?',
  'delete_all': 'Clear All History',
  'delete_all_confirm': 'Delete all analysis history? This cannot be undone.',
  'delete_success': 'Analysis deleted',
  'delete_all_success': 'All history cleared',
  'compare': 'Compare',
  'findings': 'findings',
  'no_results': 'No search results found',

  // Notification settings
  'notification_settings': 'Notification Settings',
  'notification_analysis_reminder': 'Analysis Reminder',
  'notification_analysis_reminder_sub': 'Analysis renewal notification every 3 months',
  'notification_earthquake_alert': 'Earthquake Alert',
  'notification_earthquake_alert_sub': 'Notification for significant earthquakes in your area',
  'notification_tips': 'Tips & Recommendations',
  'notification_tips_sub': 'Earthquake safety tips',
  'notification_test': 'Send Test Notification',
  'notification_test_sent': 'Test notification sent',
  'notification_reminder_interval': 'Reminder Interval',
  'notification_1month': '1 Month',
  'notification_3months': '3 Months',
  'notification_6months': '6 Months',
  'notification_permission_required': 'Notification permission required',
  'notification_permission_sub': 'Enable notification permission in settings',
  'notification_open_settings': 'Open Settings',

  // Map
  'map_title': 'Earthquake & Fault Map',
  'map_last_24h': 'Last 24 hours',
  'map_last_7d': 'Last 7 days',
  'map_filter_magnitude': 'Magnitude Filter',
  'map_scan_nearby': 'Scan Nearby',
  'map_rescan': 'Rescan',
  'map_assembly': 'Assembly',
  'map_hospital': 'Hospital',
  'map_police': 'Police',
  'map_fire': 'Fire Dept.',
  'map_select_fault': 'Select Fault',
  'map_layers': 'Map Layers',
  'map_earthquakes': 'Earthquakes',
  'map_fault_lines': 'Fault Lines',
  'map_assembly_areas': 'Assembly Points',
  'map_emergency': 'Emergency Services',
  'map_my_location': 'My Location',

  // Earthquake info
  'info_title': 'Earthquake Information',

  // Onboarding
  'onboarding_skip': 'Skip',
  'onboarding_next': 'Next',
  'onboarding_start': 'Get Started',
  'onboarding_lang_title': 'Select Language',
  'onboarding_lang_sub': 'Which language would you like to use?',
  'onboarding_0_title': 'Earthquake Risk Analysis',
  'onboarding_0_desc': 'Assess your building\'s earthquake safety with AI-powered analysis. Get detailed reports with your PDF documents and photos.',
  'onboarding_1_title': 'Easy to Use',
  'onboarding_1_desc': 'Just upload your PDF document and building photos. Mimar-AI takes care of the rest.',
  'onboarding_2_title': 'Science-Based',
  'onboarding_2_desc': 'Your senior structural engineer and earthquake expert AI calculates risk scores with scientific formulas and provides recommendations.',
  'onboarding_3_title': 'Safe and Fast',
  'onboarding_3_desc': 'Your data is safe. You can share your analysis results as PDF and get detailed reports.',

  // Login screen
  'login_welcome_title': 'Let\'s Get Started! 🚀',
  'login_welcome_subtitle': 'Analyze your building\'s earthquake safety\nwith artificial intelligence',
  'continue_with_google': 'Continue with Google',
  'or': 'or',
  'continue_as_guest_btn': 'Continue as guest →',
  'guest_local_save': 'Analyses are saved to your device only',
  'google_sign_in_error': 'Failed to sign in with Google. Please try again.',

  // Register screen
  'register_screen_title': 'Create Account',
  'register_welcome_title': 'Join Us! 👋',
  'register_welcome_subtitle': 'Start analyzing your building',
  'or_register_with_email': 'or register with email',
  'full_name': 'Full Name',
  'full_name_hint': 'Your Full Name',
  'full_name_required': 'Enter your full name',
  'full_name_short': 'Must be at least 2 characters',
  'password_min_chars': 'At least 6 characters',
  'password_confirm_label': 'Confirm Password',
  'password_confirm_hint': 'Re-enter your password',
  'password_confirm_required': 'Enter password confirmation',
  'password_mismatch': 'Passwords do not match',
  'create_account_btn': 'Create Account',
  'have_account': 'Already have an account? ',
  'sign_in_link': 'Sign In',
  'register_error_prefix': 'Error during registration: ',

  // Email login screen
  'email_login_screen_title': 'Sign In with Email',
  'login_welcome_back': 'Welcome back 👋',
  'login_sign_in_sub': 'Sign in to your account',
  'reset_email_info_dialog': 'A password reset link will be sent to your email address.',
  'reset_email_sent_dialog': 'Password reset link sent. Please check your inbox.',
  'login_error_prefix': 'Error during sign in: ',

  // Email verification screen
  'verify_email_title': 'Verify Your Email',
  'verify_email_sent_to': 'Verification link was sent to:\n',
  'verify_email_spam': 'Also check your spam/junk folder.',
  'verify_confirm_btn': 'I\'ve Verified, Continue',
  'verify_resend_btn': 'Resend Email',
  'verify_resend_countdown': 'Resend',
  'verify_auto_detect': 'Page automatically detects email verification.',
  'verify_resent_success': 'Verification email resent!',
  'verify_resend_failed_prefix': 'Failed to send email: ',

  // Analysis detail
  'analysis_date_label': 'Analysis Date',
  'photos_label': 'Photos',

  // Home screen extra
  'connection_restored': 'Internet connection restored',
  'history_save_error': 'Analysis completed but could not be saved to history',

  // Account management
  'show_onboarding': 'View Intro Again',
  'delete_account': 'Delete My Account',
  'delete_account_title': 'Delete Account',
  'delete_account_confirm': 'Your account and all data will be permanently deleted. This cannot be undone. Are you sure?',
  'delete_account_btn': 'Yes, Delete',

  // Risk score formula explanation
  'risk_score_formula_title': 'How Is the Risk Score Calculated?',
  'risk_score_formula_desc': 'The risk score is a composite earthquake risk index from 0-10, calculated by the AI model based on structural analysis findings.',
  'risk_score_factors': 'Factors Considered:',
  'factor_age': 'Building age and year of construction',
  'factor_floors': 'Number of floors and height',
  'factor_construction': 'Structural system type (reinforced concrete, masonry, steel)',
  'factor_concrete': 'Concrete quality and grade',
  'factor_damage': 'Severity of existing damage and cracks',
  'factor_seismic_zone': 'Seismic zone and soil conditions',
  'risk_score_ranges': 'Score Ranges:',
  'range_very_low': 'Very Low Risk',
  'range_low': 'Low Risk',
  'range_medium': 'Medium Risk',
  'range_high': 'High Risk',
  'range_very_high': 'Very High Risk',
  'risk_score_disclaimer': 'This score is for guidance only. A licensed civil engineer assessment is required for definitive decisions.',

  // Photo preview & delete
  'photo_preview': 'Photo',
  'delete_photo_title': 'Delete Photo',
  'delete_photo_confirm': 'Remove this photo from the list?',

  // File size errors
  'pdf_too_large': 'PDF file is too large ({size}MB). Maximum 10MB is supported.',
  'photo_too_large': 'Some photos exceeded the 5MB limit and were skipped: {files}',
  'photo_camera_too_large': 'Captured photo is too large ({size}MB). Maximum 5MB is supported.',

  // Analysis history error
  'history_load_error': 'Error loading analyses. Please try again.',

  // Building name input
  'building_name_label': 'Building Name (optional)',
  'building_name_hint': 'e.g., Home, Apartment, Office...',

  // Risk card labels
  'building_info': 'Building Information',
  'building_age_label': 'Building Age',
  'concrete_grade_label': 'Concrete Grade',
  'floor_count_label': 'Floor Count',
  'structure_type_label': 'Structure Type',
  'damage_severity_label': 'Damage Severity',
  'urgency_level_label': 'Urgency Level',
  'estimated_cost_label': 'Estimated Cost',
  'findings_title': 'Findings',
  'engineer_advice_title': 'Engineer Advice',
  'tap_to_zoom': 'Tap to zoom',
  'photo_label': 'Photo',

  // Loading overlay steps
  'loading_please_wait': 'Please wait...',
  'loading_step_files': 'Reading files...',
  'loading_step_ai': 'AI analysis in progress...',
  'loading_step_saving': 'Saving results...',
  'cancel_analysis': 'Cancel',
  'analysis_cancelled': 'Analysis cancelled.',

  // Bottom navigation bar
  'nav_home': 'Home',
  'nav_history': 'History',
  'nav_map': 'Map',
  'nav_info': 'Info',

  // Demo mode
  'demo_try': 'Try with Demo',

  // Quota exceeded — clean message
  'quota_exceeded_message':
      'Daily analysis limit reached. Please try again in a few hours.',

  // Photo guide content
  'guide_title': 'Photo Shooting Guide',
  'guide_subtitle': 'Enhance AI analysis with the right photos',
  'guide_prev': 'Previous',
  'guide_next': 'Next',
  'guide_start': "Got It, Let's Start",
  // Step 1: Exterior Facade
  'guide_s1_title': 'Exterior Facade',
  'guide_s1_sub': 'Take full facade photos from all four sides',
  'guide_s1_m1': 'Make sure the entire building fits in the frame',
  'guide_s1_m2': 'Shoot from at least 2 different angles (front and side)',
  'guide_s1_m3': 'Make cracks, spalling, or tilt visible',
  'guide_s1_m4': 'Shoot in the morning or on cloudy days (less shadow)',
  'guide_s1_m5': 'Avoid using zoom, step back instead',
  'guide_s1_tip': "💡 If the whole building doesn't fit, step back a bit.",
  // Step 2: Foundation & Columns
  'guide_s2_title': 'Foundation & Columns',
  'guide_s2_sub': 'Photograph structural load-bearing elements up close',
  'guide_s2_m1': 'Capture the top and bottom joints of columns',
  'guide_s2_m2': 'Photograph visible cracks from 30-50 cm',
  'guide_s2_m3': 'Take close-up shots of rust stains or concrete spalling',
  'guide_s2_m4': 'Pay special attention to corner columns',
  'guide_s2_m5': 'Be sure to photograph the foundation in the basement',
  'guide_s2_tip': '💡 Use a flashlight or phone flash to illuminate dark corners.',
  // Step 3: Interior
  'guide_s3_title': 'Interior',
  'guide_s3_sub': 'Record wall, ceiling, and floor surfaces',
  'guide_s3_m1': 'Capture the ceiling-wall junction from a corner of each room',
  'guide_s3_m2': 'Document cracks around doors and windows',
  'guide_s3_m3': 'Photograph stains or sagging in ceiling plaster',
  'guide_s3_m4': 'Check for slope or subsidence in the floor',
  'guide_s3_m5': 'Capture moisture signs in wet areas (bathroom, kitchen)',
  'guide_s3_tip': '💡 Use flash; brighter photos improve AI analysis accuracy.',
  // Step 4: Stairs & Corridors
  'guide_s4_title': 'Stairs & Corridors',
  'guide_s4_sub': 'Document damage in common areas',
  'guide_s4_m1': 'Photograph the side wall of staircase steps from top to bottom',
  'guide_s4_m2': 'Document cracks running along the corridor',
  'guide_s4_m3': 'Check the area around the elevator shaft (if any)',
  'guide_s4_m4': 'Document the fire escape or exit route',
  'guide_s4_m5': 'Take wide-angle shots that give an overview of the building',
  'guide_s4_tip': '💡 Tap the camera to lock focus on the crack.',
  // Step 5: Final Checks
  'guide_s5_title': 'Final Checks',
  'guide_s5_sub': 'Verify your photo set before uploading',
  'guide_s5_m1': 'Upload at least 4–6 photos (too few may be insufficient)',
  'guide_s5_m2': 'Make sure each photo is sharp and in focus; delete blurry ones',
  'guide_s5_m3': 'Reshoot dark or overexposed photos',
  'guide_s5_m4': 'Cover different areas (exterior, interior, columns, ceiling)',
  'guide_s5_m5': 'Size limit: maximum 5 MB per photo',
  'guide_s5_tip': "✅ If you're ready, close this screen and upload your photos.",
};

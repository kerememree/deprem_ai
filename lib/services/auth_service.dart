import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/exceptions/app_exceptions.dart';

/// Authentication servisi - Firebase Authentication kullanıyor
/// Backward compatible: Firebase yoksa SharedPreferences'a geri döner
class AuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isGuestKey = 'is_guest';

  /// Google ile giriş yap
  static Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Mevcut oturumu temizle (her seferinde hesap seçimi göster)
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException(
          'Google girişi iptal edildi',
          code: 'GOOGLE_CANCELLED',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthException(
          'Google ile giriş başarısız oldu',
          code: 'GOOGLE_SIGN_IN_FAILED',
        );
      }

      // SharedPreferences'a kaydet (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userEmailKey, userCredential.user?.email ?? '');
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setBool(_isGuestKey, false);
      final displayName = userCredential.user?.displayName ??
          userCredential.user?.email?.split('@')[0] ??
          'Kullanıcı';
      await prefs.setString(_userNameKey, displayName);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      String userMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          userMessage =
              'Bu email başka bir giriş yöntemiyle kayıtlı. Email/şifre ile deneyin.';
          break;
        case 'network-request-failed':
          userMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
          break;
        default:
          userMessage =
              'Google ile giriş yapılırken hata oluştu: ${e.message ?? "Bilinmeyen hata"}';
      }
      throw AuthException(
        userMessage,
        code: 'GOOGLE_SIGN_IN_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Google ile giriş yapılırken hata oluştu: ${e.toString()}',
        code: 'GOOGLE_SIGN_IN_ERROR',
        originalError: e,
      );
    }
  }

  /// Kullanıcı giriş yap (Firebase Authentication ile)
  static Future<void> login(String email, String password) async {
    try {
      // Validasyon
      if (email.isEmpty) {
        throw AuthException(
          'Email boş olamaz',
          code: 'EMPTY_EMAIL',
        );
      }
      
      if (password.isEmpty) {
        throw AuthException(
          'Şifre boş olamaz',
          code: 'EMPTY_PASSWORD',
        );
      }
      
      if (password.length < 6) {
        throw AuthException(
          'Şifre en az 6 karakter olmalıdır',
          code: 'WEAK_PASSWORD',
        );
      }
      
      if (!email.contains('@')) {
        throw AuthException(
          'Geçerli bir email adresi giriniz',
          code: 'INVALID_EMAIL',
        );
      }

      // Firebase Authentication ile giriş yap
      try {
        final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (userCredential.user == null) {
          throw AuthException(
            'Giriş başarısız oldu',
            code: 'LOGIN_FAILED',
          );
        }

        // Kullanıcı bilgilerini SharedPreferences'a da kaydet (backward compatibility)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userEmailKey, email);
        await prefs.setBool(_isLoggedInKey, true);
        
        // Kullanıcı adını Firebase'den veya email'den al
        final displayName = userCredential.user?.displayName ?? email.split('@')[0];
        await prefs.setString(_userNameKey, displayName);

      } on FirebaseAuthException catch (e) {
        // Firebase auth hatalarını yakala ve kullanıcı dostu mesajlara dönüştür
        String userMessage;
        String code;
        
        switch (e.code) {
          case 'user-not-found':
            userMessage = 'Bu email adresine kayıtlı kullanıcı bulunamadı';
            code = 'USER_NOT_FOUND';
            break;
          case 'wrong-password':
            userMessage = 'Şifre yanlış';
            code = 'WRONG_PASSWORD';
            break;
          case 'invalid-email':
            userMessage = 'Geçersiz email formatı';
            code = 'INVALID_EMAIL';
            break;
          case 'user-disabled':
            userMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış';
            code = 'USER_DISABLED';
            break;
          case 'too-many-requests':
            userMessage = 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin';
            code = 'TOO_MANY_REQUESTS';
            break;
          case 'network-request-failed':
            userMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin';
            code = 'NETWORK_ERROR';
            break;
          default:
            userMessage = 'Giriş yapılırken hata oluştu: ${e.message ?? "Bilinmeyen hata"}';
            code = 'LOGIN_ERROR';
        }
        
        throw AuthException(
          userMessage,
          code: code,
          originalError: e,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Giriş yapılırken hata oluştu: ${e.toString()}',
        code: 'LOGIN_ERROR',
        originalError: e,
      );
    }
  }

  /// Kullanıcı kayıt ol (Firebase Authentication ile)
  static Future<void> register(String email, String password, String name) async {
    try {
      // Validasyon
      if (name.isEmpty) {
        throw AuthException(
          'Ad soyad boş olamaz',
          code: 'EMPTY_NAME',
        );
      }
      
      if (email.isEmpty) {
        throw AuthException(
          'Email boş olamaz',
          code: 'EMPTY_EMAIL',
        );
      }
      
      if (!email.contains('@')) {
        throw AuthException(
          'Geçerli bir email adresi giriniz',
          code: 'INVALID_EMAIL',
        );
      }
      
      if (password.isEmpty) {
        throw AuthException(
          'Şifre boş olamaz',
          code: 'EMPTY_PASSWORD',
        );
      }
      
      if (password.length < 6) {
        throw AuthException(
          'Şifre en az 6 karakter olmalıdır',
          code: 'WEAK_PASSWORD',
        );
      }

      // Firebase Authentication ile kayıt ol
      try {
        final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        if (userCredential.user == null) {
          throw AuthException(
            'Kayıt başarısız oldu',
            code: 'REGISTER_FAILED',
          );
        }

        // Kullanıcı profilini güncelle (display name)
        await userCredential.user?.updateDisplayName(name);
        await userCredential.user?.reload();
        
        // Email doğrulama gönder (opsiyonel - kullanıcı daha sonra doğrulayabilir)
        try {
          await userCredential.user?.sendEmailVerification();
        } catch (e) {
          // Email doğrulama gönderme hatası kritik değil
          debugPrint('Email doğrulama gönderilemedi: $e');
        }

        // Kullanıcı bilgilerini SharedPreferences'a da kaydet (backward compatibility)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userEmailKey, email);
        await prefs.setString(_userNameKey, name);
        await prefs.setBool(_isLoggedInKey, true);

      } on FirebaseAuthException catch (e) {
        // Firebase auth hatalarını yakala ve kullanıcı dostu mesajlara dönüştür
        String userMessage;
        String code;
        
        switch (e.code) {
          case 'email-already-in-use':
            userMessage = 'Bu email adresi zaten kullanılıyor';
            code = 'EMAIL_ALREADY_IN_USE';
            break;
          case 'invalid-email':
            userMessage = 'Geçersiz email formatı';
            code = 'INVALID_EMAIL';
            break;
          case 'weak-password':
            userMessage = 'Şifre çok zayıf. En az 6 karakter olmalıdır';
            code = 'WEAK_PASSWORD';
            break;
          case 'network-request-failed':
            userMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin';
            code = 'NETWORK_ERROR';
            break;
          default:
            userMessage = 'Kayıt olurken hata oluştu: ${e.message ?? "Bilinmeyen hata"}';
            code = 'REGISTER_ERROR';
        }
        
        throw AuthException(
          userMessage,
          code: code,
          originalError: e,
        );
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Kayıt olurken hata oluştu: ${e.toString()}',
        code: 'REGISTER_ERROR',
        originalError: e,
      );
    }
  }

  /// Kullanıcı çıkış yap
  static Future<void> logout() async {
    try {
      // Anonim hesap ise sil (Firebase'de gereksiz hesap birikmesin)
      final user = _firebaseAuth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await user.delete();
        } catch (_) {
          // Silme başarısız olsa da devam et
        }
      }

      // Firebase'den çıkış yap
      await _firebaseAuth.signOut();
      
      // SharedPreferences'dan da temizle (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_isGuestKey);
    } catch (e) {
      debugPrint('Logout hatası: $e');
      // Hata olsa bile SharedPreferences'ı temizle
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, false);
      } catch (_) {}
    }
  }

  /// Kullanıcı giriş yapmış mı?
  static Future<bool> isLoggedIn() async {
    try {
      // Firebase'den kontrol et
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        return true;
      }
      
      // Firebase'de yoksa SharedPreferences'a bak (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      // Hata durumunda SharedPreferences'a bak
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_isLoggedInKey) ?? false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Kullanıcı email'ini al
  static Future<String?> getUserEmail() async {
    try {
      // Firebase'den al
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser?.email != null) {
        return currentUser!.email;
      }
      
      // Firebase'de yoksa SharedPreferences'a bak (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      // Hata durumunda SharedPreferences'a bak
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_userEmailKey);
      } catch (_) {
        return null;
      }
    }
  }

  /// Kullanıcı adını al
  static Future<String?> getUserName() async {
    try {
      // Firebase'den al
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser?.displayName != null) {
        return currentUser!.displayName;
      }
      
      // Email'den kullanıcı adını çıkar
      if (currentUser?.email != null) {
        return currentUser!.email!.split('@')[0];
      }
      
      // Firebase'de yoksa SharedPreferences'a bak (backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey);
    } catch (e) {
      // Hata durumunda SharedPreferences'a bak
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_userNameKey);
      } catch (_) {
        return null;
      }
    }
  }

  /// Misafir olarak giriş yap — Firebase Anonymous Auth kullanır
  static Future<void> loginAsGuest() async {
    try {
      // Firebase Anonymous Auth ile oturum aç (kalıcı, cihazlar arası tutarsız olmaz)
      final userCredential = await _firebaseAuth.signInAnonymously();

      if (userCredential.user == null) {
        throw AuthException(
          'Misafir girişi başarısız oldu',
          code: 'ANONYMOUS_SIGN_IN_FAILED',
        );
      }

      // SharedPreferences'a misafir bayrağını da kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setBool(_isGuestKey, true);
      await prefs.setString(_userNameKey, 'Misafir');
    } on FirebaseAuthException catch (e) {
      String userMessage;
      switch (e.code) {
        case 'operation-not-allowed':
          userMessage =
              'Misafir girişi şu an kullanılamıyor. Lütfen kayıt olun.';
          break;
        case 'network-request-failed':
          userMessage =
              'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
          break;
        default:
          userMessage =
              'Misafir girişi başarısız: ${e.message ?? "Bilinmeyen hata"}';
      }
      throw AuthException(
        userMessage,
        code: 'GUEST_LOGIN_ERROR',
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Misafir girişi başarısız: ${e.toString()}',
        code: 'GUEST_LOGIN_ERROR',
        originalError: e,
      );
    }
  }

  /// Misafir kullanıcı mı?
  static Future<bool> isGuest() async {
    try {
      // Firebase Anonymous kullanıcısı mı?
      final user = _firebaseAuth.currentUser;
      if (user != null && user.isAnonymous) return true;
      // Backward compat: SharedPreferences kontrolü
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isGuestKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hesabı kalıcı olarak sil
  static Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException(
          'Kullanıcı giriş yapmamış',
          code: 'USER_NOT_LOGGED_IN',
        );
      }
      await user.delete();
      // SharedPreferences temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_isGuestKey);
    } on FirebaseAuthException catch (e) {
      String userMessage;
      String code;
      switch (e.code) {
        case 'requires-recent-login':
          userMessage = 'Güvenlik için lütfen önce çıkış yapıp tekrar giriş yapın, sonra hesabı silin.';
          code = 'REQUIRES_RECENT_LOGIN';
          break;
        case 'network-request-failed':
          userMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
          code = 'NETWORK_ERROR';
          break;
        default:
          userMessage = 'Hesap silinirken hata oluştu: ${e.message ?? "Bilinmeyen hata"}';
          code = 'DELETE_ACCOUNT_ERROR';
      }
      throw AuthException(userMessage, code: code, originalError: e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Hesap silinirken hata oluştu: ${e.toString()}',
        code: 'DELETE_ACCOUNT_ERROR',
        originalError: e,
      );
    }
  }

  /// Mevcut Firebase kullanıcısını al
  static User? getCurrentUser() {
    try {
      return _firebaseAuth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Email doğrulama durumunu kontrol et
  static Future<bool> isEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload(); // En güncel bilgiyi al
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Email doğrulama linki gönder
  static Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException(
          'Kullanıcı giriş yapmamış',
          code: 'USER_NOT_LOGGED_IN',
        );
      }

      if (user.emailVerified) {
        throw AuthException(
          'Email zaten doğrulanmış',
          code: 'EMAIL_ALREADY_VERIFIED',
        );
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      String userMessage;
      String code;
      
      switch (e.code) {
        case 'too-many-requests':
          userMessage = 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin';
          code = 'TOO_MANY_REQUESTS';
          break;
        case 'network-request-failed':
          userMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin';
          code = 'NETWORK_ERROR';
          break;
        default:
          userMessage = 'Email doğrulama linki gönderilirken hata oluştu: ${e.message ?? "Bilinmeyen hata"}';
          code = 'EMAIL_VERIFICATION_ERROR';
      }
      
      throw AuthException(
        userMessage,
        code: code,
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Email doğrulama linki gönderilirken hata oluştu: ${e.toString()}',
        code: 'EMAIL_VERIFICATION_ERROR',
        originalError: e,
      );
    }
  }

  /// Şifre sıfırlama email'i gönder
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw AuthException(
          'Email boş olamaz',
          code: 'EMPTY_EMAIL',
        );
      }
      
      if (!email.contains('@')) {
        throw AuthException(
          'Geçerli bir email adresi giriniz',
          code: 'INVALID_EMAIL',
        );
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      String userMessage;
      String code;
      
      switch (e.code) {
        case 'user-not-found':
          userMessage = 'Bu email adresine kayıtlı kullanıcı bulunamadı';
          code = 'USER_NOT_FOUND';
          break;
        case 'invalid-email':
          userMessage = 'Geçersiz email formatı';
          code = 'INVALID_EMAIL';
          break;
        case 'network-request-failed':
          userMessage = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin';
          code = 'NETWORK_ERROR';
          break;
        default:
          userMessage = 'Şifre sıfırlama email\'i gönderilirken hata oluştu: ${e.message ?? "Bilinmeyen hata"}';
          code = 'PASSWORD_RESET_ERROR';
      }
      
      throw AuthException(
        userMessage,
        code: code,
        originalError: e,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'Şifre sıfırlama email\'i gönderilirken hata oluştu: ${e.toString()}',
        code: 'PASSWORD_RESET_ERROR',
        originalError: e,
      );
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';
import 'package:toba_vision_mobile/services/offline_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mendapatkan user aktif saat ini dari Firebase
  static User? get currentUser => _auth.currentUser;

  /// Helper: Mengonversi Nama / Username menjadi Virtual Email untuk Firebase Auth
  /// Contoh: "Slamet Raharjo" -> "slametraharjo@tobavision.local"
  static String _toVirtualEmail(String username) {
    final clean = username
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Hapus spasi & karakter simbol
    return '$clean@tobavision.local';
  }

  // ==========================================
  // 1. REGISTRASI PETANI BARU + SYNC PROFIL
  // ==========================================
  static Future<void> registerPetani({
    required String password,
    required String nama,
    required String alamatLahan,
    String noTelepon = "",
    double luasLahan = 0.0,
  }) async {
    try {
      final exactName = nama.trim();
      final virtualEmail = _toVirtualEmail(exactName);

      // Validasi jika nama hanya berisi simbol/kosong
      if (virtualEmail.startsWith('@')) {
        throw Exception("Nama petani harus mengandung huruf atau angka.");
      }

      // Buat user di Firebase Auth menggunakan virtual email
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: virtualEmail,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Simpan penulisan nama persis (case-sensitive) ke Firebase DisplayName
        await user.updateDisplayName(exactName);

        // Sync profil ke Firestore via Backend FastAPI
        await ApiService.syncPetaniProfile(
          uid: user.uid,
          nama: exactName,
          alamatLahan: alamatLahan.trim(),
          noTelepon: noTelepon,
          luasLahan: luasLahan,
        );

        // Simpan sesi ke Hive untuk offline access
        await OfflineService.saveUserSession(
          uid: user.uid,
          nama: exactName,
          email: virtualEmail,
          alamatLahan: alamatLahan.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==========================================
  // 2. LOGIN PETANI (STRICT CASE-SENSITIVE USERNAME)
  // ==========================================
  static Future<void> loginPetani({
    required String username,
    required String password,
  }) async {
    try {
      final inputName = username.trim();
      final virtualEmail = _toVirtualEmail(inputName);

      if (virtualEmail.startsWith('@')) {
        throw Exception("Masukkan nama atau username petani yang valid.");
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: virtualEmail,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // 1. Ambil profil terbaru dari Cloud Firestore via FastAPI
        final cloudProfile = await ApiService.getPetaniProfile(user.uid);
        final localData = OfflineService.getUserData();

        // 2. Tentukan nama asli terdaftar (Cloud Firestore -> Firebase DisplayName -> Cache Lokal)
        String? registeredName;
        if (cloudProfile?['nama']?.toString().trim().isNotEmpty ?? false) {
          registeredName = cloudProfile!['nama'].toString().trim();
        } else if (user.displayName?.trim().isNotEmpty ?? false) {
          registeredName = user.displayName!.trim();
        } else if (localData['uid'] == user.uid &&
            (localData['nama']?.toString().trim().isNotEmpty ?? false)) {
          registeredName = localData['nama'].toString().trim();
        }

        // 3. VALIDASI STRICT CASE-SENSITIVE:
        // Setiap huruf kapital dan spasi harus 100% identik dengan nama terdaftar
        if (registeredName != null && registeredName != inputName) {
          await _auth.signOut();
          throw Exception(
            'Penulisan nama/username tidak sesuai (perhatikan huruf besar/kecil dan spasi).',
          );
        }

        final finalName = registeredName ?? inputName;

        // 4. Prioritaskan alamat_lahan dari Cloud -> Cache lokal Hive -> Default
        final alamatLahan =
            (cloudProfile?['alamat_lahan']?.toString().trim().isNotEmpty ?? false)
                ? cloudProfile!['alamat_lahan'].toString().trim()
                : (localData['uid'] == user.uid &&
                        (localData['alamat_lahan']?.toString().isNotEmpty ?? false))
                    ? localData['alamat_lahan'].toString()
                    : "Lokasi Kebun Terdaftar";

        // 5. Simpan sesi login terbaru ke Hive
        await OfflineService.saveUserSession(
          uid: user.uid,
          nama: finalName,
          email: user.email ?? virtualEmail,
          alamatLahan: alamatLahan,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ==========================================
  // 3. LOGOUT
  // ==========================================
  static Future<void> logout() async {
    await _auth.signOut();
    await OfflineService.logoutUser();
  }

  // Handling pesan error ramah pengguna (disesuaikan ke konteks Nama/Username)
  static String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Nama petani ini sudah terdaftar. Gunakan nama lain (misal tambahkan nama desa/blok) atau langsung masuk.';
      case 'invalid-email':
        return 'Format nama/username tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Minimal 6 karakter.';
      case 'user-not-found':
        return 'Akun petani tidak ditemukan. Periksa kembali penulisan nama Anda.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Nama petani atau kata sandi yang Anda masukkan salah.';
      default:
        return 'Terjadi kesalahan autentikasi ($code).';
    }
  }
}
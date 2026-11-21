import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ==========================================
  // KONFIGURASI ENVIRONMENT & URL
  // ==========================================

  // 1. Ganti URL di bawah ini dengan URL hasil perintah 'cloudflared tunnel' Anda
  // Ganti dengan IP lokal laptop kamu + port FastAPI (:8000)
  static const String _devTunnelUrl = "http://10.132.13.25:8000";

  // 2. URL Server Cloud Production (Saat Aplikasi Rilis)
  static const String _prodServerUrl = "https://api-tobavision.onrender.com";

  // 3. Membaca Environment dari Command Line --dart-define=ENV=prod (Default: 'dev')
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // OTOMATIS: Penentuan Base URL sesuai environment dan platform perangkat
  static String get baseUrl {
    // Mode Production jika dikirim parameter --dart-define=ENV=prod ATAU mode release apk
    if (_env == 'prod' || (_env == 'dev' && kReleaseMode)) {
      return _prodServerUrl;
    }

    // Mode Development / Testing Lokal
    if (kIsWeb) {
      return "http://localhost:8000";
    } else if (Platform.isAndroid) {
      // Jika di-run di Emulator gunakan IP 10.0.2.2, jika HP Fisik gunakan Cloudflare Tunnel
      return _isEmulator ? "http://10.0.2.2:8000" : _devTunnelUrl;
    } else if (Platform.isIOS) {
      return "http://127.0.0.1:8000";
    } else {
      return "http://localhost:8000";
    }
  }

  // Helper pendeteksi Android Emulator
  static bool get _isEmulator {
    return !kIsWeb &&
        Platform.isAndroid &&
        (Platform.environment.containsKey('ANDROID_EMULATOR') || true);
  }

  // Header Standar Request JSON
  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  // ==========================================
  // 1. ROOT CHECK (STATUS SERVER)
  // ==========================================
  static Future<dynamic> checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Server merespon dengan status: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Gagal terhubung ke backend FastAPI: $e");
    }
  }

  // ==========================================
  // 2. AUTHENTICATION (SYNC PROFIL PETANI)
  // ==========================================
  static Future<dynamic> syncPetaniProfile({
    required String uid,
    required String nama,
    String alamatLahan = "",
    String noTelepon = "",
    double luasLahan = 0.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/petani/sync-profile'),
        headers: _headers,
        body: jsonEncode({
          "uid": uid,
          "nama": nama,
          "alamat_lahan": alamatLahan,
          "no_telepon": noTelepon,
          "luas_lahan": luasLahan,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal sync profil petani");
      }
    } catch (e) {
      throw Exception("Gagal melakukan sync profil: $e");
    }
  }

  static Future<Map<String, dynamic>?> getPetaniProfile(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/petani/$uid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null; // Fallback aman ke data lokal Hive jika offline
    }
  }

  // ==========================================
  // 3. DETEKSI AI DAUN TEMBAKAU (YOLO + CLOUDINARY)
  // ==========================================
  static Future<dynamic> predictTobaccoGrade({
    required XFile imageFile,
    String idPetani = "guest_petani",
    String? idPetikan,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/predict'),
      );

      // Membaca gambar sebagai bytes agar berjalan mulus di Web, Android, & iOS
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.name.isNotEmpty ? imageFile.name : 'daun_tembakau.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      request.fields['id_petani'] = idPetani;
      if (idPetikan != null && idPetikan.isNotEmpty) {
        request.fields['id_petikan'] = idPetikan;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal memproses prediksi AI");
      }
    } catch (e) {
      throw Exception("Gagal terhubung ke endpoint prediksi: $e");
    }
  }
  // ==========================================
  // 4. WEATHER API INTEGRATION
  // ==========================================
  static Future<dynamic> getWeather({String location = "Temanggung"}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/weather?location=$location'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal mengambil data cuaca");
      }
    } catch (e) {
      throw Exception("Gagal memuat data cuaca: $e");
    }
  }

  // ==========================================
  // 5. PANEN (SIMPAN PETIKAN & AMBIL REKAP)
  // ==========================================
  static Future<dynamic> simpanPetikanPanen({
    required String idSiklus,
    required int petikanKe,
    required double beratKg,
    required double totalPendapatan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/panen/petikan'),
        headers: _headers,
        body: jsonEncode({
          "id_siklus": idSiklus,
          "petikan_ke": petikanKe,
          "berat_kg": beratKg,
          "total_pendapatan": totalPendapatan,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal menyimpan catatan panen");
      }
    } catch (e) {
      throw Exception("Gagal menyimpan panen: $e");
    }
  }

  static Future<dynamic> getRekapPanen(String idSiklus) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/panen/$idSiklus'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal mengambil rekap panen");
      }
    } catch (e) {
      throw Exception("Gagal memuat data panen: $e");
    }
  }

  // ==========================================
  // 6. FINANSIAL (BIAYA OPERASIONAL)
  // ==========================================
  static Future<dynamic> tambahBiayaOperasional({
    required String idSiklus,
    required String namaPengeluaran,
    required String kategori,
    required double jumlahBiaya,
    String keterangan = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/finansial/biaya'),
        headers: _headers,
        body: jsonEncode({
          "id_siklus": idSiklus,
          "nama_pengeluaran": namaPengeluaran,
          "kategori": kategori,
          "jumlah_biaya": jumlahBiaya,
          "keterangan": keterangan,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ?? "Gagal menyimpan biaya operasional",
        );
      }
    } catch (e) {
      throw Exception("Gagal menyimpan biaya: $e");
    }
  }

  static Future<dynamic> getRekapFinansial(String idSiklus) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/finansial/$idSiklus'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ?? "Gagal mengambil rekap finansial",
        );
      }
    } catch (e) {
      throw Exception("Gagal memuat data finansial: $e");
    }
  }

  // ==========================================
  // 7. BATCH SYNC DATA OFFLINE (HIVE TO FIRESTORE)
  // ==========================================
  static Future<dynamic> syncOfflineData({
    required String idSiklus,
    required List<dynamic> listPetikan,
    required List<dynamic> listBiaya,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/offline-data'),
        headers: _headers,
        body: jsonEncode({
          "id_siklus": idSiklus,
          "list_petikan": listPetikan,
          "list_biaya": listBiaya,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ?? "Gagal melakukan sync data offline",
        );
      }
    } catch (e) {
      throw Exception("Gagal melakukan batch sync: $e");
    }
  }

  static Future<Object?> updateSiklusStatus({
    required String idSiklus,
    required String status,
  }) async {
    return null;
  }

  static Future<dynamic> tutupSiklusPanen(
    String idSiklus, {
    required Map<String, dynamic> archivePayload,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/siklus/$idSiklus/tutup'),
        headers: _headers,
        body: jsonEncode(archivePayload),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['detail'] ?? "Gagal menutup siklus dan mengarsipkan ke server",
        );
      }
    } catch (e) {
      debugPrint("Gagal menutup siklus di server: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getArsipMusimPetani(
    String uidPetani,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/arsip-musim/$uidPetani'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list = decoded['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Gagal mengambil arsip musim dari server: $e");
      return [];
    }
  }
}

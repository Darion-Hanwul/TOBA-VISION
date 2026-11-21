import 'dart:core';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineService {
  static const String _userBoxName = 'user_box';
  static const String _panenBoxName = 'offline_panen_box';
  static const String _biayaBoxName = 'offline_biaya_box';

  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(_userBoxName);
    await Hive.openBox(_panenBoxName);
    await Hive.openBox(_biayaBoxName);
  }

  // ==========================================
  // 1. AUTENTIKASI & SESI LOGIN OFFLINE
  // ==========================================
  static final Box _userBox = Hive.box(_userBoxName);

  static Future<void> saveUserSession({
    required String uid,
    required String nama,
    required String email,
    required String alamatLahan,
  }) async {
    await _userBox.put('isLoggedIn', true);
    await _userBox.put('uid', uid);
    await _userBox.put('nama', nama);
    await _userBox.put('email', email);
    await _userBox.put('alamat_lahan', alamatLahan);
  }

  static bool isLoggedIn() {
    return _userBox.get('isLoggedIn', defaultValue: false);
  }

  static Map<String, dynamic> getUserData() {
    return {
      'uid': _userBox.get('uid', defaultValue: ''),
      'nama': _userBox.get('nama', defaultValue: 'Petani Toba'),
      'email': _userBox.get('email', defaultValue: ''),
      'alamat_lahan': _userBox.get('alamat_lahan', defaultValue: 'Temanggung, Jateng'),
    };
  }

  static Future<void> logoutUser() async {
    await _userBox.clear();
  }

  // ==========================================
  // 2. ANTREAN PANEN OFFLINE
  // ==========================================
  static final Box _panenBox = Hive.box(_panenBoxName);

  static Future<void> savePanenOffline(Map<String, dynamic> dataPanen) async {
    await _panenBox.add(dataPanen);
  }

  static List<dynamic> getOfflinePanenList() {
    return _panenBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearPanenQueue() async {
    await _panenBox.clear();
  }

  // ==========================================
  // 3. ANTREAN BIAYA OFFLINE
  // ==========================================
  static final Box _biayaBox = Hive.box(_biayaBoxName);

  static Future<void> saveBiayaOffline(Map<String, dynamic> dataBiaya) async {
    await _biayaBox.add(dataBiaya);
  }

  static List<dynamic> getOfflineBiayaList() {
    return _biayaBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearBiayaQueue() async {
    await _biayaBox.clear();
  }
}
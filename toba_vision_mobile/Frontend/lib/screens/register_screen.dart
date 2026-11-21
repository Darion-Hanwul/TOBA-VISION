import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _userEditedAddress = false;

  @override
  void initState() {
    super.initState();
    _autoFillCurrentAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // DETEKSI ALAMAT SAAT INI OTOMATIS (GPS + REVERSE GEOCODING)
  // ==========================================
  Future<void> _autoFillCurrentAddress({bool forceOverwrite = false}) async {
    if (_isFetchingLocation) return;

    setState(() => _isFetchingLocation = true);
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      // Tampilkan cache lokasi jika ada sambil menunggu GPS terbaru
      if (!forceOverwrite && !_userEditedAddress && _addressController.text.trim().isEmpty) {
        final cached = box.get('current_user_location')?.toString();
        if (cached != null && cached.isNotEmpty) {
          _addressController.text = cached;
        }
      }

      double? lat;
      double? lon;

      try {
        if (!kIsWeb) {
          final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            throw Exception('Location service disabled');
          }
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }

        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (gpsError) {
        debugPrint('GPS fallback ke lokasi jaringan di Register: $gpsError');
        final ipRes = await http
            .get(Uri.parse('https://ipapi.co/json/'))
            .timeout(const Duration(seconds: 5));
        if (ipRes.statusCode == 200) {
          final ipData = jsonDecode(ipRes.body);
          final String city = (ipData['city'] ?? '').toString();
          final String region = (ipData['region'] ?? '').toString();
          if (city.isNotEmpty) {
            final fallbackPlace = region.isNotEmpty ? '$city, $region' : city;
            await box.put('current_user_location', fallbackPlace);
            if (mounted && (forceOverwrite || !_userEditedAddress)) {
              setState(() => _addressController.text = fallbackPlace);
            }
            return;
          }
        }
      }

      if (lat != null && lon != null) {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&accept-language=id',
        );
        final response = await http.get(
          uri,
          headers: {'User-Agent': 'TobaVisionApp/1.0'},
        ).timeout(const Duration(seconds: 6));

        String resolvedPlace = '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final Map<String, dynamic> address =
              Map<String, dynamic>.from(data['address'] ?? {});

          final String? village = address['village'] ??
              address['suburb'] ??
              address['hamlet'] ??
              address['neighbourhood'];
          final String? district = address['city_district'] ??
              address['town'] ??
              address['municipality'];
          final String? city = address['city'] ??
              address['county'] ??
              address['regency'] ??
              address['state_district'];
          final String? state = address['state'];

          final parts = <String>[
            if (village != null && village.isNotEmpty) village,
            if (district != null && district.isNotEmpty && district != village) district,
            if (city != null && city.isNotEmpty) city,
            if (state != null && state.isNotEmpty) state,
          ];

          if (parts.isNotEmpty) {
            resolvedPlace = parts.join(', ');
          } else if (data['display_name'] != null) {
            resolvedPlace = data['display_name'].toString();
          }
        }

        await box.put('current_user_location', resolvedPlace);
        if (mounted && (forceOverwrite || !_userEditedAddress)) {
          setState(() {
            _addressController.text = resolvedPlace;
            if (forceOverwrite) _userEditedAddress = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal mendeteksi alamat otomatis saat registrasi: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  // ==========================================
  // LOGIKA REGISTRASI PETANI BARU (TANPA EMAIL)
  // ==========================================
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || address.isEmpty || password.isEmpty) {
      _showSnackBar('Mohon lengkapi seluruh kolom pendaftaran.', Colors.orange);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Kata sandi dan konfirmasi tidak cocok.', Colors.orange);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Kata sandi minimal 6 karakter.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.registerPetani(
        password: password,
        nama: name,
        alamatLahan: address,
      );

      // Simpan alamat terpilih ke cache lokasi agar selaras dengan Beranda
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');
      await box.put('current_user_location', address);

      if (!mounted) return;

      _showSnackBar('Registrasi berhasil! Selamat datang di Toba Vision.', const Color(0xFF004C22));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Shell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: kSerif)),
        backgroundColor: bgColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input 1: Nama Lengkap / Username Login
                    _buildFieldLabel(
                      icon: Icons.person_rounded,
                      label: 'Nama Lengkap Petani (Untuk Masuk)',
                    ),
                    const SizedBox(height: 6),
                    _buildInputCard(
                      child: TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 16,
                          color: Color(0xFF191C1E),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Contoh: Slamet Raharjo',
                          hintStyle: TextStyle(
                            fontFamily: kSerif,
                            fontSize: 16,
                            color: Color(0xFF707A6F),
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: Color(0xFF707A6F),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input 2: Alamat Lahan / Lokasi Kebun (Otomatis GPS + Bisa Diedit Manual)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildFieldLabel(
                            icon: Icons.location_on_rounded,
                            label: 'Alamat Lahan / Lokasi Kebun',
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFF004C22),
                          ),
                          onPressed: _isFetchingLocation
                              ? null
                              : () => _autoFillCurrentAddress(forceOverwrite: true),
                          icon: _isFetchingLocation
                              ? const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF004C22),
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 15),
                          label: Text(
                            _isFetchingLocation ? 'Mendeteksi...' : 'Deteksi GPS',
                            style: const TextStyle(
                              fontFamily: kSerif,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildInputCard(
                      child: TextField(
                        controller: _addressController,
                        minLines: 2,
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _userEditedAddress = true,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 16,
                          color: Color(0xFF191C1E),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isFetchingLocation
                              ? 'Mendeteksi lokasi perangkat saat ini...'
                              : 'Nama desa, dusun, atau blok lahan kebun tembakau',
                          hintStyle: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 16,
                            color: Color(0xFF707A6F),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Color(0xFF707A6F),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Color(0xFF9B4500),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Terisi otomatis sesuai lokasi saat ini, silakan ubah manual jika perlu',
                              style: TextStyle(
                                fontFamily: kSerif,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                color: Color(0xFF404940),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input 3: Kata Sandi
                    _buildFieldLabel(
                      icon: Icons.lock_rounded,
                      label: 'Kata Sandi',
                    ),
                    const SizedBox(height: 6),
                    _buildInputCard(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 16,
                          color: Color(0xFF191C1E),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Buat kata sandi akun (min. 6 karakter)',
                          hintStyle: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 16,
                            color: Color(0xFF707A6F),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: Color(0xFF707A6F),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF707A6F),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            tooltip: 'Tampilkan atau sembunyikan kata sandi',
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input 4: Konfirmasi Kata Sandi
                    _buildFieldLabel(
                      icon: Icons.lock_reset_rounded,
                      label: 'Konfirmasi Kata Sandi',
                    ),
                    const SizedBox(height: 6),
                    _buildInputCard(
                      child: TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _isLoading ? null : _handleRegister(),
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 16,
                          color: Color(0xFF191C1E),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ulangi kata sandi',
                          hintStyle: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 16,
                            color: Color(0xFF707A6F),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: Color(0xFF707A6F),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF707A6F),
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirm = !_obscureConfirm);
                            },
                            tooltip: 'Tampilkan atau sembunyikan kata sandi',
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security & Offline Sync Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEEF0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0x1A004C22),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 15,
                              color: Color(0xFF004C22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Data akun tersimpan aman dan terenkripsi di perangkat untuk akses tanpa sinyal.',
                              style: TextStyle(
                                fontFamily: kSerif,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                letterSpacing: 0.3,
                                color: Color(0xFF404940),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Action Button (Daftar Akun Sekarang)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF166534),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Daftar Akun Sekarang',
                                    style: TextStyle(
                                      fontFamily: kSerif,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Link Navigation Footer
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: TextStyle(
                              fontFamily: kSerif,
                              fontSize: 16,
                              color: Color(0xFF404940),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Masuk Sekarang',
                                  style: TextStyle(
                                    fontFamily: kSerif,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF004C22),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Color(0xFF004C22),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xCCF7F9FB),
        border: Border(
          bottom: BorderSide(
            color: Color(0x0D022C22),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF191C1E),
                ),
              ),
            ),
          ),
          const Text(
            'Daftar Akun Baru',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF004C22),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF004C22),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 9, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
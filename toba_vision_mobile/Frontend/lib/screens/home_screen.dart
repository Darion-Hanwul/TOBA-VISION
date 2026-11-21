import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../data/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import '../widgets/app_header.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _namaPetani = 'Petani Mitra';
  String _alamatTerdaftar = 'Lokasi Kebun Belum Diatur';
  String _currentLocationLabel = 'Mendeteksi lokasi...';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _initHomeData();
  }

  Future<void> _initHomeData() async {
    await _loadActivePetaniProfile();
    await _detectCurrentLocation();
  }

  String _dynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Future<void> _loadActivePetaniProfile() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final userData = OfflineService.getUserData();

      String nama = (userData['nama']?.toString().trim().isNotEmpty ?? false) &&
              userData['nama'] != 'Petani Toba'
          ? userData['nama'].toString().trim()
          : (firebaseUser?.displayName?.trim().isNotEmpty ?? false)
              ? firebaseUser!.displayName!.trim()
              : 'Petani Mitra';

      String alamat = (userData['alamat_lahan']?.toString().trim().isNotEmpty ?? false)
          ? userData['alamat_lahan'].toString().trim()
          : '';

      if (mounted) {
        setState(() {
          _namaPetani = nama;
          if (alamat.isNotEmpty) _alamatTerdaftar = alamat;
          _isLoadingProfile = false;
        });
      }

      if (firebaseUser != null) {
        final cloudProfile = await ApiService.getPetaniProfile(firebaseUser.uid);
        if (cloudProfile != null && mounted) {
          final cloudNama = cloudProfile['nama']?.toString().trim() ?? '';
          final cloudAlamat = cloudProfile['alamat_lahan']?.toString().trim() ?? '';
          setState(() {
            if (cloudNama.isNotEmpty) _namaPetani = cloudNama;
            if (cloudAlamat.isNotEmpty) _alamatTerdaftar = cloudAlamat;
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal memuat profil petani di Beranda: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _detectCurrentLocation() async {
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      final String? cachedLoc = box.get('current_user_location')?.toString();
      if (cachedLoc != null && cachedLoc.isNotEmpty && mounted) {
        setState(() => _currentLocationLabel = cachedLoc);
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
        debugPrint('GPS fallback ke lokasi jaringan di Beranda: $gpsError');
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
            if (mounted) setState(() => _currentLocationLabel = fallbackPlace);
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

        String resolvedPlace = '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}';

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final Map<String, dynamic> address =
              Map<String, dynamic>.from(data['address'] ?? {});

          final String? subDistrict = address['suburb'] ??
              address['village'] ??
              address['town'] ??
              address['municipality'];
          final String? city = address['city'] ??
              address['county'] ??
              address['regency'] ??
              address['state_district'];

          if (subDistrict != null && city != null) {
            resolvedPlace = '$subDistrict, $city';
          } else if (city != null) {
            resolvedPlace = city;
          } else if (subDistrict != null) {
            resolvedPlace = subDistrict;
          }
        }

        await box.put('current_user_location', resolvedPlace);
        if (mounted) setState(() => _currentLocationLabel = resolvedPlace);
      }
    } catch (e) {
      debugPrint('Gagal mendeteksi lokasi saat ini di Beranda: $e');
      if (mounted && _currentLocationLabel == 'Mendeteksi lokasi...') {
        setState(() {
          _currentLocationLabel = _alamatTerdaftar != 'Lokasi Kebun Belum Diatur'
              ? _alamatTerdaftar
              : 'Lokasi Saat Ini';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'TB-2026';
    final shortId = uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();

    final profile = UserProfile(
      name: _namaPetani,
      group: 'Mitra Petani Toba Vision',
      region: _alamatTerdaftar,
    );

    final String subtitleLocation =
        _currentLocationLabel != 'Mendeteksi lokasi...' && _currentLocationLabel != 'Lokasi Saat Ini'
            ? _currentLocationLabel
            : (_alamatTerdaftar != 'Lokasi Kebun Belum Diatur'
                ? _alamatTerdaftar
                : _currentLocationLabel);

    if (_isLoadingProfile) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            subtitle: subtitleLocation.toUpperCase(),
            padding: EdgeInsets.zero,
            height: null,
            logoSize: 44,
            useAppLogo: true,
            trailing: AppHeaderActionButton(
              icon: Icons.person_outline_rounded,
              onTap: () => _showProfileModal(context, profile, shortId, subtitleLocation),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_dynamicGreeting()}, ${profile.name}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.groups_outlined, size: 17, color: AppColors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${profile.group} • $subtitleLocation',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fitur Utama Lapangan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeatureGrid(onNavigate: widget.onNavigate),
          const SizedBox(height: 20),
          _AiBanner(onTap: () => widget.onNavigate(1)),
        ],
      ),
    );
  }

  void _showProfileModal(
    BuildContext context,
    UserProfile p,
    String shortId,
    String currentDetectedLocation,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profil Petani',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x0D022C22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, size: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF047857)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: TB-$shortId • Petani Mitra Aktif',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildProfileRow(
                    icon: Icons.badge_outlined,
                    label: 'Nama Lengkap',
                    value: p.name,
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildProfileRow(
                    icon: Icons.my_location_rounded,
                    label: 'Lokasi Saat Ini (GPS)',
                    value: currentDetectedLocation,
                  ),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  _buildProfileRow(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat Rumah / Alamat Lahan',
                    value: p.region,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFDA4AF), width: 1.5),
                  backgroundColor: const Color(0xFFFFF1F2),
                  foregroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmLogout(context);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Keluar dari Akun (Log Out)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.forest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.forest),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'Konfirmasi Keluar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun TOBA VISION? Anda perlu masuk kembali untuk mengakses data kebun.',
          style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anda telah berhasil keluar dari akun.'),
                  backgroundColor: Color(0xFFDC2626),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  final int tabIndex;

  const _FeatureItem({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.tabIndex,
  });
}

const List<_FeatureItem> _features = [
  _FeatureItem(
    icon: Icons.local_florist_outlined,
    bg: AppColors.mint,
    fg: AppColors.green,
    title: 'Deteksi AI',
    subtitle: 'Pindai Daun Kebun',
    tabIndex: 1,
  ),
  _FeatureItem(
    icon: Icons.wb_sunny_outlined,
    bg: AppColors.peach,
    fg: AppColors.amber,
    title: 'Cuaca',
    subtitle: 'Prakiraan & Jemur',
    tabIndex: 4,
  ),
  _FeatureItem(
    icon: Icons.payments_outlined,
    bg: Color(0xFFE5E7EB),
    fg: AppColors.ink,
    title: 'Keuangan',
    subtitle: 'Buku Kas & Biaya',
    tabIndex: 2,
  ),
  _FeatureItem(
    icon: Icons.agriculture_outlined,
    bg: Color(0xFFE0E7FF),
    fg: Color(0xFF3730A3),
    title: 'Panen',
    subtitle: 'Jadwal & Hasil Petik',
    tabIndex: 3,
  ),
];

class _FeatureGrid extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _FeatureGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (int i = 0; i < _features.length; i += 2) {
      if (i > 0) {
        rows.add(Container(height: 1, color: AppColors.line));
      }

      final first = _features[i];
      final hasSecond = i + 1 < _features.length;
      final second = hasSecond ? _features[i + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FeatureCell(
                  item: first,
                  onTap: () => onNavigate(first.tabIndex),
                ),
              ),
              if (second != null) ...[
                Container(width: 1, color: AppColors.line),
                Expanded(
                  child: _FeatureCell(
                    item: second,
                    onTap: () => onNavigate(second.tabIndex),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: cardDeco(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _FeatureCell extends StatelessWidget {
  final _FeatureItem item;
  final VoidCallback onTap;

  const _FeatureCell({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.fg),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AiBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.green, Color(0xFF14572F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -4,
            top: -4,
            child: Icon(Icons.local_florist_outlined, size: 68, color: Color(0x33FFFFFF)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.mint),
                    SizedBox(width: 6),
                    Text(
                      'AI Vision Standar SNI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pindai Mutu Daun Tembakau',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Arahkan kamera ke daun untuk cek kematangan & prediksi grade instan.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.mint,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.photo_camera_rounded, size: 20),
                  label: const Text(
                    'Buka Kamera AI',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
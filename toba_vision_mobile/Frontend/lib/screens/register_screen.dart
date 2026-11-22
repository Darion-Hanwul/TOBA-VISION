import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/auth_session.dart';
import '../data/bmkg_locations.dart';
import '../data/firestore_service.dart';
import '../widgets/retro/blade_ornament.dart';
import '../widgets/retro/chrome_wordmark.dart';
import '../widgets/retro/micro_text.dart';
import '../widgets/retro/retro_card.dart';
import '../widgets/retro/retro_frame.dart';
import '../widgets/retro/trapezoid_tab_button.dart';
import 'shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _desaController = TextEditingController(text: 'Bulu');
  String _selectedProvinsi = 'Jawa Tengah';
  String _selectedKabupaten = 'Temanggung';
  String _selectedKecamatan = 'Bulu';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _desaController.dispose();
    super.dispose();
  }

  void _showNameTakenDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.rust, size: 22),
            const SizedBox(width: 8),
            Text(
              'NAMA SUDAH TERPAKAI',
              style: AppTypography.display(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.rust,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama petani "$name" sudah terdaftar dalam sistem.',
              style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan gunakan nama lain atau variasikan nama Anda (misal tambah dusun), atau langsung masuk jika akun ini milik Anda.',
              style: AppTypography.body(fontSize: 11.5, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'GANTI NAMA',
              style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Kembali ke halaman login
            },
            child: Text('MASUK SEKARANG', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final areaStr = _areaController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final desaStr = _desaController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masukkan Nama Lengkap Petani!'),
          backgroundColor: AppColors.rust,
        ),
      );
      return;
    }

    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masukkan Kata Sandi (minimal 6 karakter)!'),
          backgroundColor: AppColors.rust,
        ),
      );
      return;
    }

    if (password.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kata sandi wajib minimal 6 karakter!'),
          backgroundColor: AppColors.rust,
        ),
      );
      return;
    }

    if (password.trim() != confirm.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Konfirmasi kata sandi tidak cocok!'),
          backgroundColor: AppColors.rust,
        ),
      );
      return;
    }

    final luas = double.tryParse(areaStr.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1000.0;
    final lokasiLahanFinal = desaStr.isNotEmpty
        ? 'Desa $desaStr, Kec. $_selectedKecamatan, Kab. $_selectedKabupaten, Prov. $_selectedProvinsi'
        : 'Kec. $_selectedKecamatan, Kab. $_selectedKabupaten, Prov. $_selectedProvinsi';

    setState(() => _isLoading = true);

    try {
      final petani = await FirestoreService.instance.daftarPetaniBaru(
        nama: name,
        lokasiLahan: lokasiLahanFinal,
        luasLahanM2: luas,
        password: password.trim(),
      );

      AuthSession.setSession(petani);
      try {
        final musim = await FirestoreService.instance.getOrCreateMusimAktif(petani.idPetani);
        AuthSession.activeMusimId = musim.idMusim;
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat bergabung, ${petani.nama}! Akun berhasil dibuat.'),
            backgroundColor: AppColors.forestGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Shell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('NAMA_SUDAH_TERPAKAI')) {
          _showNameTakenDialog(name);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pendaftaran gagal: $e'),
              backgroundColor: AppColors.rust,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordMatch = _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFE9),
      body: SafeArea(
        child: RetroFrame(
          backgroundColor: AppColors.sage,
          margin: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Navigasi Kembali & Wordmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.ink),
                            SizedBox(width: 4),
                            MicroText('KEMBALI', fontSize: 9),
                          ],
                        ),
                      ),
                    ),
                    const MicroText('REGISTRATION // TAPE-FORM', fontSize: 8.5),
                  ],
                ),
                const SizedBox(height: 8),
                const Center(
                  child: ChromeWordmark(fontSize: 20),
                ),
                const SizedBox(height: 10),
                const TaperedDivider(centerLabel: 'PENDAFTARAN MITRA BARU'),

                // Strip Keamanan Data Offline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 20, color: AppColors.forest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data akun tersimpan aman dan terenkripsi.',
                          style: AppTypography.mono(
                            fontSize: 10,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Form Registrasi
                RetroCard(
                  tapeTag: 'FORMULIR PETANI // BARU',
                  rightTag: 'TB-REG-2026',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Nama Lengkap (ID Unik Petani)
                      const MicroText('NAMA LENGKAP PETANI (ID UNIK AKUN)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Contoh: Slamet Raharjo',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.ink, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const MicroText(
                        '* Nama petani harus unik untuk identitas akun & login',
                        fontSize: 8.5,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Lokasi Kebun & Wilayah Cuaca BMKG (Provinsi, Kabupaten, Kecamatan, Desa)
                      const MicroText('1. PROVINSI KEBUN (38 PROVINSI RESMI BMKG)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProvinsi,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                            style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                            items: BmkgLocations.daftarProvinsi.map((p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text(
                                  p == 'Jawa Tengah' ? '$p (Sentra Utama Temanggung)' : p,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedProvinsi = val;
                                  final newKabs = BmkgLocations.getKabupatenList(val);
                                  _selectedKabupaten = newKabs.first;
                                  final newKecs = BmkgLocations.getKecamatanList(_selectedKabupaten);
                                  _selectedKecamatan = newKecs.first;
                                  final newDesas = BmkgLocations.getDesaList(_selectedKecamatan);
                                  _desaController.text = newDesas.isNotEmpty ? newDesas.first : '';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      MicroText('2. KABUPATEN / KOTA (${BmkgLocations.getKabupatenList(_selectedProvinsi).length} WILAYAH)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: BmkgLocations.getKabupatenList(_selectedProvinsi).contains(_selectedKabupaten)
                                ? _selectedKabupaten
                                : BmkgLocations.getKabupatenList(_selectedProvinsi).first,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                            style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                            items: BmkgLocations.getKabupatenList(_selectedProvinsi).map((k) {
                              return DropdownMenuItem<String>(
                                value: k,
                                child: Text(
                                  k == 'Temanggung' ? '$k (Sentra Utama Sindoro-Sumbing)' : k,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedKabupaten = val;
                                  final newKecs = BmkgLocations.getKecamatanList(val);
                                  _selectedKecamatan = newKecs.first;
                                  final newDesas = BmkgLocations.getDesaList(_selectedKecamatan);
                                  _desaController.text = newDesas.isNotEmpty ? newDesas.first : '';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      MicroText('3. KECAMATAN (${BmkgLocations.getKecamatanList(_selectedKabupaten).length} KECAMATAN)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: BmkgLocations.getKecamatanList(_selectedKabupaten).contains(_selectedKecamatan)
                                ? _selectedKecamatan
                                : BmkgLocations.getKecamatanList(_selectedKabupaten).first,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                            style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                            items: BmkgLocations.getKecamatanList(_selectedKabupaten).map((kec) {
                              return DropdownMenuItem<String>(
                                value: kec,
                                child: Text('Kecamatan $kec'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedKecamatan = val;
                                  final desaList = BmkgLocations.getDesaList(val);
                                  _desaController.text = desaList.isNotEmpty ? desaList.first : '';
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      MicroText(
                        BmkgLocations.getDesaList(_selectedKecamatan).isNotEmpty
                            ? '4. DESA / KELURAHAN (${BmkgLocations.getDesaList(_selectedKecamatan).length} DESA DI KEC. ${_selectedKecamatan.toUpperCase()})'
                            : '4. DESA / KELURAHAN KEBUN',
                        fontSize: 10,
                      ),
                      const SizedBox(height: 6),
                      if (BmkgLocations.getDesaList(_selectedKecamatan).isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: BmkgLocations.getDesaList(_selectedKecamatan).contains(_desaController.text.trim())
                                  ? _desaController.text.trim()
                                  : BmkgLocations.getDesaList(_selectedKecamatan).first,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                              style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                              items: BmkgLocations.getDesaList(_selectedKecamatan).map((d) {
                                return DropdownMenuItem<String>(
                                  value: d,
                                  child: Text('Desa / Kel. $d'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _desaController.text = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: TextField(
                            controller: _desaController,
                            textInputAction: TextInputAction.next,
                            style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Contoh: Lamuk / Danurejo / Tlahap',
                              prefixIcon: Icon(Icons.home_work_outlined, color: AppColors.ink, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      const MicroText(
                        '* Data Provinsi, Kabupaten, Kecamatan, dan Desa terhubung ke prakiraan cuaca & jadwal penjemuran BMKG',
                        fontSize: 8.5,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 14),

                      // Field 4: Luas Lahan (Meter Persegi / m²)
                      const MicroText('LUAS LAHAN KEBUN (METER PERSEGI / m²)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.square_foot_rounded, color: AppColors.ink, size: 20),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _areaController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                style: AppTypography.mono(fontSize: 14, fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Contoh: 2500',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.ink, width: 1.2),
                              ),
                              child: const MicroText('m²', fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Field 3: Kata Sandi
                      const MicroText('KATA SANDI', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.ink, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.ink,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Field 4: Konfirmasi Kata Sandi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const MicroText('KONFIRMASI KATA SANDI', fontSize: 10),
                          if (_confirmPasswordController.text.isNotEmpty)
                            MicroText(
                              passwordMatch ? 'COCOK' : 'BELUM COCOK',
                              fontSize: 9,
                              color: passwordMatch ? AppColors.green : AppColors.red,
                              fontWeight: FontWeight.w900,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _handleRegister(),
                          style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Ulangi kata sandi Anda',
                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.ink, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.ink,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol CTA Trapesium Oranye
                TrapezoidTabButton(
                  label: _isLoading ? 'MENDAFTARKAN...' : 'DAFTAR AKUN SEKARANG',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleRegister,
                ),
                const SizedBox(height: 16),

                // Link Kembali ke Login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'SUDAH PUNYA AKUN? MASUK SEKARANG',
                        style: AppTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

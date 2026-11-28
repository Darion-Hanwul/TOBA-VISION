import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/auth_session.dart';
import '../data/firestore_service.dart';
import '../widgets/retro/chrome_wordmark.dart';
import '../widgets/retro/micro_text.dart';
import '../widgets/retro/retro_card.dart';
import '../widgets/retro/retro_frame.dart';
import '../widgets/retro/trapezoid_tab_button.dart';
import 'register_screen.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masukkan Nama Petani atau Username!'),
          backgroundColor: AppColors.rust,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan masukkan Kata Sandi Anda!'),
          backgroundColor: AppColors.rust,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Pastikan demo data sudah ada jika login menggunakan akun demo
      if (identifier == 'Slamet Raharjo' ||
          identifier == 'slamet_raharjo' ||
          identifier == '081234567890') {
        try {
          await FirestoreService.instance.inisialisasiDataAwalDemo();
        } catch (_) {}
      }

      var petani = await FirestoreService.instance.loginPetani(
        identifier: identifier,
        password: password,
      );

      if (petani != null) {
        AuthSession.setSession(petani);
        try {
          final musim = await FirestoreService.instance.getOrCreateMusimAktif(petani.idPetani);
          AuthSession.activeMusimId = musim.idMusim;
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selamat datang kembali, ${petani.nama}!'),
              backgroundColor: AppColors.forestGreen,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Shell()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nama Petani / Username "$identifier" tidak ditemukan!'),
              backgroundColor: AppColors.rust,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('KATA_SANDI_SALAH')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Kata sandi salah! Mohon periksa kembali kata sandi Anda.'),
              backgroundColor: AppColors.rust,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Koneksi bermasalah: $e'),
              backgroundColor: AppColors.orange,
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
                // 1. Wordmark Aplikasi
                const Center(
                  child: ChromeWordmark(fontSize: 22),
                ),
                const SizedBox(height: 18),

                // 2. Form Input: Nama Petani & Kata Sandi
                RetroCard(
                  tapeTag: 'masukan nama dan kata sandi anda',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Nama Lengkap / Username Petani (ID Unik)
                      const MicroText('NAMA PETANI / USERNAME (ID UNIK)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _identifierController,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.mono(fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.ink, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            hintText: 'Contoh: Slamet Raharjo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Kata Sandi
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
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.ink, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.ink,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            hintText: 'Masukkan Kata Sandi',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Tombol CTA Trapesium Oranye
                TrapezoidTabButton(
                  label: _isLoading ? 'MEMERIKSA DATA...' : 'MASUK KE KEBUN',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleLogin,
                ),
                const SizedBox(height: 16),

                // 6. Link Daftar Akun Baru
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'BELUM PUNYA AKUN? DAFTAR AKUN BARU',
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

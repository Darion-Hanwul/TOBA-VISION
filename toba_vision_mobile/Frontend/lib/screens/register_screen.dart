import 'package:flutter/material.dart';
import '../core/theme.dart';
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
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    // Mode Slicing: Langsung navigasi ke HomeScreen (Shell) tanpa cek inputan
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Shell()),
      (route) => false,
    );
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
                      // Field 1: Nama Lengkap
                      const MicroText('NAMA LENGKAP', fontSize: 10),
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
                      const SizedBox(height: 14),

                      // Field 2: Alamat Lahan / Lokasi Kebun
                      const MicroText('ALAMAT LAHAN / LOKASI KEBUN', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _addressController,
                          minLines: 2,
                          maxLines: 3,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Nama desa, dusun, atau blok lahan kebun tembakau',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Icon(Icons.location_on_outlined, color: AppColors.ink, size: 20),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MicroText(
                        '* Alamat digunakan untuk integrasi cuaca & data lahan',
                        fontSize: 8.5,
                        color: AppColors.muted,
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
                  label: 'DAFTAR AKUN SEKARANG',
                  onPressed: _handleRegister,
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

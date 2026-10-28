import 'package:flutter/material.dart';
import '../core/theme.dart';
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
                    // Input 1: Nama Lengkap
                    _buildFieldLabel(
                      icon: Icons.person_rounded,
                      label: 'Nama Lengkap',
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
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Contoh: Slamet Raharjo',
                          hintStyle: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 16,
                            color: Color(0xFF707A6F),
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: Color(0xFF707A6F),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input 2: Alamat Lahan / Lokasi Kebun
                    _buildFieldLabel(
                      icon: Icons.location_on_rounded,
                      label: 'Alamat Lahan / Lokasi Kebun',
                    ),
                    const SizedBox(height: 6),
                    _buildInputCard(
                      child: TextField(
                        controller: _addressController,
                        minLines: 3,
                        maxLines: 4,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontFamily: kSerif,
                          fontSize: 16,
                          color: Color(0xFF191C1E),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nama desa, dusun, atau blok lahan kebun tembakau',
                          hintStyle: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 16,
                            color: Color(0xFF707A6F),
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 40),
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
                    // Helper text
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Color(0xFF9B4500),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Alamat digunakan untuk integrasi cuaca & data lahan',
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
                    const SizedBox(height: 20),

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
                          hintText: 'Buat kata sandi akun',
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
                    const SizedBox(height: 20),

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
                        onSubmitted: (_) => _handleRegister(),
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
                        onPressed: _handleRegister,
                        child: const Row(
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
          // Button Go Back
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

          // Title
          const Text(
            'Daftar Akun Baru',
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),

          // Right decorative badge (check mark)
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
        Text(
          label,
          style: const TextStyle(
            fontFamily: kSerif,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191C1E),
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

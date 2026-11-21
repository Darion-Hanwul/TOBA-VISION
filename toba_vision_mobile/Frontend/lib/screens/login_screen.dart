import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import '../widgets/app_logo.dart';
import 'register_screen.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIKA LOGIN FIREBASE (USERNAME) + HIVE
  // ==========================================
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama petani dan kata sandi tidak boleh kosong.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.loginPetani(
        username: username,
        password: password,
      );

      // Simpan kredensial lokal terenkripsi ringan untuk fitur pemulihan lupa sandi
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');
      await box.put('saved_cred_$username', password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil masuk! Selamat datang di Toba Vision.'),
          backgroundColor: Color(0xFF004C22),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Shell()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // DIALOG LUPA PASSWORD (LIHAT LAMA & UBAH BARU)
  // ==========================================
  Future<void> _showForgotPasswordDialog() async {
    final lookupNameCtrl = TextEditingController(
      text: _usernameController.text.trim(),
    );
    final newPassCtrl = TextEditingController();
    final confirmNewPassCtrl = TextEditingController();

    String? recoveredOldPassword;
    String? matchedUid;
    bool isSearching = false;
    bool isUpdating = false;
    bool revealOldPass = false;
    bool obscureNew = true;
    bool obscureConfirmNew = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> findOldPassword() async {
            final targetName = lookupNameCtrl.text.trim();
            if (targetName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Masukkan Nama / Username Petani terlebih dahulu.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            setDialogState(() {
              isSearching = true;
              recoveredOldPassword = null;
            });

            try {
              final box = Hive.isBoxOpen('toba_offline_box')
                  ? Hive.box('toba_offline_box')
                  : await Hive.openBox('toba_offline_box');

              // 1. Cek di cache kredensial Hive berdasarkan nama persis (case-sensitive)
              String? foundPass = box.get('saved_cred_$targetName')?.toString();
              final localUser = OfflineService.getUserData();
              if (foundPass == null &&
                  localUser['nama']?.toString().trim() == targetName &&
                  (localUser['password']?.toString().isNotEmpty ?? false)) {
                foundPass = localUser['password'].toString();
              }

              // 2. Cek ke backend FastAPI jika tersedia
              try {
                final res = await http
                    .get(
                      Uri.parse(
                        '${ApiService.baseUrl}/api/petani/by-nama/${Uri.encodeComponent(targetName)}',
                      ),
                    )
                    .timeout(const Duration(seconds: 5));
                if (res.statusCode == 200) {
                  final decoded = jsonDecode(res.body);
                  final data = decoded['data'] ?? decoded;
                  if (data is Map) {
                    matchedUid = data['uid']?.toString();
                    if ((foundPass == null || foundPass.isEmpty) &&
                        data['password'] != null) {
                      foundPass = data['password'].toString();
                    }
                  }
                }
              } catch (_) {}

              setDialogState(() {
                recoveredOldPassword = (foundPass != null && foundPass.isNotEmpty)
                    ? foundPass
                    : 'Tidak tersimpan di perangkat ini (silakan langsung buat password baru di bawah)';
              });
            } finally {
              setDialogState(() => isSearching = false);
            }
          }

          Future<void> saveNewPassword() async {
            final targetName = lookupNameCtrl.text.trim();
            final newPass = newPassCtrl.text.trim();
            final confirmPass = confirmNewPassCtrl.text.trim();

            if (targetName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nama petani wajib diisi.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (newPass.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kata sandi baru minimal 6 karakter.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (newPass != confirmPass) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Konfirmasi kata sandi baru tidak cocok.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            setDialogState(() => isUpdating = true);

            try {
              final box = Hive.isBoxOpen('toba_offline_box')
                  ? Hive.box('toba_offline_box')
                  : await Hive.openBox('toba_offline_box');

              // 1. Jika ada sesi aktif atau kredensial lama, perbarui di FirebaseAuth
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                await currentUser.updatePassword(newPass);
              } else if (recoveredOldPassword != null &&
                  !recoveredOldPassword!.startsWith('Tidak tersimpan')) {
                await AuthService.loginPetani(
                  username: targetName,
                  password: recoveredOldPassword!,
                );
                await FirebaseAuth.instance.currentUser?.updatePassword(newPass);
              }

              // 2. Sinkronkan pembaruan password ke Backend / Firestore jika endpoint tersedia
              try {
                await http
                    .post(
                      Uri.parse('${ApiService.baseUrl}/api/petani/reset-password'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'uid': matchedUid ?? FirebaseAuth.instance.currentUser?.uid,
                        'nama': targetName,
                        'new_password': newPass,
                      }),
                    )
                    .timeout(const Duration(seconds: 5));
              } catch (_) {}

              // 3. Simpan password baru di Hive lokal & isi otomatis form login
              await box.put('saved_cred_$targetName', newPass);

              if (!mounted) return;
              setState(() {
                _usernameController.text = targetName;
                _passwordController.text = newPass;
              });

              if (ctx.mounted) Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kata sandi baru berhasil disimpan! Silakan masuk.'),
                  backgroundColor: Color(0xFF004C22),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mengubah kata sandi: ${e.toString().replaceAll("Exception: ", "")}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } finally {
              if (ctx.mounted) setDialogState(() => isUpdating = false);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF004C22), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lupa Kata Sandi',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan nama akun untuk melihat sandi lama atau langsung buat sandi baru:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lookupNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama / Username Petani',
                      hintText: 'Contoh: Slamet Raharjo',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF004C22),
                        side: const BorderSide(color: Color(0xFF004C22)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSearching ? null : findOldPassword,
                      icon: isSearching
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search_rounded, size: 16),
                      label: Text(
                        isSearching ? 'Mencari Akun...' : 'Lihat Password Lama',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (recoveredOldPassword != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Password Lama Terdaftar:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  recoveredOldPassword!.startsWith('Tidak tersimpan')
                                      ? recoveredOldPassword!
                                      : (revealOldPass
                                          ? recoveredOldPassword!
                                          : '•' * recoveredOldPassword!.length),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF064E3B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!recoveredOldPassword!.startsWith('Tidak tersimpan'))
                            IconButton(
                              icon: Icon(
                                revealOldPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF065F46),
                              ),
                              onPressed: () {
                                setDialogState(() => revealOldPass = !revealOldPass);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 22),
                  const Text(
                    'Ubah ke Password Baru',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Password Baru (min. 6 karakter)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmNewPassCtrl,
                    obscureText: obscureConfirmNew,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureConfirmNew = !obscureConfirmNew),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004C22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isUpdating ? null : saveNewPassword,
                child: Text(
                  isUpdating ? 'Menyimpan...' : 'Simpan Password Baru',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero & Brand Identity Card
              _buildHeroBrandCard(),
              const SizedBox(height: 16),

              // 2. Form Card: Nama Petani & Kata Sandi
              _buildFormCard(),
              const SizedBox(height: 20),

              // 3. Primary Button: Masuk ke Kebun
              _buildLoginButton(),
              const SizedBox(height: 10),

              // 4. Tombol Lupa Password (Tepat di bawah tombol Masuk)
              _buildForgotPasswordButton(),
              const SizedBox(height: 16),

              // 5. Footer: Daftar Akun Baru
              _buildFooterLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBrandCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TobaVisionLogo(
            size: 64,
            elevation: [
              BoxShadow(
                color: const Color(0xFF29543C).withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'TOBA VISION',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDBCA),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'v2.4 AI',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF331200),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Asisten AI Cerdas Petani Tembakau Modern',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF404940),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nama / Username Petani',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Contoh: Slamet Raharjo',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF707A6F)),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Color(0xFF004C22),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kata Sandi',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isLoading ? null : _handleLogin(),
              style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Masukkan kata sandi',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF707A6F)),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: Color(0xFF004C22),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF707A6F),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  tooltip: 'Lihat atau sembunyikan kata sandi',
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF004C22),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0xFF004C22).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _handleLogin,
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
                    'Masuk ke Kebun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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
    );
  }

  Widget _buildForgotPasswordButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF004C22),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _showForgotPasswordDialog,
        icon: const Icon(Icons.lock_reset_rounded, size: 18),
        label: const Text(
          'Lupa Password?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Belum punya akun? ',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF404940),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004C22),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Color(0xFF004C22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
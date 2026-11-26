import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/auth_session.dart';
import '../data/models.dart';
import '../data/services.dart';
import '../widgets/app_header.dart';
import '../widgets/async_view.dart';
import '../widgets/retro/blade_ornament.dart';
import '../widgets/retro/micro_text.dart';
import '../widgets/retro/retro_card.dart';
import '../widgets/retro/retro_frame.dart';
import '../widgets/retro/status_chip.dart';
import '../widgets/retro/trapezoid_tab_button.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AsyncView<UserProfile>(
      load: () => Services.user.getProfile(),
      builder: (context, p) => RetroFrame(
        backgroundColor: AppColors.sage,
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header dengan Profil Action Button
              AppHeader(
                subtitle: 'TEMANGGUNG, JATENG // POKTAN',
                padding: EdgeInsets.zero,
                height: null,
                logoSize: 42,
                useAppLogo: true,
                trailing: AppHeaderActionButton(
                  icon: Icons.person_outline_rounded,
                  onTap: () => _showProfileModal(context, p),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Sapaan Display Besar & Info Kelompok Petani
              Text(
                '${greeting()},\n${p.name}',
                style: AppTypography.display(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.ink),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        p.region.toUpperCase(),
                        style: AppTypography.mono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Divider Tapered dengan Judul Section
              const TaperedDivider(centerLabel: 'FITUR UTAMA LAPANGAN // 01-04'),
              const SizedBox(height: 6),

              // 4. Grid 2x2 Fitur Utama (Bergaya Kaset Audio 01-04)
              _buildFeatureGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCassetteFeatureCard(
                trackNo: '01',
                title: 'Deteksi AI',
                subtitle: 'Grade & Siap Panen',
                icon: Icons.document_scanner_rounded,
                accentColor: AppColors.lime,
                onTap: () => onNavigate(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCassetteFeatureCard(
                trackNo: '02',
                title: 'Cuaca Kebun',
                subtitle: 'Prakiraan & Sasak',
                icon: Icons.wb_sunny_rounded,
                accentColor: AppColors.orange,
                onTap: () => onNavigate(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCassetteFeatureCard(
                trackNo: '03',
                title: 'Keuangan',
                subtitle: 'Buku Kas & Modal',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFF60A5FA),
                onTap: () => onNavigate(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCassetteFeatureCard(
                trackNo: '04',
                title: 'Panen',
                subtitle: '7 Siklus & Timbang',
                icon: Icons.agriculture_rounded,
                accentColor: AppColors.lime,
                onTap: () => onNavigate(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCassetteFeatureCard({
    required String trackNo,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return RetroCard(
      tapeTag: 'TRACK $trackNo',
      rightTag: 'TB-SYS',
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.ink),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.display(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.body(
              fontSize: 11,
              color: AppColors.muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, UserProfile p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppColors.ink, width: 2.5),
            left: BorderSide(color: AppColors.ink, width: 2.5),
            right: BorderSide(color: AppColors.ink, width: 2.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROFIL PETANI MITRA',
                    style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const StatusChip(label: 'TERVERIFIKASI', variant: StatusChipVariant.lime),
                ],
              ),
              const SizedBox(height: 12),
              RetroCard(
                tapeTag: 'IDENTIFICATION // FARMER CARD',
                rightTag: 'TB-2026-088',
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, size: 28, color: AppColors.lime),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: AppTypography.display(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          MicroText(
                            'LOKASI LAHAN: ${p.region.toUpperCase()}',
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TrapezoidTabButton(
                label: 'LOG OUT / KELUAR',
                backgroundColor: AppColors.red,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pop(ctx);
                  _confirmLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text(
          'KONFIRMASI KELUAR',
          style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun petani mitra?',
          style: AppTypography.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: AppTypography.mono(fontSize: 12, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AuthSession.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anda berhasil keluar dari sistem.')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('YA, KELUAR', style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

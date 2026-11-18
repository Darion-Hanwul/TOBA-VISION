import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';

class FinanceEndScreen extends StatelessWidget {
  const FinanceEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFE9),
      body: SafeArea(
        child: RetroFrame(
          backgroundColor: AppColors.sage,
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const AppHeader(
                  showBack: true,
                  title: 'REKAP TUTUP BUKU',
                  subtitle: 'LAPORAN AKHIR MUSIM // ARSIP',
                  padding: EdgeInsets.zero,
                  height: null,
                ),
                const SizedBox(height: 14),

                // Status Banner Selesai Musim
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ink, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KONFIRMASI TUTUP BUKU',
                              style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.red),
                            ),
                            const SizedBox(height: 1),
                            const MicroText('MUSIM TANAM 2026 • LAHAN BLOK A TIMUR', fontSize: 9, color: AppColors.ink),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Dokumen Struk / Faktur Kas Musim Tanam
                RetroCard(
                  tapeTag: 'OFFICIAL RECEIPT // PERKEBUNAN TEMANGGUNG',
                  rightTag: 'FINAL AUDIT',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const MicroText('TOTAL PENGELUARAN TERCATAT', fontSize: 10, color: AppColors.muted),
                            const SizedBox(height: 4),
                            Text(
                              'Rp 14.250.000',
                              style: AppTypography.display(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const TaperedDivider(centerLabel: 'RINCIAN 4 POS BIAYA'),
                      const SizedBox(height: 8),

                      _buildReceiptRow('Buruh Tani / Upah Kerja', 'Rp 6.800.000'),
                      _buildReceiptRow('Pupuk & Nutrisi', 'Rp 3.800.000'),
                      _buildReceiptRow('Bibit & Olah Lahan', 'Rp 2.400.000'),
                      _buildReceiptRow('Lainnya / Operasional', 'Rp 1.250.000'),

                      const Divider(color: AppColors.ink, height: 20, thickness: 1.5),
                      const MicroText('STATUS LAPORAN: TUTUP BUKU & SIAP DIARSIP', fontSize: 9, fontWeight: FontWeight.w900),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Peringatan Arsip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.ink),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Data yang ditutup buku akan dipindahkan ke arsip semua musim dan dikunci dari pengeditan.',
                          style: AppTypography.mono(fontSize: 9.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Konfirmasi CTA Trapesium
                TrapezoidTabButton(
                  label: 'KONFIRMASI & SIMPAN ARSIP',
                  backgroundColor: AppColors.orange,
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tutup buku musim berhasil diarsipkan!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),

                // Tombol Batal
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'BATAL & KEMBALI KE BUKU KAS',
                        style: AppTypography.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ).copyWith(decoration: TextDecoration.underline),
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

  Widget _buildReceiptRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(amount, style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

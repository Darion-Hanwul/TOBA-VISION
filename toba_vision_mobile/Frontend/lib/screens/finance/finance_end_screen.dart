import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

class FinanceEndScreen extends StatelessWidget {
  const FinanceEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: const AppHeader(
        showBack: true,
        title: 'Rekap Tutup Buku Musim',
        backgroundColor: Colors.white,
        showBottomBorder: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner Selesai Musim
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE4E6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBE123C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFBE123C), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfirmasi Tutup Buku',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9F1239),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Musim Tanam 2026 • Lahan Blok A - Timur',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFBE123C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card Ringkasan Finansial Akhir
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Akhir Pengeluaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Total Pengeluaran Tercatat', 'Rp 14.250.000', isBold: true),
                  const Divider(height: 24, color: Color(0xFFECEEF0)),
                  _buildSummaryRow('Buruh Tani / Upah Kerja', 'Rp 6.800.000'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Pupuk & Nutrisi', 'Rp 3.800.000'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Bibit & Olah Lahan', 'Rp 2.400.000'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Lainnya / Operasional', 'Rp 1.250.000'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informasi Penting
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF475569), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Setelah tutup buku disimpan, rekap akan diarsipkan ke histori musim dan buku kas baru akan dibuka kembali untuk musim berikutnya.',
                      style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBE123C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tutup buku musim berhasil disimpan ke arsip laporan!'),
                      backgroundColor: Color(0xFFBE123C),
                    ),
                  );
                },
                icon: const Icon(Icons.archive_rounded, size: 20),
                label: const Text(
                  'Konfirmasi & Simpan Arsip',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFECEEF0),
                  foregroundColor: const Color(0xFF191C1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal & Kembali',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF191C1E) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: isBold ? const Color(0xFFBE123C) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

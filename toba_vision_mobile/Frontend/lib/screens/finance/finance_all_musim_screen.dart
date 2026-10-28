import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

class FinanceAllMusimScreen extends StatefulWidget {
  const FinanceAllMusimScreen({super.key});

  @override
  State<FinanceAllMusimScreen> createState() => _FinanceAllMusimScreenState();
}

class _FinanceAllMusimScreenState extends State<FinanceAllMusimScreen> {
  // Data Riwayat Semua Musim Tanam
  final List<Map<String, dynamic>> _seasonHistory = [
    {
      'title': 'Musim Ketiga (2024)',
      'period': 'Mei - Okt 2024 • Lahan Blok A & B',
      'expenses': 'Rp 14.250.000',
      'harvest': '3.200 kg tembakau',
      'status': 'Selesai',
    },
    {
      'title': 'Musim Kedua (2023)',
      'period': 'Mei - Sep 2023 • Lahan Blok A',
      'expenses': 'Rp 12.800.000',
      'harvest': '2.850 kg tembakau',
      'status': 'Selesai',
    },
    {
      'title': 'Musim Pertama (2022)',
      'period': 'Jun - Okt 2022 • Lahan Blok A',
      'expenses': 'Rp 11.450.000',
      'harvest': '2.600 kg tembakau',
      'status': 'Selesai',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppHeader(
        showBack: true,
        title: 'Rekap Semua Musim',
        backgroundColor: const Color(0xE6F4F7F5),
        showBottomBorder: true,
        trailing: AppHeaderActionButton(
          icon: Icons.sync_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sinkronisasi data semua musim berhasil diperbarui!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitleSection(),
              const SizedBox(height: 16),
              _buildAllSeasonsSummaryCard(),
              const SizedBox(height: 24),
              _buildAllSeasonsHistoryList(),
            ],
          ),
        ),
      ),
    );
  }

  // Header Judul Halaman
  Widget _buildHeaderTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Biaya & Pengeluaran',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: Color(0xFF022C22),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Semua Musim',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Akumulasi menyeluruh pengeluaran operasional dari seluruh musim tanam.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // 1. Ringkasan Total & Visualisasi Donut Chart Akumulasi
  Widget _buildAllSeasonsSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0D022C22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Donut Chart 176x176
          SizedBox(
            width: 176,
            height: 176,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(176, 176),
                  painter: _AllSeasonsRingProgressPainter(),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD1FAE5).withValues(alpha: 0.6)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: const Icon(Icons.spa_rounded, color: Color(0xFF047857), size: 18),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SEMUA MUSIM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TOTAL BIAYA TERCATAT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Rp 38,5 jt',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.75,
              color: Color(0xFF14532D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Akumulasi seluruh pengeluaran dari 3 musim tanam',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          // Header Kategori Akumulasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KATEGORI AKUMULASI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF334155),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  '3 Musim',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccumulatedCategoryGrid(),
        ],
      ),
    );
  }

  // 2. Grid 2x2 Kategori Akumulasi
  Widget _buildAccumulatedCategoryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Buruh & Petik',
                amount: 'Rp 18,5 jt',
                percent: '48%',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF065F46),
                iconBg: const Color(0xFFD1FAE5),
                textColor: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Pupuk & Nutrisi',
                amount: 'Rp 10,4 jt',
                percent: '27%',
                icon: Icons.science_outlined,
                iconColor: const Color(0xFF3730A3),
                iconBg: const Color(0xFFE0E7FF),
                textColor: const Color(0xFF312E81),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Bibit & Olah Lahan',
                amount: 'Rp 6,5 jt',
                percent: '17%',
                icon: Icons.spa_outlined,
                iconColor: const Color(0xFF115E59),
                iconBg: const Color(0xFFCCFBF1),
                textColor: const Color(0xFF115E59),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Logistik & Lain',
                amount: 'Rp 3,1 jt',
                percent: '8%',
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF92400E),
                iconBg: const Color(0xFFFEF3C7),
                textColor: const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccumulatedCard({
    required String label,
    required String amount,
    required String percent,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Text(
                percent,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Section Riwayat Musim Tanam Sebelumnya
  Widget _buildAllSeasonsHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Musim Tanam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '${_seasonHistory.length} Musim Selesai',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _seasonHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final season = _seasonHistory[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            season['title'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    season['period'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Total: ${season['expenses']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${season['harvest']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF8FAFC)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMiniButton(
                        label: 'Detail',
                        icon: Icons.visibility_outlined,
                        bg: const Color(0xFFF8FAFC),
                        fg: const Color(0xFF1E293B),
                        border: const Color(0xFFE2E8F0),
                        onTap: () => _showSeasonDetail(season),
                      ),
                      const SizedBox(width: 8),
                      _buildMiniButton(
                        label: 'Hapus',
                        icon: Icons.delete_outline_rounded,
                        bg: const Color(0xFFFEF2F2),
                        fg: const Color(0xFFDC2626),
                        border: const Color(0xFFFECACA),
                        onTap: () => _confirmDeleteSeason(index, season),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _confirmDeleteSeason(int index, Map<String, dynamic> season) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFBE123C)),
            SizedBox(width: 8),
            Text(
              'Hapus Arsip Musim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${season['title']}"? Data riwayat dan rekapitulasi musim ini akan dihapus permanen.',
          style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final deletedTitle = season['title'];
              setState(() {
                _seasonHistory.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Arsip "$deletedTitle" berhasil dihapus!'),
                  backgroundColor: const Color(0xFFBE123C),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSeasonDetail(Map<String, dynamic> season) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  season['title'] as String,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF022C22)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    'Arsip Selesai',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(season['period'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const Divider(height: 28),
            _buildDetailRow('Total Pengeluaran', season['expenses'] as String, isBold: true),
            const SizedBox(height: 10),
            _buildDetailRow('Total Hasil Timbangan', season['harvest'] as String),
            const SizedBox(height: 10),
            _buildDetailRow('Status Rekap', 'Tutup Buku & Terverifikasi'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter untuk Donut Chart Segmen Semua Musim
class _AllSeasonsRingProgressPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final greenPaint = Paint()
      ..color = const Color(0xFF166534)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final indigoPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final tealPaint = Paint()
      ..color = const Color(0xFF115E59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final amberPaint = Paint()
      ..color = const Color(0xFF92400E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Background circle
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;

    // Buruh & Petik ~48%
    final sweep1 = 2 * math.pi * 0.48;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep1, false, greenPaint);
    startAngle += sweep1;

    // Pupuk & Nutrisi ~27%
    final sweep2 = 2 * math.pi * 0.27;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep2, false, indigoPaint);
    startAngle += sweep2;

    // Bibit & Olah Lahan ~17%
    final sweep3 = 2 * math.pi * 0.17;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep3, false, tealPaint);
    startAngle += sweep3;

    // Logistik & Lain ~8%
    final sweep4 = 2 * math.pi * 0.08;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep4, false, amberPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

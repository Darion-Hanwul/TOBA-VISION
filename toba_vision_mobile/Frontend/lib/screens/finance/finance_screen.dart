import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import 'finance_all_musim_screen.dart';
import 'finance_end_screen.dart';
import 'finance_screen_edit_upload.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _selectedPeriod = 0; // 0: Musim Ini, 1: Semua

  final List<String> _periods = ['Musim Ini', 'Semua'];

  // Data Kategori
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Buruh Tani / Upah',
      'amount': 'Rp 6,8 jt',
      'percentage': '48%',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFF065F46),
      'bg': const Color(0xFFD1FAE5),
    },
    {
      'name': 'Pupuk & Nutrisi',
      'amount': 'Rp 3,8 jt',
      'percentage': '27%',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF4338CA),
      'bg': const Color(0xFFE0E7FF),
    },
    {
      'name': 'Bibit & Olah Lahan',
      'amount': 'Rp 2,4 jt',
      'percentage': '17%',
      'icon': Icons.spa_outlined,
      'color': const Color(0xFF115E59),
      'bg': const Color(0xFFCCFBF1),
    },
    {
      'name': 'Lainnya / Tambahan',
      'amount': 'Rp 1,25 jt',
      'percentage': '8%',
      'icon': Icons.category_outlined,
      'color': const Color(0xFF92400E),
      'bg': const Color(0xFFFEF3C7),
    },
  ];

  // Data Riwayat Pengeluaran
  final List<Map<String, dynamic>> _historyItems = [
    {
      'title': 'Upah Petik Daun Bawah',
      'date': '12 Okt 2026 • 8 Pekerja',
      'amount': '-Rp 1.200.000',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFF065F46),
      'bg': const Color(0xFFD1FAE5),
    },
    {
      'title': 'Pupuk ZA & NPK Daun',
      'date': '08 Okt 2026 • Toko Tani Maju',
      'amount': '-Rp 850.000',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF4338CA),
      'bg': const Color(0xFFE0E7FF),
    },
    {
      'title': 'Sewa Traktor Olah Tanah',
      'date': '28 Sep 2026 • Lahan Blok A',
      'amount': '-Rp 600.000',
      'icon': Icons.agriculture_rounded,
      'color': const Color(0xFF115E59),
      'bg': const Color(0xFFCCFBF1),
    },
    {
      'title': 'Beli Tali Bambu & Waring',
      'date': '20 Sep 2026 • Perlengkapan',
      'amount': '-Rp 350.000',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFF92400E),
      'bg': const Color(0xFFFEF3C7),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                backgroundColor: const Color(0xE6F4F7F5),
                showBottomBorder: true,
                trailing: AppHeaderActionButton(
                  icon: Icons.sync_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sinkronisasi data keuangan berhasil diperbarui!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageTitleSection(),
                    const SizedBox(height: 16),
                    _buildCircularSummaryCard(),
                    const SizedBox(height: 20),
                    _buildExpenseCategoryGrid(),
                    const SizedBox(height: 20),
                    _buildPrimaryActionButton(),
                    const SizedBox(height: 20),
                    _buildExpenseHistoryList(),
                    const SizedBox(height: 20),
                    _buildArchiveReportCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Title & Period Chips Filter
  Widget _buildPageTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Biaya & Pengeluaran Kebun',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: Color(0xFF022C22),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola catatan pengeluaran operasional perkebunan dengan jelas dan tenang.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_periods.length, (index) {
              final isSelected = _selectedPeriod == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FinanceAllMusimScreen(),
                        ),
                      );
                    } else {
                      setState(() => _selectedPeriod = index);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF064E3B) : Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF064E3B)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _periods[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // 3. Circular Summary Card (Gauge Progress & Total Biaya)
  Widget _buildCircularSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Circular Progress Ring Simulation
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _RingProgressPainter(),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF065F46), size: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TOTAL BIAYA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
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
            'Estimasi Musim Tanam',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Rp 14.250.000',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: Color(0xFF022C22),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tercatat dari 4 kategori pengeluaran operasional',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Expense Category 2x2 Grid
  Widget _buildExpenseCategoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Rincian Biaya',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '4 Pos Biaya',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x0D022C22)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cat['bg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 16),
                      ),
                      Text(
                        cat['percentage'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat['name'] as String,
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
                        cat['amount'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: cat['color'] as Color,
                        ),
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

  // 5. Primary Action Button (Tambah Catatan Biaya)
  Widget _buildPrimaryActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14532D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FinanceScreenEditUpload(),
            ),
          );

          if (result != null && mounted) {
            setState(() {
              _historyItems.insert(0, {
                'title': result['title'] ?? 'Pengeluaran Baru',
                'date': '${result['date']} • ${result['category']}',
                'amount': result['amount'] ?? '-Rp 0',
                'icon': Icons.receipt_long_rounded,
                'color': const Color(0xFF065F46),
                'bg': const Color(0xFFD1FAE5),
              });
            });
          }
        },
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: const Text(
          'Tambah Catatan Biaya',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // 6. Expense History List (Riwayat Catatan Pengeluaran)
  Widget _buildExpenseHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Pengeluaran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Terbaru',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historyItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _historyItems[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x0D022C22)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item['bg'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['date'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['amount'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF064E3B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF8FAFC)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMiniButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        bg: const Color(0xFFF8FAFC),
                        fg: const Color(0xFF334155),
                        border: const Color(0xFFE2E8F0),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FinanceScreenEditUpload(
                                initialData: item,
                              ),
                            ),
                          );

                          if (result != null && mounted) {
                            setState(() {
                              item['title'] = result['title'];
                              item['amount'] = result['amount'];
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildMiniButton(
                        label: 'Hapus',
                        icon: Icons.delete_outline_rounded,
                        bg: const Color(0xFFFFF1F2),
                        fg: const Color(0xFFBE123C),
                        border: const Color(0xFFFFE4E6),
                        onTap: () => _confirmDeleteItem(index, item),
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

  void _confirmDeleteItem(int index, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFBE123C)),
            SizedBox(width: 8),
            Text(
              'Hapus Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus catatan "${item['title']}" sebesar ${item['amount']}?',
              style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFBE123C), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final deletedTitle = item['title'];
              setState(() {
                _historyItems.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Catatan "$deletedTitle" berhasil dihapus!'),
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
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Archive / Tutup Buku Section Card
  Widget _buildArchiveReportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4E6)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.archive_outlined, color: Color(0xFFBE123C), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tutup Buku Musim',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFFFFE4E6)),
                          ),
                          child: const Text(
                            'Akhir Musim',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tutup buku pengeluaran dan simpan rekap akhir musim ini ke arsip laporan perkebunan.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F2),
                foregroundColor: const Color(0xFFBE123C),
                side: const BorderSide(color: Color(0xFFFFE4E6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinanceEndScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_outline_rounded, size: 16),
              label: const Text(
                'Tutup Buku & Simpan Rekap',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter untuk Circular Gauge Ring Progress
class _RingProgressPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 11.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final greenPaint = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final indigoPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background Full Circle
    canvas.drawCircle(center, radius, bgPaint);

    // Green Arc (Segmen Buruh Tani ~48%)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.0,
      false,
      greenPaint,
    );

    // Indigo Arc (Segmen Pupuk & Nutrisi ~27%)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi / 2,
      math.pi * 0.55,
      false,
      indigoPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

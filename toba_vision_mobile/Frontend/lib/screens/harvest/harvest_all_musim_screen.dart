import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import 'harvest_screen.dart';

class HarvestAllMusimScreen extends StatefulWidget {
  const HarvestAllMusimScreen({super.key});

  @override
  State<HarvestAllMusimScreen> createState() => _HarvestAllMusimScreenState();
}

class _HarvestAllMusimScreenState extends State<HarvestAllMusimScreen> {
  // Data Riwayat Semua Musim Panen Tembakau (Keuntungan Mentah & Siklus 7 Petikan Daun)
  final List<Map<String, dynamic>> _seasonHistory = [
    {
      'title': 'Musim Ketiga (2024)',
      'period': 'Mei - Okt 2024 • Lahan Blok A & B',
      'weight': '3.200 kg tembakau',
      'revenue': 'Rp 88.500.000',
      'cycles': '7/7 Petikan Selesai',
      'status': 'Selesai',
      'stageDetails': [
        {'stage': 'P1', 'label': 'Daun Pasir (Bawah 1)', 'weight': '450 kg', 'revenue': 'Rp 11.250.000'},
        {'stage': 'P2', 'label': 'Daun Bawah 2', 'weight': '510 kg', 'revenue': 'Rp 12.750.000'},
        {'stage': 'P3', 'label': 'Daun Tengah Utama (Prima)', 'weight': '860 kg', 'revenue': 'Rp 27.520.000'},
        {'stage': 'P4', 'label': 'Daun Tengah 2', 'weight': '620 kg', 'revenue': 'Rp 18.600.000'},
        {'stage': 'P5', 'label': 'Daun Atas', 'weight': '420 kg', 'revenue': 'Rp 10.920.000'},
        {'stage': 'P6', 'label': 'Pucuk Daun', 'weight': '230 kg', 'revenue': 'Rp 5.290.000'},
        {'stage': 'P7', 'label': 'Pemetikan Akhir', 'weight': '110 kg', 'revenue': 'Rp 2.170.000'},
      ],
    },
    {
      'title': 'Musim Kedua (2023)',
      'period': 'Mei - Sep 2023 • Lahan Blok A',
      'weight': '2.850 kg tembakau',
      'revenue': 'Rp 78.000.000',
      'cycles': '7/7 Petikan Selesai',
      'status': 'Selesai',
      'stageDetails': [
        {'stage': 'P1', 'label': 'Daun Pasir (Bawah 1)', 'weight': '400 kg', 'revenue': 'Rp 9.600.000'},
        {'stage': 'P2', 'label': 'Daun Bawah 2', 'weight': '460 kg', 'revenue': 'Rp 11.500.000'},
        {'stage': 'P3', 'label': 'Daun Tengah Utama (Prima)', 'weight': '780 kg', 'revenue': 'Rp 24.180.000'},
        {'stage': 'P4', 'label': 'Daun Tengah 2', 'weight': '550 kg', 'revenue': 'Rp 16.500.000'},
        {'stage': 'P5', 'label': 'Daun Atas', 'weight': '380 kg', 'revenue': 'Rp 9.880.000'},
        {'stage': 'P6', 'label': 'Pucuk Daun', 'weight': '190 kg', 'revenue': 'Rp 4.370.000'},
        {'stage': 'P7', 'label': 'Pemetikan Akhir', 'weight': '90 kg', 'revenue': 'Rp 1.970.000'},
      ],
    },
    {
      'title': 'Musim Pertama (2022)',
      'period': 'Jun - Okt 2022 • Lahan Blok A',
      'weight': '2.600 kg tembakau',
      'revenue': 'Rp 68.600.000',
      'cycles': '7/7 Petikan Selesai',
      'status': 'Selesai',
      'stageDetails': [
        {'stage': 'P1', 'label': 'Daun Pasir (Bawah 1)', 'weight': '380 kg', 'revenue': 'Rp 8.740.000'},
        {'stage': 'P2', 'label': 'Daun Bawah 2', 'weight': '420 kg', 'revenue': 'Rp 10.080.000'},
        {'stage': 'P3', 'label': 'Daun Tengah Utama (Prima)', 'weight': '710 kg', 'revenue': 'Rp 21.300.000'},
        {'stage': 'P4', 'label': 'Daun Tengah 2', 'weight': '500 kg', 'revenue': 'Rp 14.500.000'},
        {'stage': 'P5', 'label': 'Daun Atas', 'weight': '350 kg', 'revenue': 'Rp 8.750.000'},
        {'stage': 'P6', 'label': 'Pucuk Daun', 'weight': '160 kg', 'revenue': 'Rp 3.520.000'},
        {'stage': 'P7', 'label': 'Pemetikan Akhir', 'weight': '80 kg', 'revenue': 'Rp 1.710.000'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppHeader(
        showBack: true,
        title: 'Rekap Semua Musim Panen',
        backgroundColor: const Color(0xE6F4F7F5),
        showBottomBorder: true,
        trailing: AppHeaderActionButton(
          icon: Icons.sync_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sinkronisasi data panen semua musim berhasil diperbarui!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccumulatedHeaderCard(),
              const SizedBox(height: 24),
              _buildSeasonHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header Akumulasi Panen Semua Musim
  Widget _buildAccumulatedHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.agriculture_rounded, size: 12, color: Color(0xFF064E3B)),
                    SizedBox(width: 4),
                    Text(
                      'TOTAL AKUMULASI PANEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  '3 Musim Selesai',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '8.650 kg',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: Color(0xFF064E3B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total Keuntungan Kotor Mentah: Rp 235.100.000',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Akumulasi dari 21 kali siklus pemetikan daun tembakau (7 petikan per musim tanam).',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Riwayat Musim Panen Section
  Widget _buildSeasonHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Riwayat Musim Panen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Catatan 7 siklus petikan daun tembakau tiap musim',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                '7 Petikan / Musim',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF064E3B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          season['title'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF166534)),
                            const SizedBox(width: 4),
                            Text(
                              season['status'] as String,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    season['period'] as String,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        season['revenue'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${season['weight']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          season['cycles'] as String,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        bg: const Color(0xFFF0FDF4),
                        fg: const Color(0xFF166534),
                        border: const Color(0xFFBBF7D0),
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HarvestScreen()),
                            );
                          }
                        },
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

  Widget _buildMiniButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  void _showSeasonDetail(Map<String, dynamic> season) {
    final stages = (season['stageDetails'] as List<dynamic>?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
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
                      '7 Petikan Lengkap',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(season['period'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Divider(height: 24),
              _buildDetailRow('Total Hasil Bobot Panen', season['weight'] as String, isBold: true),
              const SizedBox(height: 8),
              _buildDetailRow('Total Pendapatan Kotor Mentah', season['revenue'] as String, isBold: true, valueColor: const Color(0xFF166534)),
              const SizedBox(height: 8),
              _buildDetailRow('Siklus Tembakau', '7 Petikan Daun (P1 s/d P7) Selesai'),
              const Divider(height: 24),
              const Text(
                'Rincian 7 Tahap Siklus Petikan Daun:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              ...stages.map((stg) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stg['stage'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF064E3B)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stg['label'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stg['weight'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF064E3B)),
                          ),
                          Text(
                            stg['revenue'] as String,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? (isBold ? const Color(0xFF064E3B) : const Color(0xFF1E293B)),
          ),
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
              'Hapus Arsip Panen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data panen "${season['title']}"? Seluruh riwayat timbangan 7 siklus petikan akan dihapus.',
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
              setState(() => _seasonHistory.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data "$deletedTitle" berhasil dihapus!'),
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
}

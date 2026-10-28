import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import 'harvest_edit_screen.dart';

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  int _activeStep = 3; // Tahap Petikan ke-3 (P3) aktif
  final TextEditingController _weightController = TextEditingController(text: '850');
  final TextEditingController _revenueController = TextEditingController(text: '68.600.000');

  // 7 Tahapan Petikan Daun Tembakau
  final List<String> _stages = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];

  // Distribusi Pendapatan per Petikan (Tinggi Bar Chart dan Nominal)
  final List<Map<String, dynamic>> _chartData = [
    {'stage': 'P1', 'weight': '480 kg', 'height': 48.0, 'isDone': true},
    {'stage': 'P2', 'weight': '520 kg', 'height': 52.0, 'isDone': true},
    {'stage': 'P3', 'weight': '850 kg', 'height': 68.0, 'isActive': true},
    {'stage': 'P4', 'weight': '-', 'height': 20.0, 'isUpcoming': true},
    {'stage': 'P5', 'weight': '-', 'height': 18.0, 'isUpcoming': true},
    {'stage': 'P6', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
    {'stage': 'P7', 'weight': '-', 'height': 12.0, 'isUpcoming': true},
  ];

  @override
  void dispose() {
    _weightController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                backgroundColor: const Color(0xFFF7F9FB),
                logoIcon: Icons.agriculture_rounded,
                logoBg: const Color(0xFFA7F3D0),
                trailing: AppHeaderActionButton(
                  icon: Icons.sync_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sinkronisasi data panen petani berhasil diperbarui!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildStepTrackerCard(),
                    const SizedBox(height: 16),
                    _buildMilestoneProfitCard(),
                    const SizedBox(height: 16),
                    _buildWeighingInputCard(),
                    const SizedBox(height: 20),
                    _buildCtaButtonSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Title Section (Location Tag & Title & Description)
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F0F8),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF064E3B)),
              SizedBox(width: 4),
              Text(
                'Lahan Blok A • Temanggung',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF064E3B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Monitoring Siklus Panen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF064E3B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pantau dan catat bobot pemetikan daun tembakau secara berkala.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // 3. Tahap Petikan Daun Card (Horizontal 7-Step Tracker)
  Widget _buildStepTrackerCard() {
    return Container(
      width: double.infinity,
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
              const Text(
                'Siklus Petikan Daun',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.eco_rounded, size: 12, color: Color(0xFF064E3B)),
                    SizedBox(width: 4),
                    Text(
                      'P3 Aktif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7-Step Horizontal Tracker with Line
          SizedBox(
            height: 67,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track Lines
                Positioned(
                  top: 17,
                  left: 18,
                  right: 18,
                  child: Row(
                    children: [
                      // Segment 1-2 (Done Green)
                      Expanded(
                        child: Container(height: 2.5, color: const Color(0xFF166534)),
                      ),
                      // Segment 2-3 (Active Amber)
                      Expanded(
                        child: Container(height: 2.5, color: const Color(0xFFF59E0B)),
                      ),
                      // Segment 3-7 (Upcoming Gray)
                      Expanded(
                        flex: 4,
                        child: Container(height: 2.5, color: const Color(0xFFE2E8F0)),
                      ),
                    ],
                  ),
                ),

                // 7 Step Nodes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_stages.length, (index) {
                    final stepNum = index + 1;
                    final isDone = stepNum < _activeStep;
                    final isActive = stepNum == _activeStep;

                    return GestureDetector(
                      onTap: () async {
                        setState(() => _activeStep = stepNum);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HarvestEditScreen(
                              initialStep: stepNum,
                              stageName: _stages[index],
                            ),
                          ),
                        );

                        if (result != null && mounted) {
                          setState(() {
                            _weightController.text = result['weight'] ?? _weightController.text;
                            _revenueController.text = result['revenue'] ?? _revenueController.text;
                          });
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF166534)
                                  : isActive
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFF8FAFC),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF166534)
                                    : isActive
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFE2E8F0),
                                width: isActive ? 3 : 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : Text(
                                      '$stepNum',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isActive ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stages[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? const Color(0xFFD97706) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Milestone BEP & Estimasi Keuntungan Bersih Card + Bar Chart
  Widget _buildMilestoneProfitCard() {
    return Container(
      width: double.infinity,
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Target Keuntungan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          'TARGET 40 JT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Pencapaian Modal & Profit Bersih',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      'Rp 32,6 jt',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    Text(
                      '81,6% Tercapai',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Milestone Bar BEP
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.flag_rounded, size: 14, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text('BEP: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        Text('Modal Rp 25 jt Lunas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF064E3B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        'BEP TERCAPAI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Bar Segment
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    height: 14,
                    color: const Color(0xFFE2E8F0),
                    child: Row(
                      children: [
                        // Modal BEP 62.5%
                        Container(
                          width: 175,
                          color: const Color(0xFF94A3B8),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 6),
                          child: const Text(
                            'MODAL',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        // Murni Untung
                        Expanded(
                          child: Container(
                            color: const Color(0xFF166534),
                            alignment: Alignment.center,
                            child: const Text(
                              'UNTUNG',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Modal: Rp 25.000.000', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                      ],
                    ),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF166534), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Untung: +Rp 7.660.000', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF064E3B))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Subheading Distribusi Pendapatan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Distribusi Hasil Petikan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              Text(
                'Per Tahapan (kg)',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bar Chart Distribusi
          Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _chartData.map((data) {
                final isActive = data['isActive'] == true;
                final isDone = data['isDone'] == true;
                final height = data['height'] as double;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['weight'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFFD97706)
                            : isDone
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 26,
                      height: height,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFF59E0B)
                            : isDone
                                ? const Color(0xFF166534)
                                : const Color(0xFFE2E8F0),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['stage'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFFD97706)
                            : isDone
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Estimasi Keuntungan Bersih Saat Ini Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                  ),
                  child: const Icon(Icons.savings_outlined, color: Color(0xFFA7F3D0), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Text(
                          'ESTIMASI LABA BERSIH',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '+Rp 7.660.000',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF064E3B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Total pendapatan sudah melampaui seluruh modal operasional.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Timbangan Hari Ini Input Card (Berat & Pendapatan)
  Widget _buildWeighingInputCard() {
    return Container(
      width: double.infinity,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.scale_rounded, color: Color(0xFF064E3B), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Timbangan Petikan P3',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Input hasil panen hari ini',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: const Text(
                  'Hari Ini',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Field Berat Tembakau (kg)
          const Text(
            'Berat Tembakau (kg)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF064E3B),
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const Text(
                  'kg',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bobot bersih hasil timbang petikan daun hari ini',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 14),

          // Field Total Pendapatan (Rp)
          const Text(
            'Total Pendapatan (Rp)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _revenueController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total penerimaan berdasarkan negosiasi mutu daun',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // 6. Section CTA Button & Footer Note
  Widget _buildCtaButtonSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Timbangan ${_weightController.text} kg & pendapatan Rp ${_revenueController.text} berhasil disimpan!'),
                  backgroundColor: const Color(0xFF064E3B),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: const Text(
              'Simpan Catatan Petikan P3',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBE123C), width: 1.5),
              foregroundColor: const Color(0xFFBE123C),
              backgroundColor: const Color(0xFFFFF1F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showCloseCycleDialog,
            icon: const Icon(Icons.lock_clock_outlined, size: 20),
            label: const Text(
              'Tutup Buku Siklus Padi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Data timbangan akan terintegrasi langsung ke buku kas panen perkebunan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  void _showCloseCycleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFBE123C)),
            SizedBox(width: 8),
            Text('Tutup Buku Siklus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menutup buku siklus panen musim ini? Rekap akhir akan diarsipkan dan histori panen akan dikunci.',
          style: TextStyle(fontSize: 13, height: 1.4),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buku siklus berhasil ditutup & diarsipkan!'),
                  backgroundColor: Color(0xFFBE123C),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Ya, Tutup Buku', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

class HarvestEditScreen extends StatefulWidget {
  final int initialStep;
  final String stageName;

  const HarvestEditScreen({
    super.key,
    required this.initialStep,
    required this.stageName,
  });

  @override
  State<HarvestEditScreen> createState() => _HarvestEditScreenState();
}

class _HarvestEditScreenState extends State<HarvestEditScreen> {
  late int _currentStep;
  late TextEditingController _weightController;
  late TextEditingController _revenueController;
  late TextEditingController _noteController;

  final List<String> _stages = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];

  final Map<int, Map<String, String>> _stageDefaults = {
    1: {'weight': '480', 'rev': '38.400.000', 'note': 'Petikan daun pasir / bawah pertama'},
    2: {'weight': '520', 'rev': '42.000.000', 'note': 'Petikan daun bawah kedua'},
    3: {'weight': '850', 'rev': '68.600.000', 'note': 'Petikan daun tengah utama (kualitas prima)'},
    4: {'weight': '600', 'rev': '48.000.000', 'note': 'Petikan daun tengah kedua'},
    5: {'weight': '450', 'rev': '36.000.000', 'note': 'Petikan daun atas'},
    6: {'weight': '320', 'rev': '25.600.000', 'note': 'Petikan pucuk daun'},
    7: {'weight': '200', 'rev': '16.000.000', 'note': 'Petikan akhir / pembersihan'},
  };

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    final defaultData = _stageDefaults[_currentStep] ?? {'weight': '850', 'rev': '68.600.000', 'note': ''};

    _weightController = TextEditingController(text: defaultData['weight']);
    _revenueController = TextEditingController(text: defaultData['rev']);
    _noteController = TextEditingController(text: defaultData['note']);
  }

  void _onSelectStep(int step) {
    setState(() {
      _currentStep = step;
      final defaultData = _stageDefaults[_currentStep] ?? {'weight': '0', 'rev': '0', 'note': ''};
      _weightController.text = defaultData['weight']!;
      _revenueController.text = defaultData['rev']!;
      _noteController.text = defaultData['note']!;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _revenueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageLabel = _stages[_currentStep - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppHeader(
        showBack: true,
        title: 'Edit Catatan Petikan $stageLabel',
        backgroundColor: const Color(0xFFF7F9FB),
        showBottomBorder: true,
        trailing: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFA7F3D0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.agriculture_rounded, color: Color(0xFF064E3B), size: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tahapan Selector Horizontal Tracker
            Container(
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
                        'Pilih Tahapan yang Ingin Diedit',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '$stageLabel Dipilih',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF064E3B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_stages.length, (index) {
                      final stepNum = index + 1;
                      final isSelected = stepNum == _currentStep;

                      return GestureDetector(
                        onTap: () => _onSelectStep(stepNum),
                        child: Column(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _stages[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? const Color(0xFFD97706) : const Color(0xFF64748B),
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

            const SizedBox(height: 20),

            // Form Pengeditan Timbangan & Pendapatan
            Container(
              padding: const EdgeInsets.all(18),
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
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Color(0xFF064E3B), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rincian Hasil Petikan $stageLabel',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Input Berat Tembakau
                  const Text(
                    'Berat Bersih Tembakau (kg)',
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

                  const SizedBox(height: 16),

                  // Input Total Pendapatan
                  const Text(
                    'Total Penerimaan / Pendapatan (Rp)',
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

                  const SizedBox(height: 16),

                  // Catatan Kondisi Mutu Daun
                  const Text(
                    'Keterangan / Kondisi Daun',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Misal: Daun tebal, warna kuning merata, bebas bercak',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.pop(context, {
                    'step': _currentStep,
                    'stage': stageLabel,
                    'weight': _weightController.text,
                    'revenue': _revenueController.text,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data petikan $stageLabel berhasil diperbarui!'),
                      backgroundColor: const Color(0xFF064E3B),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  'Simpan Perubahan $stageLabel',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFECEEF0),
                  foregroundColor: const Color(0xFF191C1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';

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
                AppHeader(
                  showBack: true,
                  title: 'EDIT PETIKAN $stageLabel',
                  subtitle: 'SIKLUS PANEN // TEMBAKAU',
                  padding: EdgeInsets.zero,
                  height: null,
                  trailing: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: const Icon(Icons.agriculture_rounded, color: AppColors.ink, size: 18),
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Selector Tahapan Siklus Petikan (P1..P7)
                RetroCard(
                  tapeTag: 'PILIH TAHAPAN PETIKAN',
                  rightTag: '$stageLabel AKTIF',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Pilih Tahapan yang Ingin Diedit',
                              style: AppTypography.display(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.ink, width: 1.2),
                            ),
                            child: MicroText.bold(
                              '$stageLabel DIPILIH',
                              color: AppColors.ink,
                              size: 9.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Jejeran tombol track kaset P1-P7
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(_stages.length, (index) {
                            final stepNum = index + 1;
                            final isSelected = stepNum == _currentStep;
                            final stageCode = _stages[index];

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _onSelectStep(stepNum),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 48,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.orange : AppColors.paper,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.ink, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.ink,
                                        offset: isSelected ? const Offset(1, 1) : const Offset(2.5, 2.5),
                                      ),
                                    ],
                                  ),
                                  child: Transform.translate(
                                    offset: isSelected ? const Offset(1, 1) : Offset.zero,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$stepNum',
                                          style: AppTypography.mono(
                                            size: 16,
                                            weight: FontWeight.w900,
                                            color: isSelected ? Colors.white : AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          stageCode,
                                          style: AppTypography.mono(
                                            size: 10,
                                            weight: FontWeight.w700,
                                            color: isSelected ? Colors.white : AppColors.ink.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.ink.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.ink),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _stageDefaults[_currentStep]?['note'] ?? 'Catatan tahap $stageLabel',
                                style: AppTypography.mono(
                                  size: 10.5,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Form Rincian Timbangan & Pendapatan
                RetroCard(
                  tapeTag: 'INPUT DATA // $stageLabel',
                  rightTag: 'TIMBANGAN FISIK',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.ink, width: 1.5),
                            ),
                            child: const Icon(Icons.edit_note_rounded, color: AppColors.ink, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rincian Hasil Petikan $stageLabel',
                            style: AppTypography.display(
                              size: 15,
                              weight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const TaperedDivider(),
                      const SizedBox(height: 14),

                      // Input Berat Bersih Tembakau
                      MicroText.bold('BERAT BERSIH TEMBAKAU (KG)', color: AppColors.ink),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                          boxShadow: const [
                            BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.scale_outlined, size: 18, color: AppColors.ink),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                                style: AppTypography.mono(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: AppTypography.mono(color: Colors.black26),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.ink, width: 1.2),
                              ),
                              child: MicroText.bold('KG', color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input Total Penerimaan / Pendapatan
                      MicroText.bold('TOTAL PENERIMAAN / PENDAPATAN (RP)', color: AppColors.ink),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                          boxShadow: const [
                            BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 18, color: AppColors.ink),
                            const SizedBox(width: 10),
                            Text(
                              'Rp ',
                              style: AppTypography.mono(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _revenueController,
                                keyboardType: TextInputType.number,
                                style: AppTypography.mono(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: AppTypography.mono(color: Colors.black26),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input Keterangan / Kondisi Daun
                      MicroText.bold('KETERANGAN / KONDISI DAUN', color: AppColors.ink),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                          boxShadow: const [
                            BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                          ],
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 2,
                          style: AppTypography.body(size: 13, color: AppColors.ink),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Misal: Daun tebal, warna kuning merata, bebas bercak',
                            hintStyle: AppTypography.body(size: 12, color: Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Tombol Aksi (Simpan & Batal)
                TrapezoidTabButton(
                  label: '----SIMPAN CATATAN PETIKAN $stageLabel----',
                  color: AppColors.orange,
                  textColor: Colors.white,
                  height: 48,
                  onTap: () {
                    Navigator.pop(context, {
                      'step': _currentStep,
                      'stage': stageLabel,
                      'weight': _weightController.text,
                      'revenue': _revenueController.text,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Data petikan $stageLabel berhasil diperbarui!',
                          style: AppTypography.mono(size: 12, color: Colors.white),
                        ),
                        backgroundColor: AppColors.ink,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Tombol Batal bergaya tape-deck fisik
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.ink, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'BATAL & KEMBALI',
                        style: AppTypography.mono(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
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
}

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/auth_session.dart';
import '../../data/firestore_models.dart';
import '../../data/firestore_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';

class HarvestEditScreen extends StatefulWidget {
  final int initialStep;
  final String stageName;
  final int maxUnlockedStep;
  final String? initialWeight;
  final String? initialRevenue;
  final String? initialNote;

  const HarvestEditScreen({
    super.key,
    required this.initialStep,
    required this.stageName,
    this.maxUnlockedStep = 7,
    this.initialWeight,
    this.initialRevenue,
    this.initialNote,
  });

  @override
  State<HarvestEditScreen> createState() => _HarvestEditScreenState();
}

class _HarvestEditScreenState extends State<HarvestEditScreen> {
  late int _currentStep;
  late TextEditingController _weightController;
  late TextEditingController _revenueController;
  late DateTime _selectedDate;
  bool _isSaving = false;
  Map<String, PetikanPanenModel> _savedPetikanMap = {};

  final List<String> _stages = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];

  static const Map<int, String> _stageDescriptions = {
    1: 'Petikan daun pasir / bawah pertama',
    2: 'Petikan daun bawah kedua',
    3: 'Petikan daun tengah utama (kualitas prima)',
    4: 'Petikan daun tengah kedua',
    5: 'Petikan daun atas',
    6: 'Petikan pucuk daun',
    7: 'Petikan akhir / pembersihan',
  };

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _weightController = TextEditingController(text: widget.initialWeight ?? '');
    _revenueController = TextEditingController(text: widget.initialRevenue ?? '');
    _selectedDate = DateTime.now();
    _loadSavedPetikan();
  }

  Future<void> _loadSavedPetikan() async {
    final idPetani = AuthSession.currentIdPetani;
    final idMusim = AuthSession.currentIdMusim;
    if (idPetani.isEmpty || idMusim.isEmpty) return;

    try {
      final list = await FirestoreService.instance.getDaftarPetikan(idPetani, idMusim);
      if (!mounted) return;
      final map = {for (final p in list) p.kodeSiklus: p};
      final current = map[_stages[_currentStep - 1]];
      setState(() {
        _savedPetikanMap = map;
        if (current != null) {
          _selectedDate = current.tanggalPetik;
          if (_weightController.text.isEmpty) {
            _weightController.text = current.beratKg.round().toString();
          }
          if (_revenueController.text.isEmpty) {
            _revenueController.text = current.estimasiPendapatan.round().toString();
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onSelectStep(int step) {
    if (step > widget.maxUnlockedStep) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Petikan P$step masih terkunci! Selesaikan petikan P${widget.maxUnlockedStep} terlebih dahulu.',
                  style: AppTypography.mono(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _currentStep = step;
      final existing = _savedPetikanMap[_stages[step - 1]];
      if (existing != null) {
        _weightController.text = existing.beratKg.round().toString();
        _revenueController.text = existing.estimasiPendapatan.round().toString();
        _selectedDate = existing.tanggalPetik;
      } else {
        _weightController.clear();
        _revenueController.clear();
        _selectedDate = DateTime.now();
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  Future<void> _saveHarvestPetikan(String stageLabel) async {
    final weight = double.tryParse(_weightController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final revenue = double.tryParse(_revenueController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final stageCode = _stages[_currentStep - 1];

    setState(() => _isSaving = true);

    try {
      await FirestoreService.instance.simpanPetikanPanen(
        idPetani: AuthSession.currentIdPetani,
        idMusim: AuthSession.currentIdMusim,
        kodeSiklus: stageCode,
        petikanKe: _currentStep,
        beratKg: weight,
        estimasiPendapatan: revenue,
        tanggalPetik: _selectedDate,
        kondisiDaun: (widget.initialNote?.trim().isNotEmpty ?? false)
            ? widget.initialNote!.trim()
            : null,
      );
    } catch (_) {
      // offline graceful fallback
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, {
          'step': _currentStep,
          'stage': stageCode,
          'weight': _weightController.text,
          'revenue': _revenueController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data petikan $stageCode berhasil disimpan ke database!',
              style: AppTypography.mono(fontSize: 12, color: Colors.white),
            ),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    }
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
                            final isLocked = stepNum > widget.maxUnlockedStep;
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
                                    color: isSelected
                                        ? AppColors.orange
                                        : (isLocked ? const Color(0xFFE2E8F0) : AppColors.paper),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isLocked ? AppColors.muted.withValues(alpha: 0.35) : AppColors.ink,
                                      width: 2,
                                    ),
                                    boxShadow: isLocked
                                        ? null
                                        : [
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
                                            color: isSelected
                                                ? Colors.white
                                                : (isLocked ? AppColors.muted : AppColors.ink),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isLocked) ...[
                                              Icon(Icons.lock_outline_rounded, size: 8, color: AppColors.muted.withValues(alpha: 0.8)),
                                              const SizedBox(width: 2),
                                            ],
                                            Text(
                                              stageCode,
                                              style: AppTypography.mono(
                                                size: 10,
                                                weight: FontWeight.w700,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isLocked ? AppColors.muted : AppColors.ink.withValues(alpha: 0.7)),
                                              ),
                                            ),
                                          ],
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
                                _stageDescriptions[_currentStep] ?? 'Catatan tahap $stageLabel',
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

                      // Input Tanggal Penimbangan / Petikan
                      MicroText.bold('TANGGAL PENIMBANGAN / PETIKAN', color: AppColors.ink),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                              Expanded(
                                child: Text(
                                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                  style: AppTypography.mono(
                                    size: 16,
                                    weight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.ink),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Tombol Aksi (Simpan & Batal)
                TrapezoidTabButton(
                  label: _isSaving
                      ? '----MENYIMPAN DATA...----'
                      : '----SIMPAN CATATAN PETIKAN $stageLabel----',
                  color: AppColors.orange,
                  textColor: Colors.white,
                  height: 48,
                  isLoading: _isSaving,
                  onTap: _isSaving ? null : () => _saveHarvestPetikan(stageLabel),
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

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/status_chip.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';
import '../../widgets/retro/vu_meter_bar.dart';
import 'harvest_all_musim_screen.dart';
import 'harvest_edit_screen.dart';

class HarvestScreen extends StatefulWidget {
  final bool showBack;
  const HarvestScreen({super.key, this.showBack = false});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  int _selectedPeriod = 0; // 0: Musim Ini, 1: Semua
  final List<String> _periods = ['Musim Ini', 'Semua'];

  int _activeStep = 3; // Tahap Petikan ke-3 (P3) aktif
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _weightController = TextEditingController(text: '850');
  final TextEditingController _revenueController = TextEditingController(text: '68.600.000');

  final List<String> _stages = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];

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
                // 1. Header
                AppHeader(
                  showBack: widget.showBack,
                  title: 'PANEN & HASIL PETIK',
                  subtitle: 'LAHAN BLOK A • TEMANGGUNG',
                  padding: EdgeInsets.zero,
                  height: null,
                  logoSize: 40,
                  logoIcon: Icons.agriculture_rounded,
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
                const SizedBox(height: 12),

                // Judul & Deskripsi
                Text(
                  'Monitoring Siklus Panen',
                  style: AppTypography.display(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau dan catat bobot pemetikan daun tembakau secara berkala.',
                  style: AppTypography.body(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 14),

                // 2. Filter Periode Musim
                _buildPeriodSelector(),
                const SizedBox(height: 14),

                // 3. Stepper 7 Tahapan Siklus Petikan Daun (P1 s/d P7)
                _buildStepTrackerCard(),
                const SizedBox(height: 16),

                // 4. Milestone BEP & Target Keuntungan (VuMeterBar & Equalizer)
                _buildMilestoneProfitCard(),
                const SizedBox(height: 16),

                // 5. Timbangan Hari Ini Input Card
                _buildWeighingInputCard(),
                const SizedBox(height: 20),

                // 6. Tombol Aksi Simpan & Tutup Buku Siklus
                _buildCtaButtonSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MicroText('PILIH PERIODE // SIKLUS', fontSize: 9.5),
        const SizedBox(height: 8),
        Row(
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
                        builder: (context) => const HarvestAllMusimScreen(),
                      ),
                    ).then((_) {
                      if (mounted) setState(() => _selectedPeriod = 0);
                    });
                  } else {
                    setState(() => _selectedPeriod = index);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: AppColors.lime, offset: Offset(2, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded, color: AppColors.lime, size: 14),
                        const SizedBox(width: 4),
                      ],
                      MicroText(
                        _periods[index],
                        fontSize: 10,
                        color: isSelected ? AppColors.paper : AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepTrackerCard() {
    return RetroCard(
      tapeTag: 'SIKLUS PETIKAN // 7 TAHAP',
      rightTag: 'P$_activeStep AKTIF',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Siklus Petikan Daun',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              const StatusChip(label: 'P3 AKTIF PRIMA', variant: StatusChipVariant.lime),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Step Button Bar Ala Tape-Deck Track Select
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
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
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.orange
                          : isDone
                              ? AppColors.lime
                              : AppColors.paper,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      boxShadow: isActive
                          ? const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$stepNum',
                          style: AppTypography.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isActive ? Colors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        MicroText(
                          _stages[index],
                          fontSize: 9,
                          color: isActive ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProfitCard() {
    return RetroCard(
      tapeTag: 'MILESTONE // PROFIT & BEP',
      rightTag: 'TARGET 40 JT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MicroText('PENCAPAIAN MODAL & PROFIT BERSIH', fontSize: 9, color: AppColors.muted),
                    const SizedBox(height: 2),
                    Text(
                      'Rp 32,6 jt',
                      style: AppTypography.display(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusChip(label: 'BEP TERCAPAI', variant: StatusChipVariant.lime),
            ],
          ),
          const SizedBox(height: 10),

          // Equalizer VuMeterBar 81.6%
          const VuMeterBar(
            value: 0.816,
            height: 10,
            totalSegments: 16,
            label: 'TARGET LABA 40 JT',
            valueText: '81,6% TERCAPAI',
          ),
          const SizedBox(height: 12),

          // Info Box Modal Lunas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.flag_rounded, size: 16, color: AppColors.forest),
                    SizedBox(width: 6),
                    MicroText(
                      'MODAL RP 25 JT LUNAS',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ],
                ),
                const MicroText(
                  'UNTUNG +RP 7,66 JT',
                  fontSize: 9.5,
                  color: AppColors.forest,
                  fontWeight: FontWeight.w900,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Equalizer Bar Chart Distribusi Hasil Petikan
          const TaperedDivider(centerLabel: 'DISTRIBUSI PETIKAN (KG)'),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _chartData.map((data) {
                final isActive = data['isActive'] == true;
                final isDone = data['isDone'] == true;
                final height = data['height'] as double;

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          data['weight'] as String,
                          style: AppTypography.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: isActive ? AppColors.orange : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: height,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.orange
                              : isDone
                                  ? AppColors.lime
                                  : const Color(0xFFE2E8F0),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          border: Border.all(color: AppColors.ink, width: 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: MicroText(
                          data['stage'] as String,
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                          color: isActive ? AppColors.orange : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeighingInputCard() {
    return RetroCard(
      tapeTag: 'TIMBANGAN // PETIKAN P3',
      rightTag: 'HARI INI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Timbangan Petikan P3',
                  style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              const StatusChip(label: 'HARI INI', variant: StatusChipVariant.dark, fontSize: 8),
            ],
          ),
          const SizedBox(height: 10),

          // Field Berat Tembakau (kg)
          const MicroText('BERAT TEMBAKAU (KG)', fontSize: 9.5),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.mono(fontSize: 16, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('KG', style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Field Total Pendapatan (Rp)
          const MicroText('TOTAL ESTIMASI PENDAPATAN KOTOR (RP)', fontSize: 9.5),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Rp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ),
                Expanded(
                  child: TextField(
                    controller: _revenueController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.mono(fontSize: 16, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Field Tanggal Penimbangan / Petikan
          const MicroText('TANGGAL PENIMBANGAN / PETIKAN', fontSize: 9.5),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    style: AppTypography.mono(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButtonSection() {
    return Column(
      children: [
        // Tombol Simpan CTA Trapesium Oranye
        TrapezoidTabButton(
          label: 'SIMPAN PETIKAN P3',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Timbangan ${_weightController.text} kg & pendapatan Rp ${_revenueController.text} (${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}) tersimpan!'),
                backgroundColor: AppColors.ink,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Bagian Tutup Buku Musim
        _buildCloseBookBanner(),
      ],
    );
  }

  Widget _buildCloseBookBanner() {
    return RetroCard(
      tapeTag: 'TUTUP BUKU // AKHIR MUSIM',
      rightTag: 'FINAL REKAP',
      backgroundColor: const Color(0xFFFFF1F2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tutup Buku & Arsipkan Musim Ini',
            style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.red),
          ),
          const SizedBox(height: 4),
          Text(
            'Tutup buku pengeluaran dan simpan rekap akhir musim ini ke arsip laporan perkebunan.',
            style: AppTypography.body(fontSize: 11.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TrapezoidTabButton(
            label: 'TUTUP BUKU & SIMPAN REKAP',
            backgroundColor: AppColors.red,
            textColor: Colors.white,
            height: 40,
            onPressed: _showCloseCycleDialog,
          ),
        ],
      ),
    );
  }

  void _showCloseCycleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('TUTUP BUKU SIKLUS', style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.red)),
        content: Text(
          'Apakah Anda yakin ingin menutup buku siklus panen musim ini? Rekap akhir akan diarsipkan dan histori panen akan dikunci.',
          style: AppTypography.body(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: AppTypography.mono(fontSize: 11, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buku siklus berhasil ditutup & diarsipkan!')),
              );
            },
            child: Text('YA, TUTUP BUKU', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

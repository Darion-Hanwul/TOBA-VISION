import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/auth_session.dart';
import '../../data/firestore_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/status_chip.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';
import 'finance_screen.dart';

class FinanceAllMusimScreen extends StatefulWidget {
  const FinanceAllMusimScreen({super.key});

  /// Menentukan status selesai musim secara konsisten di header & badge kartu arsip.
  @visibleForTesting
  static bool isSeasonCompleted(Map<String, dynamic> season) {
    if (season['isSelesai'] == true) return true;
    final normalized = (season['status'] as String? ?? '').trim().toUpperCase();
    return normalized == 'SELESAI' || normalized == 'SUDAH SELESAI';
  }

  @override
  State<FinanceAllMusimScreen> createState() => _FinanceAllMusimScreenState();
}

class _FinanceAllMusimScreenState extends State<FinanceAllMusimScreen> {
  String _totalAccumulated = 'Rp 0';
  double _totalBuruh = 0;
  double _totalPupuk = 0;
  double _totalBibit = 0;
  double _totalLainnya = 0;
  int _totalMusimCount = 0;
  final List<Map<String, dynamic>> _seasonHistory = [];

  @override
  void initState() {
    super.initState();
    _loadMusimFromFirestore();
  }

  Future<void> _loadMusimFromFirestore() async {
    try {
      final list = await FirestoreService.instance.getSemuaMusim(AuthSession.currentIdPetani);
      if (!mounted) return;

      double totalSemua = 0.0;
      double buruhSemua = 0.0;
      double pupukSemua = 0.0;
      double bibitSemua = 0.0;
      double lainnyaSemua = 0.0;
      final List<Map<String, dynamic>> loadedHistory = [];

      for (final m in list) {
        // Ambil data pengeluaran asli per kategori dari subkoleksi biaya_operasional
        final biayaList = await FirestoreService.instance.getDaftarBiaya(AuthSession.currentIdPetani, m.idMusim);

        double mBuruh = 0.0;
        double mPupuk = 0.0;
        double mBibit = 0.0;
        double mLainnya = 0.0;
        double mTotal = 0.0;

        for (final b in biayaList) {
          mTotal += b.jumlahBiaya;
          switch (b.kodeKategori) {
            case 'BURUH':
              mBuruh += b.jumlahBiaya;
              break;
            case 'PUPUK':
              mPupuk += b.jumlahBiaya;
              break;
            case 'BIBIT':
              mBibit += b.jumlahBiaya;
              break;
            case 'LAINNYA':
            default:
              mLainnya += b.jumlahBiaya;
              break;
          }
        }

        final double seasonTotal = (biayaList.isNotEmpty || mTotal > 0) ? mTotal : m.totalPengeluaranCache;

        totalSemua += seasonTotal;
        buruhSemua += mBuruh;
        pupukSemua += mPupuk;
        bibitSemua += mBibit;
        lainnyaSemua += mLainnya;

        final bool isSelesai = m.status.trim().toUpperCase() == 'SELESAI';
        final createdDate = tanggalIndonesia(m.tanggalMulai);

        loadedHistory.add({
          'idMusim': m.idMusim,
          'seasonNumber': m.nomorMusim,
          'title': m.judulMusim,
          'createdDate': createdDate,
          'period': 'Dibuat: $createdDate • ${m.lokasiBlok}',
          'expenses': 'Rp ${_formatAngka(seasonTotal)}',
          'harvest': '${m.totalBobotPanenCache.toStringAsFixed(0)} kg tembakau',
          'status': isSelesai ? 'Sudah Selesai' : 'Belum Selesai',
          'isSelesai': isSelesai,
          'labor': 'Rp ${_formatAngka(mBuruh)}',
          'fertilizer': 'Rp ${_formatAngka(mPupuk)}',
          'seed': 'Rp ${_formatAngka(mBibit)}',
          'other': 'Rp ${_formatAngka(mLainnya)}',
        });
      }

      if (!mounted) return;
      setState(() {
        _seasonHistory.clear();
        _seasonHistory.addAll(loadedHistory);
        _totalMusimCount = list.length;
        _totalAccumulated = 'Rp ${_formatAngka(totalSemua)}';
        _totalBuruh = buruhSemua;
        _totalPupuk = pupukSemua;
        _totalBibit = bibitSemua;
        _totalLainnya = lainnyaSemua;
      });
    } catch (_) {}
  }

  String _formatAngka(double val) {
    final intVal = val.round();
    final s = intVal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]}.');
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
                // Header dengan tombol Sinkronisasi
                AppHeader(
                  showBack: true,
                  title: 'REKAP SEMUA MUSIM',
                  subtitle: 'ARSIP KEUANGAN // PERKEBUNAN',
                  padding: EdgeInsets.zero,
                  height: null,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () async {
                      await _loadMusimFromFirestore();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sinkronisasi data semua musim berhasil diperbarui!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Kartu Akumulasi Biaya Semua Musim
                _buildAccumulatedHeaderCard(),
                const SizedBox(height: 16),

                // 2. Daftar Riwayat Arsip Musim Tanam
                _buildSeasonHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccumulatedHeaderCard() {
    return RetroCard(
      tapeTag: 'TOTAL AKUMULASI // $_totalMusimCount MUSIM TANAM',
      rightTag: 'ARSIP KAS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroText('TOTAL AKUMULASI BIAYA', fontSize: 9.5, color: AppColors.muted),
          const SizedBox(height: 4),
          Text(
            _totalAccumulated,
            style: AppTypography.display(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          const TaperedDivider(centerLabel: 'KATEGORI AKUMULASI'),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildSmallCategoryPill('Buruh & Petik', 'Rp ${_formatAngka(_totalBuruh)}', AppColors.forest),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallCategoryPill('Pupuk & Nutrisi', 'Rp ${_formatAngka(_totalPupuk)}', AppColors.limeDeep),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSmallCategoryPill('Bibit & Olah', 'Rp ${_formatAngka(_totalBibit)}', AppColors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallCategoryPill('Lainnya/Alat', 'Rp ${_formatAngka(_totalLainnya)}', AppColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCategoryPill(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroText(title, fontSize: 8.5, color: color, fontWeight: FontWeight.w800),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.mono(fontSize: 9.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSeasonHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TaperedDivider(centerLabel: 'RIWAYAT MUSIM TANAM // ARSIP'),
        const SizedBox(height: 6),
        if (_seasonHistory.isEmpty)
          RetroCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.muted, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'BELUM ADA ARSIP KEUANGAN',
                  style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const MicroText(
                  'Belum ada riwayat musim tanam terdahulu.\nData rekap kas akan diarsipkan saat buku siklus musim ditutup.',
                  fontSize: 9.5,
                  color: AppColors.muted,
                ),
              ],
            ),
          )
        else
          ..._seasonHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final season = entry.value;
            final isSelesai = FinanceAllMusimScreen.isSeasonCompleted(season);
            final statusLabel = isSelesai ? 'SUDAH SELESAI' : 'BELUM SELESAI';

            return RetroCard(
              tapeTag: 'ARSIP TAHUNAN // REKAP',
              rightTag: statusLabel,
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          season['title'] as String,
                          style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: statusLabel,
                        variant: isSelesai ? StatusChipVariant.dark : StatusChipVariant.orange,
                        fontSize: 8.5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Flexible(
                          child: MicroText(
                            'DIBUAT: ${(season['createdDate'] ?? season['period'] ?? '-').toString()}',
                            fontSize: 9,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      season['expenses'] as String,
                      style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${season['harvest']}',
                      style: AppTypography.mono(fontSize: 11, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.ink, height: 1, thickness: 1),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMiniActionBtn('DETAIL', Icons.visibility_outlined, AppColors.paper, () => _showSeasonDetail(season)),
                    const SizedBox(width: 6),
                    _buildMiniActionBtn('EDIT', Icons.edit_outlined, AppColors.lime, () => _applyAndReturnSeason(season)),
                    const SizedBox(width: 6),
                    _buildMiniActionBtn('HAPUS', Icons.delete_outline_rounded, const Color(0xFFFED7AA), () => _confirmDeleteSeason(index, season)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniActionBtn(String label, IconData icon, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.ink, width: 1.2),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.ink),
            const SizedBox(width: 4),
            MicroText(label, fontSize: 8.5, color: AppColors.ink, fontWeight: FontWeight.w900),
          ],
        ),
      ),
    );
  }

  void _applyAndReturnSeason(Map<String, dynamic> season) {
    final idMusim = season['idMusim'] as String?;
    if (idMusim != null && idMusim.isNotEmpty) {
      AuthSession.setActiveMusim(idMusim);
      FirestoreService.instance.setMusimAktif(AuthSession.currentIdPetani, idMusim);
    }
    FinanceDataStore.activeSeasonData = season;
    final seasonNum = season['seasonNumber'] as int?;
    final rawTitle = season['title'] as String? ?? '';
    final lowerTitle = rawTitle.toLowerCase();

    if (seasonNum == 3 || lowerTitle.contains('ketiga') || lowerTitle.contains('musim 3')) {
      FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran Musim 3';
    } else if (seasonNum == 2 || lowerTitle.contains('kedua') || lowerTitle.contains('musim 2')) {
      FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran Musim 2';
    } else if (seasonNum == 1 || lowerTitle.contains('pertama') || lowerTitle.contains('kesatu') || lowerTitle.contains('musim 1')) {
      FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran Musim 1';
    } else if (rawTitle.isNotEmpty) {
      if (lowerTitle.startsWith('biaya & pengeluaran')) {
        FinanceDataStore.activeSeasonTitle = rawTitle;
      } else {
        FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran $rawTitle';
      }
    }
    if (season['expenses'] != null) {
      FinanceDataStore.activeTotalExpense = season['expenses'] as String;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context, season);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinanceScreen(initialSeasonData: season),
        ),
      );
    }
  }

  void _showSeasonDetail(Map<String, dynamic> season) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(
            top: BorderSide(color: AppColors.ink, width: 2),
            left: BorderSide(color: AppColors.ink, width: 2),
            right: BorderSide(color: AppColors.ink, width: 2),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      season['title'] as String,
                      style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const StatusChip(label: 'ARSIP RESMI', variant: StatusChipVariant.lime),
                  ],
                ),
                const SizedBox(height: 4),
                MicroText(season['period'] as String, fontSize: 9.5, color: AppColors.muted),
                const SizedBox(height: 14),

                // 4 Kategori Rincian Biaya Musim (Format Baris Tanpa Persen)
                _buildDetailRow('Tanggal Dibuat:', (season['createdDate'] ?? '-') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Buruh & Petik:', (season['labor'] ?? 'Rp 0') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Pupuk & Nutrisi:', (season['fertilizer'] ?? 'Rp 0') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Bibit & Olah Lahan:', (season['seed'] ?? 'Rp 0') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Lainnya / Tambahan:', (season['other'] ?? 'Rp 0') as String),
                const SizedBox(height: 10),
                Container(
                  height: 1.5,
                  color: AppColors.ink.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Total Pengeluaran:', (season['expenses'] ?? 'Rp 0') as String),
                const SizedBox(height: 18),
                TrapezoidTabButton(
                  label: 'TUTUP',
                  height: 42,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(fontSize: 12)),
        Text(value, style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _confirmDeleteSeason(int index, Map<String, dynamic> season) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('HAPUS ARSIP MUSIM', style: AppTypography.display(fontSize: 15, fontWeight: FontWeight.w900)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${season['title']}"? Data riwayat musim ini akan dihapus permanen.',
          style: AppTypography.body(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: AppTypography.mono(fontSize: 11, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedTitle = season['title'] ?? 'Musim';
              final idMusim = season['idMusim'] as String? ?? '';
              final idPetani = AuthSession.currentIdPetani;

              if (idMusim.isNotEmpty && idPetani.isNotEmpty) {
                final newMusim = await FirestoreService.instance.hapusMusimTanam(
                  idPetani: idPetani,
                  idMusim: idMusim,
                );
                if (newMusim != null) {
                  AuthSession.activeMusimId = newMusim.idMusim;
                } else if (AuthSession.activeMusimId == idMusim) {
                  final sisa = await FirestoreService.instance.getSemuaMusim(idPetani);
                  if (sisa.isNotEmpty) {
                    AuthSession.activeMusimId = sisa.first.idMusim;
                  } else {
                    final fresh = await FirestoreService.instance.getOrCreateMusimAktif(idPetani);
                    AuthSession.activeMusimId = fresh.idMusim;
                  }
                }
              }

              await _loadMusimFromFirestore();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Musim "$deletedTitle" berhasil dihapus dari keuangan & panen!'),
                    backgroundColor: AppColors.ink,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('YA, HAPUS', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

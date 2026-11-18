import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';

class FinanceScreenEditUpload extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const FinanceScreenEditUpload({super.key, this.initialData});

  @override
  State<FinanceScreenEditUpload> createState() => _FinanceScreenEditUploadState();
}

class _FinanceScreenEditUploadState extends State<FinanceScreenEditUpload> {
  int _selectedCategoryIndex = 0;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Buruh Tani / Upah Kerja',
      'desc': 'Petik, jemur, kuli angkut',
      'icon': Icons.groups_rounded,
    },
    {
      'name': 'Pupuk & Nutrisi',
      'desc': 'NPK, ZA, kompos, suplemen',
      'icon': Icons.science_outlined,
    },
    {
      'name': 'Bibit & Olah Lahan',
      'desc': 'Benih unggul, traktor/bajak',
      'icon': Icons.spa_outlined,
    },
    {
      'name': 'Lainnya / Tambahan',
      'desc': 'Terpal, karung, tali rafia, transport',
      'icon': Icons.more_horiz_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    if (data != null && data['category'] != null) {
      final foundIdx = _categories.indexWhere((c) => c['name'] == data['category']);
      if (foundIdx != -1) {
        _selectedCategoryIndex = foundIdx;
      } else {
        _selectedCategoryIndex = 3;
      }
    }

    _amountController = TextEditingController(
      text: data != null && data['amount'] != null
          ? data['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '')
          : '750000',
    );

    _titleController = TextEditingController(
      text: data != null && data['title'] != null
          ? data['title'].toString()
          : (_selectedCategoryIndex == 3 ? '' : _categories[_selectedCategoryIndex]['name'] as String),
    );

    _notesController = TextEditingController(
      text: data != null && data['notes'] != null ? data['notes'].toString() : '',
    );

    _selectedDate = DateTime.now();
  }

  void _onSelectCategory(int idx) {
    setState(() {
      _selectedCategoryIndex = idx;
      if (idx == 3) {
        // Kategori "Lainnya / Tambahan" memerlukan inputan manual dari user
        _titleController.clear();
      } else {
        // Otomatis terisi sesuai kategori yang dipilih
        _titleController.text = _categories[idx]['name'] as String;
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan keterangan / judul transaksi terlebih dahulu!'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Catatan "$title" berhasil disimpan!'),
        backgroundColor: AppColors.ink,
      ),
    );
    Navigator.pop(context);
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
                // Header
                AppHeader(
                  showBack: true,
                  title: widget.initialData != null ? 'EDIT CATATAN BIAYA' : 'INPUT BIAYA OPERASIONAL',
                  subtitle: 'FORMULIR KAS // TAPE-FORM',
                  padding: EdgeInsets.zero,
                  height: null,
                ),
                const SizedBox(height: 12),

                // 1. Pilih Kategori Pembayaran (Grid Tombol Fisik)
                const TaperedDivider(centerLabel: 'PILIH KATEGORI PEMBAYARAN'),
                const SizedBox(height: 6),
                _buildCategorySelectorGrid(),
                const SizedBox(height: 14),

                // 2. Formulir Rincian & Tanggal
                RetroCard(
                  tapeTag: 'INPUT DATA // NOMINAL & TANGGAL',
                  rightTag: 'RUPIAH (IDR)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field Nominal
                      const MicroText('NOMINAL PENGELUARAN (RP)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.mono(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.red),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              child: Text('Rp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Field Judul
                      MicroText(
                        _selectedCategoryIndex == 3
                            ? 'KETERANGAN / JUDUL TRANSAKSI (INPUT MANUAL)'
                            : 'KETERANGAN / JUDUL TRANSAKSI (OTOMATIS // TERKUNCI)',
                        fontSize: 10,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: _selectedCategoryIndex == 3 ? Colors.white : const Color(0xFFF1F1EB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _titleController,
                          readOnly: _selectedCategoryIndex != 3,
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _selectedCategoryIndex == 3
                                ? 'Ketik keterangan transaksi di sini...'
                                : 'Misal: ${_categories[_selectedCategoryIndex]['name']}',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: _selectedCategoryIndex != 3
                                ? const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.muted)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pemilih Tanggal
                      const MicroText('TANGGAL PENGELUARAN', fontSize: 10),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.ink, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.ink),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Field Catatan
                      const MicroText('CATATAN TAMBAHAN (OPSIONAL)', fontSize: 10),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: TextField(
                          controller: _notesController,
                          minLines: 2,
                          maxLines: 3,
                          style: AppTypography.body(fontSize: 12),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Tuliskan rincian tambahan di sini...',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Simpan CTA Trapesium Oranye
                TrapezoidTabButton(
                  label: 'SIMPAN CATATAN BIAYA',
                  icon: Icons.check_rounded,
                  onPressed: _saveExpense,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryTile(0)),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryTile(1)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCategoryTile(2)),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryTile(3)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTile(int idx) {
    final cat = _categories[idx];
    final isSelected = _selectedCategoryIndex == idx;

    return GestureDetector(
      onTap: () => _onSelectCategory(idx),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.lime : AppColors.ink,
            width: 2,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.lime, offset: Offset(2, 2))]
              : const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 20,
                  color: isSelected ? AppColors.lime : AppColors.ink,
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.lime),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cat['name'] as String,
              style: AppTypography.display(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.paper : AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

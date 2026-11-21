import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

class FinanceScreenEditUpload extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String idSiklus;

  const FinanceScreenEditUpload({
    super.key,
    this.initialData,
    this.idSiklus = "siklus_2026_01",
  });

  @override
  State<FinanceScreenEditUpload> createState() => _FinanceScreenEditUploadState();
}

class _FinanceScreenEditUploadState extends State<FinanceScreenEditUpload> {
  int _selectedCategoryIndex = 0;
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Buruh Tani / Upah',
      'desc': 'Petik, jemur, kuli angkut',
      'icon': Icons.groups_rounded,
      'activeBg': const Color(0xFF065F46),
    },
    {
      'name': 'Pupuk & Nutrisi',
      'desc': 'NPK, ZA, kompos, suplemen',
      'icon': Icons.science_outlined,
      'activeBg': const Color(0xFF4338CA),
    },
    {
      'name': 'Bibit & Olah Lahan',
      'desc': 'Benih unggul, traktor/bajak',
      'icon': Icons.spa_outlined,
      'activeBg': const Color(0xFF115E59),
    },
    {
      'name': 'Lainnya / Tambahan',
      'desc': 'Terpal, karung, tali rafia, transport',
      'icon': Icons.more_horiz_rounded,
      'activeBg': const Color(0xFF92400E),
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    // Jika mode edit, pilih kategori awal sesuai item yang diedit
    if (data != null && data['category'] != null) {
      final catLower = data['category'].toString().toLowerCase();
      if (catLower.contains('buruh') || catLower.contains('upah')) {
        _selectedCategoryIndex = 0;
      } else if (catLower.contains('pupuk') || catLower.contains('nutrisi')) {
        _selectedCategoryIndex = 1;
      } else if (catLower.contains('bibit') || catLower.contains('olah') || catLower.contains('lahan')) {
        _selectedCategoryIndex = 2;
      } else {
        _selectedCategoryIndex = 3;
      }
    }

    // Mode baru dimulai dari kosong (0), mode edit diisi dari data sebelumnya
    _amountController = TextEditingController(
      text: data != null && data['amount'] != null
          ? data['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '')
          : '',
    );

    _titleController = TextEditingController(
      text: data != null && data['title'] != null
          ? data['title'].toString()
          : '',
    );

    _notesController = TextEditingController(
      text: data != null && data['notes'] != null
          ? data['notes'].toString()
          : '',
    );

    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatAmount(String value) {
    if (value.isEmpty) return '0';
    final n = int.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _terbilang(int number) {
    if (number <= 0) return 'Nol rupiah';
    return 'Nominal: Rp ${_formatAmount(number.toString())} rupiah';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF166534),
              onPrimary: Colors.white,
              onSurface: Color(0xFF191C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ==========================================
  // VALIDASI & KIRIM DATA KEMBALI KE FINANCESCREEN
  // ==========================================
  Future<void> _handleSaveBiaya() async {
    final String title = _titleController.text.trim();
    final String amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    final double amountVal = double.tryParse(amountText) ?? 0.0;
    final String category = _categories[_selectedCategoryIndex]['name'];
    final String notes = _notesController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama / keperluan biaya tidak boleh kosong!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (amountVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal pengeluaran harus lebih besar dari 0!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;

      // Kembalikan payload ke FinanceScreen agar disimpan & dihitung ulang tanpa duplikasi
      Navigator.pop(context, {
        'title': title,
        'amount': '-Rp ${_formatAmount(amountText)}',
        'raw_amount': amountVal,
        'category': category,
        'date': '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
        'notes': notes,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialData != null
              ? 'Catatan pengeluaran berhasil diperbarui!'
              : 'Pengeluaran baru berhasil dicatat!'),
          backgroundColor: const Color(0xFF166534),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan biaya: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    final int numericAmount =
        int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppHeader(
        showBack: true,
        title: isEdit ? 'Ubah Pengeluaran' : 'Catat Pengeluaran Baru',
        backgroundColor: const Color(0xD9F7F9FB),
        showBottomBorder: true,
        trailing: GestureDetector(
          onTap: _isLoading ? null : _handleSaveBiaya,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF004C22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFA6F4B5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                color: Color(0xFF00210B), size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'PENCATATAN OPERASIONAL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: Color(0xFF004C22),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E8EA),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF004C22),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Musim 2026',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF404940),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Masukkan rincian pengeluaran kebun tembakau untuk menjaga pencatatan buku kas tetap rapi dan terukur.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF404940),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Icons.grid_view_rounded,
                    title: 'Pilih Kategori Pembayaran',
                    badge: 'Wajib',
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryList(),

                  const SizedBox(height: 28),

                  _buildSectionHeader(
                    icon: Icons.edit_note_rounded,
                    title: 'Rincian & Tanggal',
                    badge: '',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailsForm(numericAmount),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA6F4B5).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF004C22), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catatan pengeluaran ini akan langsung diperbarui ke ringkasan total estimasi biaya musim tanam dan modal perhitungan BEP panen.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  _buildActionButtons(isEdit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String badge,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF004C22)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF191C1E),
              ),
            ),
          ],
        ),
        if (badge.isNotEmpty)
          Text(
            badge,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF004C22),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Column(
      children: List.generate(_categories.length, (index) {
        final cat = _categories[index];
        final isSelected = _selectedCategoryIndex == index;
        final Color activeColor = cat['activeBg'] as Color;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? activeColor : const Color(0x0D000000),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : const Color(0xFFE6E8EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? Colors.white : const Color(0xFF404940),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat['desc'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF404940),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : const Color(0xFFECEEF0),
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDetailsForm(int numericAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              const Row(
                children: [
                  Icon(Icons.payments_outlined, size: 16, color: Color(0xFF004C22)),
                  SizedBox(width: 6),
                  Text(
                    'Nominal Pengeluaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEF0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Mata Uang IDR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF404940),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF004C22).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Rp',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF404940),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: Color(0xFF191C1E),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _terbilang(numericAmount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF404940),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFECEEF0)),
          const SizedBox(height: 16),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nama / Keperluan Biaya',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191C1E),
                ),
              ),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF191C1E),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Misal: Upah tenaga petik harian',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Tanggal Transaksi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF004C22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF404940)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catatan Tambahan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191C1E),
                ),
              ),
              Text(
                'Opsional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF404940),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF191C1E),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Tuliskan catatan atau rincian tambahan di sini...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isEdit) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF166534),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: _isLoading ? null : _handleSaveBiaya,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: Text(
              _isLoading
                  ? 'Menyimpan...'
                  : (isEdit ? 'Simpan Perubahan' : 'Simpan Pengeluaran'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
            child: const Text(
              'Batal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }
}
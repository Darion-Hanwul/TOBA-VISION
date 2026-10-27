import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

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
      'activeBg': Color(0xFF166534),
    },
    {
      'name': 'Pupuk & Nutrisi',
      'desc': 'NPK, ZA, kompos, suplemen',
      'icon': Icons.science_outlined,
      'activeBg': Color(0xFF166534),
    },
    {
      'name': 'Bibit & Olah Lahan',
      'desc': 'Benih unggul, traktor/bajak',
      'icon': Icons.spa_outlined,
      'activeBg': Color(0xFF166534),
    },
    {
      'name': 'Lainnya / Tambahan',
      'desc': 'Terpal, karung, tali rafia, transport',
      'icon': Icons.more_horiz_rounded,
      'activeBg': Color(0xFF166534),
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _amountController = TextEditingController(
      text: data != null && data['amount'] != null
          ? data['amount'].toString().replaceAll(RegExp(r'[^0-9]'), '')
          : '750000',
    );

    _titleController = TextEditingController(
      text: data != null && data['title'] != null
          ? data['title'].toString()
          : 'Upah 5 Tenaga Petik Harian - Blok Timur',
    );

    _notesController = TextEditingController(
      text: data != null && data['notes'] != null
          ? data['notes'].toString()
          : '5 orang @ Rp 150.000 per hari kerja',
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
    if (number == 750000) return 'Tujuh ratus lima puluh ribu rupiah';
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    final int numericAmount =
        int.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppHeader(
        showBack: true,
        title: isEdit ? 'Ubah Pengeluaran' : 'Catat Pengeluaran Baru',
        backgroundColor: const Color(0xD9F7F9FB),
        showBottomBorder: true,
        trailing: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF004C22),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtle Header Description & Quick Status Bar
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

            // Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 2: PILIH KATEGORI PEMBAYARAN
                  _buildSectionHeader(
                    icon: Icons.grid_view_rounded,
                    title: 'Pilih Kategori Pembayaran',
                    badge: 'Wajib',
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryList(),

                  const SizedBox(height: 28),

                  // SECTION 3: RINCIAN & TANGGAL
                  _buildSectionHeader(
                    icon: Icons.edit_note_rounded,
                    title: 'Rincian & Tanggal',
                    badge: '',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailsForm(numericAmount),

                  const SizedBox(height: 24),

                  // Info Field Tip Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA6F4B5).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF004C22), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Catatan pengeluaran ini akan langsung diperbarui ke ringkasan total estimasi biaya musim tanam.',
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

                  // BOTTOM ACTION BUTTONS
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
                  color: isSelected ? const Color(0xFF004C22) : const Color(0x0D000000),
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
                      color: isSelected ? const Color(0xFF166534) : const Color(0xFFE6E8EA),
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
                      color: isSelected ? const Color(0xFF004C22) : const Color(0xFFECEEF0),
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
          // Field Nominal Pengeluaran
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
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

          // Input Box Nominal
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

          // Field Nama / Keperluan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
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
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Field Tanggal Transaksi
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

          // Field Catatan Tambahan (Opsional)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
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
        // Tombol Simpan
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
            onPressed: () {
              Navigator.pop(context, {
                'title': _titleController.text,
                'amount': '-Rp ${_formatAmount(_amountController.text)}',
                'category': _categories[_selectedCategoryIndex]['name'],
                'date': '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEdit
                      ? 'Catatan pengeluaran berhasil diperbarui!'
                      : 'Pengeluaran baru berhasil dicatat!'),
                  backgroundColor: const Color(0xFF166534),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: Text(
              isEdit ? 'Simpan Perubahan' : 'Simpan Pengeluaran',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Tombol Batal
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

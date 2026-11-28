import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/bmkg_locations.dart';
import 'locked_bmkg_desa_field.dart';
import 'retro/micro_text.dart';

/// Modal Bottom Sheet Retro untuk memilih lokasi resmi BMKG:
/// Provinsi, Kabupaten/Kota, Kecamatan, dan Desa/Kelurahan
Future<BmkgLocation?> showBmkgLocationPicker(
  BuildContext context, {
  String? activeCode,
  String? activeName,
}) {
  return showModalBottomSheet<BmkgLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LocationPickerSheet(
      activeCode: activeCode,
      activeName: activeName,
    ),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  final String? activeCode;
  final String? activeName;

  const _LocationPickerSheet({
    this.activeCode,
    this.activeName,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late String _selectedProvinsi;
  late String _selectedKabupaten;
  late String _selectedKecamatan;
  final _desaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final parsed = BmkgLocations.parseAddressComponents(widget.activeName ?? '');
    final prov = parsed['provinsi'] ?? 'Jawa Tengah';
    final kab = parsed['kabupaten'] ?? 'Temanggung';
    final kec = parsed['kecamatan'] ?? 'Bulu';
    final des = parsed['desa'] ?? '';

    // 1. Inisialisasi Provinsi
    _selectedProvinsi = BmkgLocations.daftarProvinsi.firstWhere(
      (p) => p.toLowerCase() == prov.toLowerCase(),
      orElse: () => 'Jawa Tengah',
    );

    // 2. Inisialisasi Kabupaten
    final listKab = BmkgLocations.getKabupatenList(_selectedProvinsi);
    _selectedKabupaten = listKab.firstWhere(
      (k) => k.toLowerCase() == kab.toLowerCase() ||
             k.toLowerCase().contains(kab.toLowerCase()) ||
             kab.toLowerCase().contains(k.toLowerCase()),
      orElse: () => listKab.isNotEmpty ? listKab.first : 'Temanggung',
    );

    // 3. Inisialisasi Kecamatan
    final listKec = BmkgLocations.getKecamatanList(_selectedKabupaten);
    _selectedKecamatan = listKec.firstWhere(
      (k) => k.toLowerCase() == kec.toLowerCase() ||
             k.toLowerCase().contains(kec.toLowerCase()) ||
             kec.toLowerCase().contains(k.toLowerCase()),
      orElse: () => listKec.isNotEmpty ? listKec.first : 'Bulu',
    );

    // 4. Inisialisasi Desa (kosongkan jika kecamatan belum punya daftar desa resmi BMKG)
    final initialDesas = BmkgLocations.getDesaList(_selectedKecamatan);
    _desaController.text = initialDesas.isNotEmpty ? des : '';
  }

  @override
  void dispose() {
    _desaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final String prov = _selectedProvinsi;
    final String kab = _selectedKabupaten;
    final String kec = _selectedKecamatan;
    final listDesa = BmkgLocations.getDesaList(kec);
    final String des = listDesa.isNotEmpty ? _desaController.text.trim() : '';

    final result = BmkgLocations.createFromComponents(
      provinsi: prov,
      kabupaten: kab,
      kecamatan: kec,
      desa: des.isNotEmpty ? des : null,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    final listKab = BmkgLocations.getKabupatenList(_selectedProvinsi);
    final listKec = BmkgLocations.getKecamatanList(_selectedKabupaten);
    final listDesa = BmkgLocations.getDesaList(_selectedKecamatan);

    final activeDesa = listDesa.isNotEmpty ? _desaController.text.trim() : '';
    final matched = BmkgLocations.findMatchingLocation('$_selectedKecamatan $_selectedKabupaten');

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.92,
        ),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 22, color: AppColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MicroText('STASIUN BMKG // WILAYAH ADMINISTRATIF', fontSize: 9),
                        Text(
                          'PILIH WILAYAH RESMI BMKG',
                          style: AppTypography.display(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Tutup',
                  ),
                ],
              ),

              const Divider(color: AppColors.ink, height: 16, thickness: 1.5),

              // 1. PROVINSI (Semua 38 Provinsi Resmi Indonesia)
              const MicroText('1. PROVINSI (38 PROVINSI RESMI BMKG)', fontSize: 10),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink, width: 1.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvinsi,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                    style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                    items: BmkgLocations.daftarProvinsi.map((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(
                          p == 'Jawa Tengah' ? '$p (Sentra Utama Temanggung)' : p,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedProvinsi = val;
                          final newKabs = BmkgLocations.getKabupatenList(val);
                          _selectedKabupaten = newKabs.first;
                          final newKecs = BmkgLocations.getKecamatanList(_selectedKabupaten);
                          _selectedKecamatan = newKecs.first;
                          final newDesas = BmkgLocations.getDesaList(_selectedKecamatan);
                          _desaController.text = newDesas.isNotEmpty ? newDesas.first : '';
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. KABUPATEN / KOTA
              MicroText('2. KABUPATEN / KOTA (${listKab.length} WILAYAH DI ${_selectedProvinsi.toUpperCase()})', fontSize: 10),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink, width: 1.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: listKab.contains(_selectedKabupaten) ? _selectedKabupaten : listKab.first,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                    style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                    items: listKab.map((k) {
                      return DropdownMenuItem<String>(
                        value: k,
                        child: Text(
                          k == 'Temanggung' ? '$k (Sentra Utama Sindoro-Sumbing)' : k,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedKabupaten = val;
                          final newKecs = BmkgLocations.getKecamatanList(val);
                          _selectedKecamatan = newKecs.first;
                          final newDesas = BmkgLocations.getDesaList(_selectedKecamatan);
                          _desaController.text = newDesas.isNotEmpty ? newDesas.first : '';
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. KECAMATAN
              MicroText('3. KECAMATAN (${listKec.length} KECAMATAN DI ${_selectedKabupaten.toUpperCase()})', fontSize: 10),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.ink, width: 1.8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: listKec.contains(_selectedKecamatan) ? _selectedKecamatan : listKec.first,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                    style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                    items: listKec.map((kec) {
                      return DropdownMenuItem<String>(
                        value: kec,
                        child: Text('Kecamatan $kec'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedKecamatan = val;
                          final newDesas = BmkgLocations.getDesaList(val);
                          _desaController.text = newDesas.isNotEmpty ? newDesas.first : '';
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. DESA / KELURAHAN
              MicroText(
                listDesa.isNotEmpty
                    ? '4. DESA / KELURAHAN (${listDesa.length} DESA DI KEC. ${_selectedKecamatan.toUpperCase()})'
                    : '4. DESA / KELURAHAN (TERKUNCI)',
                fontSize: 10,
              ),
              const SizedBox(height: 6),

              if (listDesa.isNotEmpty) ...[
                // Pilihan Dropdown Seluruh Desa Resmi di Kecamatan Terpilih
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: listDesa.contains(_desaController.text.trim())
                          ? _desaController.text.trim()
                          : listDesa.first,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.ink),
                      style: AppTypography.body(fontSize: 13.5, fontWeight: FontWeight.w700),
                      items: listDesa.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text('Desa / Kel. $d'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _desaController.text = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Rekomendasi Cepat / Quick Chips Desa
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: listDesa.take(8).map((d) {
                    final isCurrent = _desaController.text.trim().toLowerCase() == d.toLowerCase();
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _desaController.text = d;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.lime : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCurrent ? AppColors.forestGreen : AppColors.ink,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          d,
                          style: AppTypography.mono(
                            fontSize: 9.5,
                            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                // Terkunci jika tidak ada rekomendasi desa / kelurahan dari BMKG
                const LockedBmkgDesaField(),
              ],

              const SizedBox(height: 16),

              // KOTAK PREVIEW LOKASI TERPILIH & KODE BMKG
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.forestGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.forestGreen, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MicroText('LOKASI KEBUN AKTIF (BMKG)', fontSize: 8),
                          Text(
                            '${activeDesa.isNotEmpty ? "Desa $activeDesa, " : ""}Kec. $_selectedKecamatan, Kab. $_selectedKabupaten, Prov. $_selectedProvinsi',
                            style: AppTypography.display(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          MicroText(
                            'KODE BMKG: ${matched.code} • ${matched.description}',
                            fontSize: 8,
                            color: AppColors.forest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // TOMBOL SIMPAN
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: AppColors.ink, width: 2),
                  ),
                ),
                onPressed: _handleSave,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 18, color: AppColors.ink),
                    const SizedBox(width: 8),
                    Text(
                      'SIMPAN WILAYAH KEBUN',
                      style: AppTypography.mono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

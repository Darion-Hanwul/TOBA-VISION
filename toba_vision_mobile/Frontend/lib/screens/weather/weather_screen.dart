import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/auth_session.dart';
import '../../data/firestore_service.dart';
import '../../data/models.dart';
import '../../data/services.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_view.dart';
import '../../widgets/location_selector_sheet.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  int _refreshCounter = 0;
  int _selectedDay = 0; // 0 = Hari Ini, 1 = Besok

  static IconData _icon(WeatherKind k) {
    switch (k) {
      case WeatherKind.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherKind.cloudy:
        return Icons.cloud_rounded;
      case WeatherKind.overcast:
        return Icons.cloud_queue_rounded;
      case WeatherKind.rain:
        return Icons.grain_rounded;
    }
  }

  /// Klasifikasi Slot Hujan (Hujan, Petir, Gerimis, Badai)
  static bool _isRainSlot(WeatherSlot s) {
    final t = s.title.toLowerCase();
    return s.kind == WeatherKind.rain ||
        t.contains('hujan') ||
        t.contains('petir') ||
        t.contains('gerimis') ||
        t.contains('badai');
  }

  /// Klasifikasi Slot Mendung (Overcast, Mendung, Udara Kabur, Kabut, Asap, Berawan non-cerah)
  static bool _isMendungSlot(WeatherSlot s) {
    if (_isRainSlot(s)) return false;
    final t = s.title.toLowerCase();
    final isBerawanMendung = t.contains('berawan') && !t.contains('cerah berawan');
    return s.kind == WeatherKind.overcast ||
        t.contains('mendung') ||
        t.contains('udara kabur') ||
        t.contains('kabut') ||
        t.contains('asap') ||
        isBerawanMendung;
  }

  static String _formatDayDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName';
  }

  Future<void> _handleEditLocation() async {
    final chosen = await showBmkgLocationPicker(
      context,
      activeName: AuthSession.currentLokasi,
    );

    if (chosen != null && mounted) {
      final idPetani = AuthSession.currentIdPetani;
      final newLocation = chosen.displayName;

      if (idPetani.isNotEmpty) {
        try {
          await FirestoreService.instance.updateLokasiPetani(
            idPetani: idPetani,
            lokasiBaru: newLocation,
          );
        } catch (_) {}
      }

      AuthSession.updateCurrentLokasi(newLocation);
      if (!mounted) return;
      setState(() => _refreshCounter++);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi kebun diperbarui: $newLocation. Menyinkronkan cuaca BMKG...'),
          backgroundColor: AppColors.forestGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<(UserProfile, WeatherData)>(
      key: ValueKey(_refreshCounter),
      load: () async {
        final p = await Services.user.getProfile();
        final w = await Services.weather.getWeather();
        return (p, w);
      },
      builder: (context, d) {
        final p = d.$1;
        final w = d.$2;
        final activeWeather = (_selectedDay == 1 && w.tomorrow != null)
            ? w.tomorrow!
            : w;

        // Analisis potensi hujan dan mendung dari semua slot waktu pada hari aktif
        final rainSlots = activeWeather.slots.where(_isRainSlot).toList();

        final hasRain = rainSlots.isNotEmpty;
        final isSunnyDay = !hasRain;

        final displayLocation = AuthSession.currentLokasi.isNotEmpty
            ? AuthSession.currentLokasi
            : w.location;

        return RetroFrame(
          backgroundColor: AppColors.sage,
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan tombol Sinkronisasi Cuaca
                AppHeader(
                  title: 'PRAKIRAAN CUACA',
                  subtitle: '${displayLocation.toUpperCase()} • STASIUN BMKG',
                  padding: EdgeInsets.zero,
                  height: null,
                  logoSize: 40,
                  logoIcon: Icons.wb_sunny_rounded,
                  logoBg: AppColors.ink,
                  logoColor: AppColors.lime,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () {
                      setState(() => _refreshCounter++);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menyinkronkan data cuaca live BMKG untuk $displayLocation...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Sapaan Display Besar
                Text(
                  '${greeting()},\n${p.name}',
                  style: AppTypography.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),

                // Bar Lokasi Kebun & Tombol Ganti Wilayah
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ink, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 20, color: AppColors.rust),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MicroText('WILAYAH KEBUN ANDA', fontSize: 8.5),
                            const SizedBox(height: 2),
                            Text(
                              displayLocation,
                              style: AppTypography.display(fontSize: 13.5, fontWeight: FontWeight.w900),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stasiun Cuaca BMKG: ${w.location}',
                              style: AppTypography.body(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lime,
                          foregroundColor: AppColors.ink,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: AppColors.ink, width: 1.5),
                          ),
                        ),
                        onPressed: _handleEditLocation,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.edit_location_alt_rounded, size: 14, color: AppColors.ink),
                            SizedBox(width: 4),
                            MicroText('GANTI', fontSize: 9.5, fontWeight: FontWeight.w900),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // TAB PILIHAN HARI: HARI INI vs HARI BESOK
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ink, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedDay = 0),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _selectedDay == 0 ? AppColors.lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: _selectedDay == 0 ? Border.all(color: AppColors.ink, width: 1.8) : null,
                              boxShadow: _selectedDay == 0
                                  ? const [BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wb_sunny_rounded,
                                  size: 16,
                                  color: _selectedDay == 0 ? AppColors.ink : AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HARI INI',
                                      style: AppTypography.display(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: _selectedDay == 0 ? AppColors.ink : AppColors.muted,
                                      ),
                                    ),
                                    Text(
                                      _formatDayDate(DateTime.now()),
                                      style: AppTypography.mono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedDay == 0 ? AppColors.forestGreen : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _selectedDay = 1),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _selectedDay == 1 ? AppColors.lime : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: _selectedDay == 1 ? Border.all(color: AppColors.ink, width: 1.8) : null,
                              boxShadow: _selectedDay == 1
                                  ? const [BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5))]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: _selectedDay == 1 ? AppColors.ink : AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HARI BESOK',
                                      style: AppTypography.display(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                        color: _selectedDay == 1 ? AppColors.ink : AppColors.muted,
                                      ),
                                    ),
                                    Text(
                                      _formatDayDate(DateTime.now().add(const Duration(days: 1))),
                                      style: AppTypography.mono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedDay == 1 ? AppColors.forestGreen : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Kotak Analisis Jam Hujan & Mendung (Merah jika Hujan, Hijau jika Hari Cerah)
                _buildHourlyRainStatusBanner(
                  context: context,
                  isToday: _selectedDay == 0,
                  activeWeather: activeWeather,
                  displayLocation: displayLocation,
                ),
                const SizedBox(height: 14),

                // 2. Kartu Jadwal Tracklist Cuaca 24 Jam Penuh (Scrollable)
                RetroCard(
                  tapeTag: 'HOURLY TRACKLIST // ${_selectedDay == 0 ? "24 JAM HARI INI" : "24 JAM HARI BESOK"}',
                  rightTag: '${activeWeather.slots.length} WAKTU',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mini Legenda Cap Kaset Retro & Indikator Scroll
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildRetroLegendBadge('CERAH', AppColors.lime, AppColors.ink),
                              const SizedBox(width: 8),
                              _buildRetroLegendBadge('MENDUNG', AppColors.orange, AppColors.paper),
                              const SizedBox(width: 8),
                              _buildRetroLegendBadge('HUJAN', AppColors.rust, Colors.white),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.unfold_more_rounded, size: 13, color: AppColors.muted),
                              SizedBox(width: 2),
                              MicroText('SCROLL', fontSize: 8.5, color: AppColors.muted),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 270),
                        child: Scrollbar(
                          thumbVisibility: true,
                          radius: const Radius.circular(4),
                          thickness: 4.5,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < activeWeather.slots.length; i++)
                                  _buildTracklistSlotItem(activeWeather.slots[i]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Kartu Tips "Si Daun Toba" Miring Sedikit (Stiker Kaset)
                Transform.rotate(
                  angle: -0.015,
                  child: RetroCard(
                    backgroundColor: const Color(0xFFFEF9C3),
                    tapeTag: isSunnyDay
                        ? (_selectedDay == 0 ? 'TIPS KEBUN // SI DAUN TOBA' : 'TIPS PERSIAPAN BESOK // SI DAUN TOBA')
                        : (_selectedDay == 0 ? 'PERINGATAN HUJAN // SI DAUN TOBA' : 'PERINGATAN HUJAN BESOK // SI DAUN TOBA'),
                    rightTag: isSunnyDay ? 'REKOMENDASI' : 'WASPADA',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.wb_incandescent_outlined, color: AppColors.ink, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '"${activeWeather.tip}"',
                            style: AppTypography.body(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRetroChip({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    final double maxChipWidth = MediaQuery.of(context).size.width - 68;
    return Container(
      constraints: BoxConstraints(maxWidth: maxChipWidth > 120 ? maxChipWidth : 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(1.2, 1.2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: fg),
          const SizedBox(width: 4.5),
          Flexible(
            child: Text(
              text,
              style: AppTypography.mono(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: fg,
                letterSpacing: 0.3,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner Status Analisis Jam Hujan & Mendung Bergaya Otentik Retro Walkman Tape-Deck
  Widget _buildHourlyRainStatusBanner({
    required BuildContext context,
    required bool isToday,
    required WeatherData activeWeather,
    required String displayLocation,
  }) {
    final rainSlots = activeWeather.slots.where(_isRainSlot).toList();
    final mendungSlots = activeWeather.slots.where(_isMendungSlot).toList();

    final bool hasRain = rainSlots.isNotEmpty;
    final rainTimes = rainSlots.map((s) => s.time).toList();
    final mendungTimes = mendungSlots.map((s) => s.time).toList();
    final String formattedRain = _formatTimeRanges(rainTimes);
    final String formattedMendung = _formatTimeRanges(mendungTimes);

    return Container(
      decoration: BoxDecoration(
        color: hasRain ? const Color(0xFFFBF0F0) : const Color(0xFFF2F7EC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(2.5, 2.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. Tape Strip Header Teknis Retro Walkman
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: hasRain ? AppColors.rust : AppColors.ink,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      hasRain ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      color: hasRain ? Colors.white : AppColors.lime,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    MicroText(
                      hasRain ? 'RADAR SYSTEM // PERINGATAN HUJAN' : 'RADAR SYSTEM // JEMUR OPTIMAL',
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ],
                ),
                MicroText(
                  hasRain ? 'TB-ALERT-24H' : 'TB-CLEAR-24H',
                  color: hasRain ? const Color(0xFFFFD1D1) : AppColors.lime,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ],
            ),
          ),

          // B. Isi Informasi Status
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Baris 1: Ikon Box Hitam Retro + Label
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
                        ],
                      ),
                      child: Icon(
                        hasRain ? Icons.thunderstorm_rounded : Icons.wb_sunny_rounded,
                        color: hasRain ? AppColors.orange : AppColors.lime,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MicroText(
                            hasRain
                                ? (isToday ? 'STATUS: WASPADA HUJAN HARI INI' : 'PREDIKSI BESOK: WASPADA HUJAN')
                                : (isToday ? 'STATUS: HARI YANG CERAH' : 'PREDIKSI BESOK: HARI YANG CERAH'),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: hasRain ? AppColors.rust : AppColors.forestGreen,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            hasRain
                                ? 'POTENSI HUJAN PADA JAM TERTENTU'
                                : 'BEBAS HUJAN SEHARIAN (AMAN DI SASAK)',
                            style: AppTypography.display(
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
                const SizedBox(height: 10),

                // Baris 2: Chips Jam Hujan / Jam Mendung / Bebas Hujan
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (hasRain) ...[
                      _buildRetroChip(
                        context: context,
                        icon: Icons.water_drop_rounded,
                        text: 'JAM HUJAN: $formattedRain',
                        bg: AppColors.rust,
                        fg: Colors.white,
                      ),
                      if (mendungTimes.isNotEmpty)
                        _buildRetroChip(
                          context: context,
                          icon: Icons.cloud_rounded,
                          text: 'MENDUNG: $formattedMendung',
                          bg: AppColors.orange,
                          fg: AppColors.paper,
                        ),
                    ] else ...[
                      _buildRetroChip(
                        context: context,
                        icon: Icons.check_circle_rounded,
                        text: 'HARI CERAH • 0% POTENSI HUJAN',
                        bg: AppColors.lime,
                        fg: AppColors.ink,
                      ),
                      if (mendungTimes.isNotEmpty)
                        _buildRetroChip(
                          context: context,
                          icon: Icons.cloud_outlined,
                          text: 'MENDUNG/KABUR: $formattedMendung',
                          bg: AppColors.paper,
                          fg: AppColors.ink,
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Baris 3: Recessed Paper Box untuk Petunjuk Penjemuran
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.ink, width: 1.2),
                  ),
                  child: Text(
                    hasRain
                        ? 'Prakiraan mendeteksi potensi HUJAN pada jam $formattedRain${mendungTimes.isNotEmpty ? ' dan MENDUNG jam $formattedMendung' : ''}. Segera amankan atau angkat sasak jemuran daun tembakau ke gudang sebelum jam ${rainTimes.first} agar tidak rusak terkena air!'
                        : (mendungTimes.isNotEmpty
                            ? 'Hari yang cerah! Tidak ada potensi hujan sepanjang hari (hanya mendung/kabut sejuk pada jam $formattedMendung). Daun tembakau sangat aman dijemur di sasak seharian penuh.'
                            : 'Hari yang cerah optimal! Bebas hujan sepanjang hari di $displayLocation. Sinar matahari maksimal untuk penjemuran daun tembakau di sasak agar kering merata & beraroma prima.'),
                    style: AppTypography.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format daftar jam menjadi rentang jam yang rapi (contoh: 03:00 - 05:00 & 13:00 - 15:00)
  static String _formatTimeRanges(List<String> times) {
    if (times.isEmpty) return '';
    if (times.length == 1) return times.first;

    final List<int> hours = [];
    for (final t in times) {
      final h = int.tryParse(t.split(':')[0]);
      if (h != null && !hours.contains(h)) {
        hours.add(h);
      }
    }
    hours.sort();

    if (hours.isEmpty) return times.join(', ');

    final List<List<int>> groups = [];
    List<int> currentGroup = [hours.first];

    for (int i = 1; i < hours.length; i++) {
      if (hours[i] == currentGroup.last + 1) {
        currentGroup.add(hours[i]);
      } else {
        groups.add(currentGroup);
        currentGroup = [hours[i]];
      }
    }
    groups.add(currentGroup);

    final List<String> rangeStrs = [];
    for (final g in groups) {
      if (g.length == 1) {
        rangeStrs.add('${g.first.toString().padLeft(2, '0')}:00');
      } else {
        final startStr = '${g.first.toString().padLeft(2, '0')}:00';
        final endStr = '${g.last.toString().padLeft(2, '0')}:00';
        rangeStrs.add('$startStr - $endStr');
      }
    }

    if (rangeStrs.length == 1) {
      return rangeStrs.first;
    } else if (rangeStrs.length == 2) {
      return '${rangeStrs[0]} & ${rangeStrs[1]}';
    } else {
      return rangeStrs.join(', ');
    }
  }

  Widget _buildRetroLegendBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(1, 1)),
        ],
      ),
      child: MicroText(label, fontSize: 8.5, fontWeight: FontWeight.w900, color: fg),
    );
  }

  Widget _buildTracklistSlotItem(WeatherSlot slot) {
    final bool isRain = _isRainSlot(slot);
    final bool isMendung = _isMendungSlot(slot);

    // Palet warna retro otentik Walkman / Tape-Deck Toba Vision
    final Color statusColor;
    final Color badgeBg;
    final Color badgeFg;
    final Color rowBg;
    final String statusLabel;

    if (isRain) {
      statusColor = AppColors.rust;
      badgeBg = AppColors.rust;
      badgeFg = Colors.white;
      rowBg = const Color(0xFFF9EEEE); // Kertas vintage aksen rust
      statusLabel = 'HUJAN';
    } else if (isMendung) {
      statusColor = AppColors.orange;
      badgeBg = AppColors.orange;
      badgeFg = AppColors.paper;
      rowBg = const Color(0xFFFAF5E8); // Kertas vintage aksen amber
      statusLabel = 'MENDUNG';
    } else {
      statusColor = AppColors.lime;
      badgeBg = AppColors.lime;
      badgeFg = AppColors.ink;
      rowBg = const Color(0xFFF2F6EB); // Kertas vintage aksen lime sage
      statusLabel = 'CERAH';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Row(
        children: [
          // 1. Indikator Strip Tegak / LED Track Tape-Deck
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(1.5),
              border: Border.all(color: AppColors.ink, width: 1),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Jam Monospace Hitam Pekat
          SizedBox(
            width: 46,
            child: MicroText(slot.time, fontSize: 11, fontWeight: FontWeight.w900),
          ),

          // 3. Mini Box Ikon Cuaca Hitam Retro
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _icon(slot.kind),
              size: 15,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 8),

          // 4. Judul Cuaca, Badge Cap Kaset & Catatan Aktivitas Sasak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      slot.title,
                      style: AppTypography.display(fontSize: 12.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppColors.ink, width: 1),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTypography.mono(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          color: badgeFg,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  slot.note,
                  style: AppTypography.body(fontSize: 9.5, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 5. Suhu Monospace
          Text(
            '${slot.temp}°C',
            style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

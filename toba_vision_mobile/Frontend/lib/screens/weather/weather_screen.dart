import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/services.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_view.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return AsyncView<(UserProfile, WeatherData)>(
      load: () async {
        final p = await Services.user.getProfile();
        final w = await Services.weather.getWeather();
        return (p, w);
      },
      builder: (context, d) {
        final p = d.$1;
        final w = d.$2;
        final ok = w.safeToDry;

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
                  subtitle: '${w.location.toUpperCase()} • METEOROLOGI KEBUN',
                  padding: EdgeInsets.zero,
                  height: null,
                  logoSize: 40,
                  logoIcon: Icons.wb_sunny_rounded,
                  logoBg: AppColors.ink,
                  logoColor: AppColors.lime,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prakiraan cuaca kebun berhasil diperbarui!'),
                          duration: Duration(seconds: 2),
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
                const SizedBox(height: 14),

                // 1. Kartu Kondisi Cuaca Utama (RetroCard Paper)
                RetroCard(
                  tapeTag: 'LIVE WEATHER // SENSOR ${w.location.toUpperCase()}',
                  rightTag: 'STATUS: ${ok ? "OPTIMAL" : "WARNING"}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${w.temp}°C',
                                style: AppTypography.display(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -2,
                                  color: AppColors.ink,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    w.condition,
                                    style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  MicroText('•  ${w.subCondition}', fontSize: 10, color: AppColors.muted),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.ink, width: 2),
                            ),
                            child: Icon(
                              _icon(w.slots.isNotEmpty ? w.slots.first.kind : WeatherKind.sunny),
                              color: ok ? AppColors.lime : AppColors.orange,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Kotak Rekomendasi Jemur Sasak
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: ok ? AppColors.lime : const Color(0xFFFED7AA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              color: ok ? AppColors.ink : AppColors.red,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MicroText(
                                    ok ? 'STATUS JEMUR: AMAN DI SASAK' : 'PERINGATAN: ANGKAT SASAK KE GUDANG',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: ok ? AppColors.ink : AppColors.red,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    w.statusMessage.replaceAll('\n', ' '),
                                    style: AppTypography.body(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Kartu Jadwal Tracklist Cuaca Siang & Sore
                RetroCard(
                  tapeTag: 'HOURLY TRACKLIST // SIANG & SORE',
                  rightTag: '3 SLOTS',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < w.slots.length; i++) ...[
                        _buildTracklistSlotItem(w.slots[i]),
                        if (i < w.slots.length - 1)
                          const Divider(color: AppColors.ink, height: 16, thickness: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Kartu Tips "Si Daun Toba" Miring Sedikit (Stiker Kaset)
                Transform.rotate(
                  angle: -0.015,
                  child: RetroCard(
                    backgroundColor: const Color(0xFFFEF9C3),
                    tapeTag: ok ? 'TIPS KEBUN // SI DAUN TOBA' : 'PERINGATAN DARURAT // SI DAUN TOBA',
                    rightTag: ok ? 'REKOMENDASI' : 'WASPADA',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.wb_incandescent_outlined, color: AppColors.ink, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '"${w.tip}"',
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

  Widget _buildTracklistSlotItem(WeatherSlot slot) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: slot.highlight
          ? BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        children: [
          // Waktu Monospace
          SizedBox(
            width: 52,
            child: MicroText(slot.time, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          // Ikon Cuaca
          Icon(_icon(slot.kind), size: 20, color: AppColors.ink),
          const SizedBox(width: 10),
          // Judul & Catatan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.title,
                  style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  slot.note,
                  style: AppTypography.body(fontSize: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          // Suhu
          Text(
            '${slot.temp}°C',
            style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

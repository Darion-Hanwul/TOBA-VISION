import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/services.dart';
import '../../widgets/async_view.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  static IconData _icon(WeatherKind k) {
    switch (k) {
      case WeatherKind.sunny:
        return Icons.wb_sunny_outlined;
      case WeatherKind.cloudy:
        return Icons.cloud_outlined;
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
        final main = ok ? AppColors.forest : AppColors.red;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${greeting()}, ${p.name}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.forest)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: cardDeco(radius: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Kondisi Kebun ${w.location}',
                        style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text('${w.temp}°C',
                          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: main)),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.condition, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text(w.subCondition, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                      ]),
                    ]),
                  ]),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ok ? AppColors.peach : AppColors.redSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ok ? Icons.wb_sunny_rounded : Icons.thunderstorm_rounded,
                      color: ok ? AppColors.ink : AppColors.red),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ok ? AppColors.mint : AppColors.redSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: ok ? null : Border.all(color: const Color(0xFFF5A3A3)),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: main, shape: BoxShape.circle),
                    child: Icon(ok ? Icons.check_rounded : Icons.warning_amber_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(w.statusMessage,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ok ? AppColors.forest : AppColors.red)),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: cardDeco(radius: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text('Prakiraan Siang &\nSore',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                ),
                Text('Hari\nIni', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
              const SizedBox(height: 12),
              for (final s in w.slots) _slot(s),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: ok
                  ? const LinearGradient(colors: [Color(0xFFE6F8EC), Color(0xFFFFFBEA)])
                  : const LinearGradient(colors: [Color(0xFFFFEFEF), Color(0xFFFFF5F0)]),
              border: Border.all(color: ok ? const Color(0xFFA7E3BB) : const Color(0xFFF5A3A3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 8, color: ok ? AppColors.green : AppColors.red),
                  const SizedBox(width: 6),
                  Text(ok ? 'Tips Si Daun Toba' : 'Darurat Si Daun Toba',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ok ? AppColors.forest : AppColors.red)),
                ]),
              ),
              const SizedBox(height: 10),
              Text('"${w.tip}"', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _slot(WeatherSlot s) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: s.highlight ? AppColors.amberSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: s.highlight ? Border.all(color: const Color(0xFFFFE0B8)) : null,
      ),
      child: Row(children: [
        Text(s.time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: s.highlight ? const Color(0xFFF59E0B) : const Color(0xFFE6EEFA),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(s.kind), size: 22, color: s.highlight ? Colors.white : const Color(0xFF3B6FB6)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: s.highlight ? AppColors.amber : AppColors.ink)),
            Text(s.note,
                style: TextStyle(fontSize: 13, color: s.highlight ? AppColors.amber : AppColors.muted)),
          ]),
        ),
        Text('${s.temp}°C',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: s.highlight ? AppColors.amber : AppColors.ink)),
      ]),
    );
  }
}

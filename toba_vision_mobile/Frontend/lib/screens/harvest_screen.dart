import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/services.dart';
import '../widgets/async_view.dart';

/// Layar ini belum ada di desain Figma - versi sederhana agar tab tidak kosong.
class HarvestScreen extends StatelessWidget {
  const HarvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<HarvestItem>>(
      load: () => Services.harvest.getSchedule(),
      builder: (context, list) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Jadwal Panen',
            style: TextStyle(fontFamily: kSerif, fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 8),
        for (final h in list)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(radius: 18),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.agriculture_outlined, color: Color(0xFF3730A3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.plot, style: const TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${h.date} • est. ${h.estimateKg} kg',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: h.status == 'Siap petik' ? AppColors.mint : const Color(0xFFF1F2F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(h.status,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: h.status == 'Siap petik' ? AppColors.forest : AppColors.muted)),
              ),
            ]),
          ),
      ]),
    );
  }
}

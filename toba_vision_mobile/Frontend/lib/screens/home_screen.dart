import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/services.dart';
import '../widgets/async_view.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return AsyncView<UserProfile>(
      load: () => Services.user.getProfile(),
      builder: (context, p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          Text('${greeting()}, ${p.name}',
              style: const TextStyle(fontFamily: kSerif, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.groups_rounded, size: 16, color: AppColors.amber),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${p.group} • ${p.region}',
                  style: const TextStyle(fontFamily: kSerif, fontSize: 14, color: AppColors.muted)),
            ),
          ]),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fitur Utama Lapangan',
                  style: TextStyle(fontFamily: kSerif, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Akses Cepat',
                  style: TextStyle(fontFamily: kSerif, fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          _featureGrid(),
          const SizedBox(height: 20),
          _banner(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.spa_outlined, color: Colors.white),
      ),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TOBA VISION',
            style: TextStyle(fontFamily: kSerif, fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.forest)),
        Row(children: [
          Icon(Icons.location_on_outlined, size: 14, color: AppColors.amber),
          SizedBox(width: 2),
          Text('TEMANGGUNG, JATENG',
              style: TextStyle(fontFamily: kSerif, fontSize: 12, letterSpacing: 0.8, color: AppColors.muted)),
        ]),
      ]),
    ]);
  }

  Widget _featureGrid() {
    return Container(
      decoration: cardDeco(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _cell(Icons.local_florist_outlined, AppColors.mint, AppColors.green,
                  'Deteksi AI', 'Pindai Daun Kebun', 1)),
              Container(width: 1, color: AppColors.line),
              Expanded(child: _cell(Icons.wb_sunny_outlined, AppColors.peach, AppColors.amber,
                  'Cuaca', 'Prakiraan & Jemur', 4)),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.line),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _cell(Icons.payments_outlined, const Color(0xFFE5E7EB), AppColors.ink,
                  'Keuangan', 'Buku Kas & Biaya', 2)),
              Container(width: 1, color: AppColors.line),
              Expanded(child: _cell(Icons.agriculture_outlined, const Color(0xFFE0E7FF), const Color(0xFF3730A3),
                  'Panen', 'Jadwal & Hasil Petik', 3)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _cell(IconData icon, Color bg, Color fg, String title, String sub, int tab) {
    return InkWell(
      onTap: () => onNavigate(tab),
      child: Container(
        constraints: const BoxConstraints(minHeight: 125),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: fg),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: kSerif, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: kSerif, fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.green, Color(0xFF14572F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        const Positioned(
          right: -4,
          top: -4,
          child: Icon(Icons.local_florist_outlined, size: 64, color: Color(0x33FFFFFF)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.mint),
              SizedBox(width: 6),
              Text('AI Vision Standar SNI',
                  style: TextStyle(fontFamily: kSerif, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mint)),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Pindai Mutu Daun Tembakau',
              style: TextStyle(fontFamily: kSerif, fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Arahkan kamera ke daun untuk cek kematangan & prediksi grade instan.',
              style: TextStyle(fontFamily: kSerif, fontSize: 14, color: AppColors.mint)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.forest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => onNavigate(1),
              icon: const Icon(Icons.photo_camera_rounded, size: 20),
              label: const Text('Buka Kamera AI',
                  style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ]),
      ]),
    );
  }
}

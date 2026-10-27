import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/services.dart';
import '../widgets/app_header.dart';
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
          const AppHeader(
            subtitle: 'TEMANGGUNG, JATENG',
            padding: EdgeInsets.zero,
            height: null,
            logoSize: 44,
            logoBg: AppColors.forest,
            logoColor: Colors.white,
            logoIcon: Icons.spa_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            '${greeting()}, ${p.name}',
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.groups_rounded, size: 16, color: AppColors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${p.group} • ${p.region}',
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fitur Utama Lapangan',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Akses Cepat',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeatureGrid(onNavigate: onNavigate),
          const SizedBox(height: 20),
          _AiBanner(onTap: () => onNavigate(1)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Grid Model & Data
// ---------------------------------------------------------------------------

class _FeatureItem {
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  final int tabIndex;

  const _FeatureItem({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.title,
    required this.subtitle,
    required this.tabIndex,
  });
}

const List<_FeatureItem> _features = [
  _FeatureItem(
    icon: Icons.local_florist_outlined,
    bg: AppColors.mint,
    fg: AppColors.green,
    title: 'Deteksi AI',
    subtitle: 'Pindai Daun Kebun',
    tabIndex: 1,
  ),
  _FeatureItem(
    icon: Icons.wb_sunny_outlined,
    bg: AppColors.peach,
    fg: AppColors.amber,
    title: 'Cuaca',
    subtitle: 'Prakiraan & Jemur',
    tabIndex: 4,
  ),
  _FeatureItem(
    icon: Icons.payments_outlined,
    bg: Color(0xFFE5E7EB),
    fg: AppColors.ink,
    title: 'Keuangan',
    subtitle: 'Buku Kas & Biaya',
    tabIndex: 2,
  ),
  _FeatureItem(
    icon: Icons.agriculture_outlined,
    bg: Color(0xFFE0E7FF),
    fg: Color(0xFF3730A3),
    title: 'Panen',
    subtitle: 'Jadwal & Hasil Petik',
    tabIndex: 3,
  ),
];

// ---------------------------------------------------------------------------
// Feature Grid Widget
// ---------------------------------------------------------------------------

class _FeatureGrid extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _FeatureGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (int i = 0; i < _features.length; i += 2) {
      if (i > 0) {
        rows.add(Container(height: 1, color: AppColors.line));
      }

      final first = _features[i];
      final hasSecond = i + 1 < _features.length;
      final second = hasSecond ? _features[i + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FeatureCell(
                  item: first,
                  onTap: () => onNavigate(first.tabIndex),
                ),
              ),
              if (second != null) ...[
                Container(width: 1, color: AppColors.line),
                Expanded(
                  child: _FeatureCell(
                    item: second,
                    onTap: () => onNavigate(second.tabIndex),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: cardDeco(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature Cell Widget
// ---------------------------------------------------------------------------

class _FeatureCell extends StatelessWidget {
  final _FeatureItem item;
  final VoidCallback onTap;

  const _FeatureCell({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.fg),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: kSerif,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: kSerif,
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Banner Widget (kept in-file)
// ---------------------------------------------------------------------------

class _AiBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _AiBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        children: [
          const Positioned(
            right: -4,
            top: -4,
            child: Icon(Icons.local_florist_outlined, size: 64, color: Color(0x33FFFFFF)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AppColors.mint),
                    SizedBox(width: 6),
                    Text(
                      'AI Vision Standar SNI',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pindai Mutu Daun Tembakau',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Arahkan kamera ke daun untuk cek kematangan & prediksi grade instan.',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 14,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.photo_camera_rounded, size: 20),
                  label: const Text(
                    'Buka Kamera AI',
                    style: TextStyle(
                      fontFamily: kSerif,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

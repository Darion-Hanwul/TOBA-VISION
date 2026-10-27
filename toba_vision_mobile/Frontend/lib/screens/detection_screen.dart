import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/services.dart';
import '../widgets/async_view.dart';

class DetectionScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DetectionScreen({super.key, required this.onBack});
  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  int _scan = 0;

  /// TODO: saat siap, ambil foto pakai image_picker lalu kirim path-nya:
  ///   final x = await ImagePicker().pickImage(source: ImageSource.camera);
  ///   Services.detection.analyze(imagePath: x?.path);
  void _capture() => setState(() => _scan++);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.bg,
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(children: [
          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_rounded)),
          const Expanded(
            child: Text('Hasil Deteksi Grade Ai',
                style: TextStyle(fontFamily: kSerif, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.forest,
            child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
          ),
        ]),
      ),
      Expanded(
        child: AsyncView<DetectionResult>(
          key: ValueKey(_scan),
          load: () => Services.detection.analyze(),
          builder: (context, r) => _result(r),
        ),
      ),
    ]);
  }

  Widget _result(DetectionResult r) {
    final color = r.isGood ? AppColors.green : AppColors.red;
    final soft = r.isGood ? AppColors.mint : AppColors.redSoft;
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: cardDeco(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(r.grade,
                    style: const TextStyle(fontFamily: kSerif, fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                const SizedBox(height: 2),
                Text(r.gradeName,
                    style: const TextStyle(fontFamily: kSerif, fontSize: 11, letterSpacing: 1.2, color: Colors.white)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(r.isGood ? Icons.check_circle_outline : Icons.cancel_outlined, size: 14, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(r.badge,
                          style: TextStyle(fontFamily: kSerif, fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(r.title,
                    style: const TextStyle(fontFamily: kSerif, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Text(r.description,
              style: const TextStyle(fontFamily: kSerif, fontSize: 15, height: 1.6, color: AppColors.muted)),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.help_outline_rounded, size: 20, color: AppColors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text('Foto Terlihat Agak Buram atau Kurang Terang?',
                  style: TextStyle(fontFamily: kSerif, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(r.photoTip,
              style: const TextStyle(fontFamily: kSerif, fontSize: 15, height: 1.5, color: AppColors.muted)),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE5E7EB),
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _capture,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Foto Ulang Sekarang', style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _capture,
          icon: const Icon(Icons.center_focus_strong_outlined),
          label: const Text('Foto Daun Lainnya', style: TextStyle(fontFamily: kSerif, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
    ]);
  }
}

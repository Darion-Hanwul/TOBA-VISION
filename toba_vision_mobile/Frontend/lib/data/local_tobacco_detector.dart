import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import 'models.dart';
import 'repositories.dart';
import 'tflite_runner.dart';

/// Spesifikasi terpadu pemetaan kelas YOLO ke label tampilan Grade atau Kematangan Toba Vision.
class TobaccoGradeSpec {
  final String grade;
  final String gradeName;
  final String badge;
  final String title;
  final String description;

  const TobaccoGradeSpec({
    required this.grade,
    required this.gradeName,
    required this.badge,
    required this.title,
    required this.description,
  });
}

class _ModelAssetConfig {
  final String modelAssetPath;
  final String labelsAssetPath;
  final List<String> defaultLabels;
  final String photoTip;

  const _ModelAssetConfig({
    required this.modelAssetPath,
    required this.labelsAssetPath,
    required this.defaultLabels,
    required this.photoTip,
  });
}

/// Detector AI 100% lokal (on-device offline) berbasis TFLite untuk 2 model YOLO11:
/// 1. `grade` (`tobacco_yolo11s.tflite`): Deteksi objek Grade A / B / C.
/// 2. `maturity` (`tobacco_maturity_yolo11n_cls.tflite`): Klasifikasi kematangan siap panen.
class LocalTobaccoDetector {
  LocalTobaccoDetector._();
  static final LocalTobaccoDetector instance = LocalTobaccoDetector._();

  static const String modelAssetPath = 'assets/ml/tobacco_yolo11s.tflite';
  static const String labelsAssetPath = 'assets/ml/labels.txt';
  static const List<String> defaultLabels = [
    'High Quality',
    'Low Quality',
    'Medium Quality',
  ];

  static const String maturityModelAssetPath =
      'assets/ml/tobacco_maturity_yolo11n_cls.tflite';
  static const String maturityLabelsAssetPath = 'assets/ml/maturity_labels.txt';
  static const List<String> defaultMaturityLabels = [
    'Immature',
    'Mature',
    'Overripe',
  ];

  static const double defaultConfThreshold = 0.25;
  static const double defaultIouThreshold = 0.45;
  static const String defaultPhotoTip =
      'Posisikan 1–2 helai daun tembakau di tengah kotak reticle dengan pencahayaan terang merata (hindari bayangan HP).';
  static const String defaultMaturityPhotoTip =
      'Arahkan kamera dekat ke permukaan helai daun segar dengan cahaya merata agar warna hijau hingga kekuningan terbaca jelas.';

  static const Map<TobaccoDetectionMode, _ModelAssetConfig> _modelConfigs = {
    TobaccoDetectionMode.grade: _ModelAssetConfig(
      modelAssetPath: modelAssetPath,
      labelsAssetPath: labelsAssetPath,
      defaultLabels: defaultLabels,
      photoTip: defaultPhotoTip,
    ),
    TobaccoDetectionMode.maturity: _ModelAssetConfig(
      modelAssetPath: maturityModelAssetPath,
      labelsAssetPath: maturityLabelsAssetPath,
      defaultLabels: defaultMaturityLabels,
      photoTip: defaultMaturityPhotoTip,
    ),
  };

  static const TobaccoGradeSpec _gradeASpec = TobaccoGradeSpec(
    grade: 'A',
    gradeName: 'BAGUS • SUPER',
    badge: 'GRADE A • KUALITAS BAGUS (SUPER)',
    title: 'Mutu Prima, Layak Jual Harga Terbaik',
    description:
        'Daun terdeteksi berkualitas tinggi (High Quality): warna cerah merata, permukaan baik, dan minim cacat/bercak. Optimal untuk standar penjualan Grade A.',
  );

  static const TobaccoGradeSpec _gradeBSpec = TobaccoGradeSpec(
    grade: 'B',
    gradeName: 'SEDANG • STANDAR',
    badge: 'GRADE B • KUALITAS SEDANG (STANDAR)',
    title: 'Mutu Menengah, Perlu Sortir Ringan',
    description:
        'Daun terdeteksi berkualitas sedang (Medium Quality): kematangan belum merata atau terdapat sedikit variasi warna/serat. Pisahkan di kelompok Grade B.',
  );

  static const TobaccoGradeSpec _gradeCSpec = TobaccoGradeSpec(
    grade: 'C',
    gradeName: 'JELEK • AFKIR',
    badge: 'GRADE C • KUALITAS JELEK (AFKIR)',
    title: 'Mutu Rendah, Pisahkan dari Lot Utama',
    description:
        'Daun terdeteksi berkualitas rendah (Low Quality): warna kusam gelap, bercak/rusak hama, atau kering berlebih. Wajib dipisahkan agar tidak menjatuhkan nilai lot A/B.',
  );

  static const TobaccoGradeSpec _notDetectedSpec = TobaccoGradeSpec(
    grade: '-',
    gradeName: 'TIDAK TERDETEKSI',
    badge: 'DAUN TIDAK TERDETEKSI',
    title: 'Objek Daun Tembakau Belum Terbaca',
    description:
        'Model AI offline tidak menemukan objek daun tembakau dengan keyakinan memadai (>= 25%) pada foto ini.',
  );

  static const TobaccoGradeSpec _immatureSpec = TobaccoGradeSpec(
    grade: '1',
    gradeName: 'Belum Matang (Masih Muda)',
    badge: '1. BELUM MATANG (MASIH MUDA) • TUNDA PETIK',
    title: 'Belum Matang (Masih Muda)',
    description:
        'Daun masih hijau muda dan kadar patinya belum puncak. Biarkan di tanaman beberapa hari lagi hingga warna daun mulai menguning kehijauan agar hasil panen lebih berbobot.',
  );

  static const TobaccoGradeSpec _matureSpec = TobaccoGradeSpec(
    grade: '2',
    gradeName: 'Matang',
    badge: '2. MATANG • SIAP PANEN OPTIMAL',
    title: 'Matang — Siap Panen!',
    description:
        'Daun telah mencapai kematangan fisiologis terbaik (warna hijau kekuningan merata). Waktu petik paling tepat: panen di pagi hari dan lanjutkan pengeringan.',
  );

  static const TobaccoGradeSpec _overripeSpec = TobaccoGradeSpec(
    grade: '3',
    gradeName: 'Terlalu Matang',
    badge: '3. TERLALU MATANG • SEGERA PETIK',
    title: 'Terlalu Matang',
    description:
        'Daun sudah melewati puncak masa matang optimal dan mulai mengalami penguningan/pengeringan berlebih. Segera petik sekarang lalu pisahkan dari kelompok daun matang optimal.',
  );

  final Map<TobaccoDetectionMode, Uint8List> _cachedModelBytes = {};
  final Map<TobaccoDetectionMode, List<String>> _cachedLabels = {};

  /// Pemetaan seragam label dataset Roboflow / YOLO Grade ke spesifikasi Grade A / B / C.
  static TobaccoGradeSpec gradeSpecForRawLabel(String rawLabel) {
    final key = rawLabel.trim().toLowerCase();
    // Periksa 'immature' lebih dulu karena string tersebut mengandung substring 'mature'
    if (key.contains('immature') ||
        key.contains('medium') ||
        key.contains('med') ||
        key == 'grade b' ||
        key == 'b') {
      return _gradeBSpec;
    }
    if (key.contains('high') ||
        key == 'mature' ||
        key == 'grade a' ||
        key == 'a') {
      return _gradeASpec;
    }
    if (key.contains('low') ||
        key.contains('overripe') ||
        key == 'grade c' ||
        key == 'c') {
      return _gradeCSpec;
    }
    return _gradeBSpec;
  }

  /// Pemetaan 3 kelas model kematangan (`best.pt`: Immature / Mature / Overripe).
  static TobaccoGradeSpec maturitySpecForRawLabel(String rawLabel) {
    final key = rawLabel.trim().toLowerCase();
    // Periksa 'immature' lebih dulu karena mengandung substring 'mature'
    if (key.contains('immature') ||
        key.contains('belum') ||
        key.contains('muda')) {
      return _immatureSpec;
    }
    if (key.contains('overripe') ||
        key.contains('terlalu') ||
        key.contains('lewat')) {
      return _overripeSpec;
    }
    if (key.contains('mature') || key.contains('matang')) {
      return _matureSpec;
    }
    return _immatureSpec;
  }

  Future<(Uint8List, List<String>)> _loadAssets(TobaccoDetectionMode mode) async {
    final cachedBytes = _cachedModelBytes[mode];
    final cachedLbls = _cachedLabels[mode];
    if (cachedBytes != null && cachedLbls != null) {
      return (cachedBytes, cachedLbls);
    }

    final cfg = _modelConfigs[mode]!;
    final byteData = await rootBundle.load(cfg.modelAssetPath);
    final modelBytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );

    List<String> labels = List<String>.from(cfg.defaultLabels);
    try {
      final rawLabels = await rootBundle.loadString(cfg.labelsAssetPath);
      final parsed = rawLabels
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) {
        labels = parsed;
      }
    } catch (_) {
      // Gunakan defaultLabels jika file labels belum tersedia
    }

    _cachedModelBytes[mode] = modelBytes;
    _cachedLabels[mode] = labels;
    return (modelBytes, labels);
  }

  /// Menjalankan inferensi YOLO11 lokal (Grade atau Kematangan) dari path file foto.
  Future<DetectionResult> analyzeFile(
    String imagePath, {
    TobaccoDetectionMode mode = TobaccoDetectionMode.grade,
  }) async {
    if (kIsWeb || !isNativeTfliteSupported) {
      return _unsupportedPlatformResult(mode);
    }

    final imageBytes = await readLocalFileBytes(imagePath);
    return analyzeImageBytes(imageBytes, imagePath: imagePath, mode: mode);
  }

  /// Menjalankan inferensi TFLite YOLO11 di background Isolate agar UI kamera tetap mulus.
  Future<DetectionResult> analyzeImageBytes(
    Uint8List imageBytes, {
    String? imagePath,
    TobaccoDetectionMode mode = TobaccoDetectionMode.grade,
    double confThreshold = defaultConfThreshold,
    double iouThreshold = defaultIouThreshold,
  }) async {
    if (kIsWeb || !isNativeTfliteSupported) {
      return _unsupportedPlatformResult(mode);
    }

    final (modelBytes, labels) = await _loadAssets(mode);
    final tip = _modelConfigs[mode]!.photoTip;

    final sw = Stopwatch()..start();
    final _IsolateInferenceOutput rawOut = await runNativeTfliteInference(
      modelBytes: modelBytes,
      prepareInput: (inputSize) {
        final decoded = img.decodeImage(imageBytes);
        if (decoded == null) {
          throw const FormatException('Gagal membaca format gambar foto.');
        }
        // Perbaiki rotasi kamera Android berdasarkan metadata EXIF
        final oriented = img.bakeOrientation(decoded);
        final pre = mode == TobaccoDetectionMode.grade
            ? _letterboxPreprocess(oriented, inputSize)
            : _centerCropPreprocess(oriented, inputSize);

        return (
          tensorData: pre.inputFloat32,
          meta: (
            inputSize: inputSize,
            origWidth: oriented.width,
            origHeight: oriented.height,
            scale: pre.scale,
            padLeft: pre.padLeft,
            padTop: pre.padTop,
          ),
        );
      },
      parseOutput: (outputShape, outputFloats, meta) {
        if (mode == TobaccoDetectionMode.maturity) {
          final probs = parseYolo11Classification(
            outputData: outputFloats,
            labels: labels,
          );
          return _IsolateInferenceOutput(
            origWidth: meta.origWidth,
            origHeight: meta.origHeight,
            classProbabilities: probs,
          );
        }

        final detections = parseYolo11Detections(
          outputData: outputFloats,
          outputShape: outputShape,
          labels: labels,
          inputSize: meta.inputSize,
          origWidth: meta.origWidth,
          origHeight: meta.origHeight,
          scale: meta.scale,
          padLeft: meta.padLeft,
          padTop: meta.padTop,
          confThreshold: confThreshold,
          iouThreshold: iouThreshold,
        );

        return _IsolateInferenceOutput(
          origWidth: meta.origWidth,
          origHeight: meta.origHeight,
          detections: detections,
        );
      },
    );
    sw.stop();

    if (mode == TobaccoDetectionMode.maturity) {
      if (rawOut.classProbabilities.isEmpty) {
        return DetectionResult(
          mode: mode,
          grade: '-',
          gradeName: 'TIDAK TERDETEKSI',
          badge: 'GAGAL MEMBACA KEMATANGAN',
          title: 'Hasil Klasifikasi Kosong',
          description:
              'Model kematangan tidak menghasilkan skor kelas yang valid. Coba ambil foto ulang dengan fokus lebih jelas.',
          photoTip: tip,
          confidencePercent: 0.0,
          inferenceMs: sw.elapsedMilliseconds,
          rawLabel: 'Tidak Terdeteksi',
          imagePath: imagePath,
          imageWidth: rawOut.origWidth,
          imageHeight: rawOut.origHeight,
        );
      }

      final primary = rawOut.classProbabilities.first;
      final spec = maturitySpecForRawLabel(primary.rawLabel);

      return DetectionResult(
        mode: mode,
        grade: spec.grade,
        gradeName: spec.gradeName,
        badge: spec.badge,
        title: spec.title,
        description: spec.description,
        photoTip: tip,
        confidencePercent: double.parse((primary.confidence * 100).toStringAsFixed(1)),
        inferenceMs: sw.elapsedMilliseconds,
        rawLabel: primary.rawLabel,
        imagePath: imagePath,
        imageWidth: rawOut.origWidth,
        imageHeight: rawOut.origHeight,
        classProbabilities: rawOut.classProbabilities,
      );
    }

    if (rawOut.detections.isEmpty) {
      return DetectionResult(
        mode: mode,
        grade: _notDetectedSpec.grade,
        gradeName: _notDetectedSpec.gradeName,
        badge: _notDetectedSpec.badge,
        title: _notDetectedSpec.title,
        description: _notDetectedSpec.description,
        photoTip: tip,
        confidencePercent: 0.0,
        inferenceMs: sw.elapsedMilliseconds,
        rawLabel: 'Tidak Terdeteksi',
        imagePath: imagePath,
        imageWidth: rawOut.origWidth,
        imageHeight: rawOut.origHeight,
        detections: const [],
      );
    }

    final primary = rawOut.detections.first;
    final spec = gradeSpecForRawLabel(primary.rawLabel);

    return DetectionResult(
      mode: mode,
      grade: spec.grade,
      gradeName: spec.gradeName,
      badge: spec.badge,
      title: spec.title,
      description: spec.description,
      photoTip: tip,
      confidencePercent: double.parse((primary.confidence * 100).toStringAsFixed(1)),
      inferenceMs: sw.elapsedMilliseconds,
      rawLabel: primary.rawLabel,
      imagePath: imagePath,
      imageWidth: rawOut.origWidth,
      imageHeight: rawOut.origHeight,
      detections: rawOut.detections,
    );
  }

  static DetectionResult _unsupportedPlatformResult(TobaccoDetectionMode mode) {
    return DetectionResult(
      mode: mode,
      grade: '-',
      gradeName: 'KHUSUS ANDROID',
      badge: 'MODE OFFLINE TFLITE // KHUSUS HP ANDROID',
      title: 'Jalankan di Aplikasi Android / Emulator',
      description:
          'Inferensi AI TFLite lokal memakai native FFI Android/Mobile. Buka aplikasi di HP Android untuk memindai daun tembakau secara offline.',
      photoTip: _modelConfigs[mode]!.photoTip,
    );
  }

  /// Resize proporsional (letterbox 114/255) ke inputSize x inputSize NHWC Float32 [0..1] untuk Detection.
  static _PreprocessedImage _letterboxPreprocess(img.Image oriented, int inputSize) {
    final origW = oriented.width;
    final origH = oriented.height;

    final double scale = math.min(inputSize / origW, inputSize / origH);
    final int newW = math.max(1, (origW * scale).round());
    final int newH = math.max(1, (origH * scale).round());
    final int padLeft = (inputSize - newW) ~/ 2;
    final int padTop = (inputSize - newH) ~/ 2;

    final img.Image resized = img.copyResize(
      oriented,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    const double padVal = 114.0 / 255.0;
    final Float32List buffer = Float32List(inputSize * inputSize * 3);
    buffer.fillRange(0, buffer.length, padVal);

    for (int y = 0; y < newH; y++) {
      final int dstY = padTop + y;
      for (int x = 0; x < newW; x++) {
        final pixel = resized.getPixel(x, y);
        final int idx = (dstY * inputSize + (padLeft + x)) * 3;
        buffer[idx] = pixel.rNormalized.toDouble();
        buffer[idx + 1] = pixel.gNormalized.toDouble();
        buffer[idx + 2] = pixel.bNormalized.toDouble();
      }
    }

    return _PreprocessedImage(
      inputFloat32: buffer,
      scale: scale,
      padLeft: padLeft,
      padTop: padTop,
    );
  }

  /// Resize sisi terpendek ke [inputSize] lalu CenterCrop [inputSize]x[inputSize]
  /// sesuai transformasi resmi Ultralytics `yolo11n-cls` (`Resize(640) + CenterCrop(640)`).
  static _PreprocessedImage _centerCropPreprocess(img.Image oriented, int inputSize) {
    final origW = oriented.width;
    final origH = oriented.height;

    final int minSide = math.max(1, math.min(origW, origH));
    final double scale = inputSize / minSide;
    final int newW = math.max(inputSize, (origW * scale).round());
    final int newH = math.max(inputSize, (origH * scale).round());
    final int cropLeft = math.max(0, (newW - inputSize) ~/ 2);
    final int cropTop = math.max(0, (newH - inputSize) ~/ 2);

    final img.Image resized = img.copyResize(
      oriented,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    final Float32List buffer = Float32List(inputSize * inputSize * 3);
    for (int y = 0; y < inputSize; y++) {
      final int srcY = cropTop + y;
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(cropLeft + x, srcY);
        final int idx = (y * inputSize + x) * 3;
        buffer[idx] = pixel.rNormalized.toDouble();
        buffer[idx + 1] = pixel.gNormalized.toDouble();
        buffer[idx + 2] = pixel.bNormalized.toDouble();
      }
    }

    return _PreprocessedImage(
      inputFloat32: buffer,
      scale: scale,
      padLeft: cropLeft,
      padTop: cropTop,
    );
  }

  /// Parsing tensor output YOLO11n-cls (`[1, C]`) menjadi daftar probabilitas terurut tertinggi.
  @visibleForTesting
  static List<TobaccoClassProbability> parseYolo11Classification({
    required Float32List outputData,
    required List<String> labels,
  }) {
    if (labels.isEmpty || outputData.length < labels.length) {
      return const [];
    }

    final int count = labels.length;
    final rawScores = List<double>.generate(count, (i) => outputData[i].toDouble());

    final bool allNonNegative = rawScores.every((v) => v >= 0.0 && v.isFinite);
    final double rawSum = rawScores.fold<double>(0.0, (acc, v) => acc + v);

    final List<double> probs;
    if (allNonNegative && rawSum > 0.0 && (rawSum - 1.0).abs() <= 0.05) {
      probs = rawScores.map((v) => (v / rawSum).clamp(0.0, 1.0)).toList();
    } else {
      final double maxLogit = rawScores.reduce(math.max);
      final exps = rawScores.map((v) => math.exp(v - maxLogit)).toList();
      final double sumExp = exps.fold<double>(0.0, (acc, v) => acc + v);
      probs = sumExp > 0.0
          ? exps.map((e) => (e / sumExp).clamp(0.0, 1.0)).toList()
          : List<double>.filled(count, 1.0 / count);
    }

    final List<TobaccoClassProbability> results = [];
    for (int i = 0; i < count; i++) {
      final spec = maturitySpecForRawLabel(labels[i]);
      results.add(
        TobaccoClassProbability(
          rawLabel: labels[i],
          code: spec.grade,
          label: spec.gradeName,
          confidence: probs[i],
        ),
      );
    }

    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  /// Parsing tensor output YOLO11 Object Detection (`[1, 4+C, N]` atau `[1, N, 4+C]`) + NMS.
  @visibleForTesting
  static List<TobaccoDetectionBox> parseYolo11Detections({
    required Float32List outputData,
    required List<int> outputShape,
    required List<String> labels,
    required int inputSize,
    required int origWidth,
    required int origHeight,
    required double scale,
    required int padLeft,
    required int padTop,
    double confThreshold = defaultConfThreshold,
    double iouThreshold = defaultIouThreshold,
  }) {
    if (outputShape.length != 3 || labels.isEmpty) {
      return const [];
    }

    final int numClasses = labels.length;
    final int attrCount = 4 + numClasses;

    final bool channelsFirst;
    final int numBoxes;
    if (outputShape[1] == attrCount) {
      channelsFirst = true;
      numBoxes = outputShape[2];
    } else if (outputShape[2] == attrCount) {
      channelsFirst = false;
      numBoxes = outputShape[1];
    } else {
      return const [];
    }

    double readVal(int boxIdx, int attrIdx) {
      return channelsFirst
          ? outputData[attrIdx * numBoxes + boxIdx]
          : outputData[boxIdx * attrCount + attrIdx];
    }

    // Deteksi apakah koordinat sudah skala piksel [0..inputSize] atau ternormalisasi [0..1]
    double maxAbsCoord = 0.0;
    final int probeStep = math.max(1, numBoxes ~/ 200);
    for (int i = 0; i < numBoxes; i += probeStep) {
      for (int a = 0; a < 4; a++) {
        final v = readVal(i, a).abs();
        if (v > maxAbsCoord) maxAbsCoord = v;
      }
    }
    final double coordMultiplier = maxAbsCoord > 2.0 ? 1.0 : inputSize.toDouble();

    final List<TobaccoDetectionBox> candidates = [];
    for (int i = 0; i < numBoxes; i++) {
      int bestCls = 0;
      double bestScore = -1.0;
      for (int c = 0; c < numClasses; c++) {
        final score = readVal(i, 4 + c);
        if (score > bestScore) {
          bestScore = score;
          bestCls = c;
        }
      }
      if (bestScore < confThreshold) continue;

      final double cx = readVal(i, 0) * coordMultiplier;
      final double cy = readVal(i, 1) * coordMultiplier;
      final double bw = readVal(i, 2) * coordMultiplier;
      final double bh = readVal(i, 3) * coordMultiplier;

      final double x1Lb = cx - bw / 2.0;
      final double y1Lb = cy - bh / 2.0;
      final double x2Lb = cx + bw / 2.0;
      final double y2Lb = cy + bh / 2.0;

      // Kembalikan ke koordinat ternormalisasi [0..1] terhadap gambar asli sebelum letterbox
      final double left = ((x1Lb - padLeft) / scale).clamp(0.0, origWidth.toDouble()) / origWidth;
      final double top = ((y1Lb - padTop) / scale).clamp(0.0, origHeight.toDouble()) / origHeight;
      final double right = ((x2Lb - padLeft) / scale).clamp(0.0, origWidth.toDouble()) / origWidth;
      final double bottom = ((y2Lb - padTop) / scale).clamp(0.0, origHeight.toDouble()) / origHeight;

      final double wNorm = right - left;
      final double hNorm = bottom - top;
      if (wNorm <= 0.01 || hNorm <= 0.01) continue;

      final String rawLabel = labels[bestCls];
      final spec = gradeSpecForRawLabel(rawLabel);

      candidates.add(
        TobaccoDetectionBox(
          rawLabel: rawLabel,
          grade: spec.grade,
          gradeName: spec.gradeName,
          confidence: bestScore.clamp(0.0, 1.0),
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
      );
    }

    if (candidates.isEmpty) return const [];

    final kept = _applyNms(candidates, iouThreshold);

    // Urutkan kotak utama berdasarkan bobot dominan (confidence * (0.5 + area_relatif))
    kept.sort((a, b) {
      final scoreA = a.confidence * (0.5 + a.area);
      final scoreB = b.confidence * (0.5 + b.area);
      return scoreB.compareTo(scoreA);
    });

    return kept;
  }

  static List<TobaccoDetectionBox> _applyNms(
    List<TobaccoDetectionBox> boxes,
    double iouThreshold,
  ) {
    final sorted = List<TobaccoDetectionBox>.from(boxes)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final List<TobaccoDetectionBox> kept = [];

    for (final candidate in sorted) {
      bool suppressed = false;
      for (final accepted in kept) {
        if (_iou(candidate, accepted) > iouThreshold) {
          suppressed = true;
          break;
        }
      }
      if (!suppressed) {
        kept.add(candidate);
      }
    }
    return kept;
  }

  static double _iou(TobaccoDetectionBox a, TobaccoDetectionBox b) {
    final double interLeft = math.max(a.left, b.left);
    final double interTop = math.max(a.top, b.top);
    final double interRight = math.min(a.right, b.right);
    final double interBottom = math.min(a.bottom, b.bottom);

    final double interW = math.max(0.0, interRight - interLeft);
    final double interH = math.max(0.0, interBottom - interTop);
    final double interArea = interW * interH;
    if (interArea <= 0.0) return 0.0;

    final double unionArea = a.area + b.area - interArea;
    return unionArea > 0.0 ? interArea / unionArea : 0.0;
  }
}

/// Implementasi DetectionRepository berbasis Edge TFLite 100% offline.
class LocalDetectionRepository implements DetectionRepository {
  @override
  Future<DetectionResult> analyze({
    String? imagePath,
    TobaccoDetectionMode mode = TobaccoDetectionMode.grade,
  }) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return DetectionResult(
        mode: mode,
        grade: '-',
        gradeName: 'TIDAK ADA FOTO',
        badge: 'BELUM ADA FOTO',
        title: 'Ambil Foto Daun Terlebih Dahulu',
        description:
            'Gunakan tombol pindai AI atau Galeri untuk memilih gambar daun tembakau.',
        photoTip: mode == TobaccoDetectionMode.maturity
            ? LocalTobaccoDetector.defaultMaturityPhotoTip
            : LocalTobaccoDetector.defaultPhotoTip,
      );
    }
    return LocalTobaccoDetector.instance.analyzeFile(imagePath, mode: mode);
  }
}

class _PreprocessedImage {
  final Float32List inputFloat32;
  final double scale;
  final int padLeft;
  final int padTop;

  const _PreprocessedImage({
    required this.inputFloat32,
    required this.scale,
    required this.padLeft,
    required this.padTop,
  });
}

class _IsolateInferenceOutput {
  final int origWidth;
  final int origHeight;
  final List<TobaccoDetectionBox> detections;
  final List<TobaccoClassProbability> classProbabilities;

  const _IsolateInferenceOutput({
    required this.origWidth,
    required this.origHeight,
    this.detections = const [],
    this.classProbabilities = const [],
  });
}

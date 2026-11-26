import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toba_vision_mobile/data/local_tobacco_detector.dart';
import 'package:toba_vision_mobile/data/models.dart';
import 'package:toba_vision_mobile/screens/detection/detection_screen.dart';
import 'package:toba_vision_mobile/widgets/detection_result_sheet.dart';

void main() {
  group('LocalTobaccoDetector parsing, NMS & Grade mapping', () {
    test('maps High/Medium/Low Quality to Grade A/B/C uniformly', () {
      expect(LocalTobaccoDetector.gradeSpecForRawLabel('High Quality').grade, 'A');
      expect(LocalTobaccoDetector.gradeSpecForRawLabel('Medium Quality').grade, 'B');
      expect(LocalTobaccoDetector.gradeSpecForRawLabel('Low Quality').grade, 'C');
      expect(LocalTobaccoDetector.gradeSpecForRawLabel('Mature').grade, 'A');
      expect(LocalTobaccoDetector.gradeSpecForRawLabel('Immature').grade, 'B');
      expect(LocalTobaccoDetector.gradeSpecForRawLabel('Overripe').grade, 'C');
    });

    test('parses channels-first [1, 7, N] normalized boxes and applies NMS', () {
      const int n = 3;
      final Float32List out = Float32List(1 * 7 * n);

      void setBox(int idx, double cx, double cy, double w, double h, List<double> scores) {
        out[0 * n + idx] = cx;
        out[1 * n + idx] = cy;
        out[2 * n + idx] = w;
        out[3 * n + idx] = h;
        out[4 * n + idx] = scores[0];
        out[5 * n + idx] = scores[1];
        out[6 * n + idx] = scores[2];
      }

      setBox(0, 0.5, 0.5, 0.4, 0.4, [0.85, 0.05, 0.10]);
      setBox(1, 0.51, 0.50, 0.4, 0.4, [0.10, 0.05, 0.55]);
      setBox(2, 0.2, 0.2, 0.2, 0.2, [0.15, 0.20, 0.10]);

      final detections = LocalTobaccoDetector.parseYolo11Detections(
        outputData: out,
        outputShape: const [1, 7, n],
        labels: LocalTobaccoDetector.defaultLabels,
        inputSize: 640,
        origWidth: 640,
        origHeight: 640,
        scale: 1.0,
        padLeft: 0,
        padTop: 0,
      );

      expect(detections.length, 1);
      expect(detections.first.grade, 'A');
      expect(detections.first.rawLabel, 'High Quality');
      expect(detections.first.confidence, closeTo(0.85, 0.001));
      expect(detections.first.left, closeTo(0.3, 0.001));
      expect(detections.first.top, closeTo(0.3, 0.001));
      expect(detections.first.right, closeTo(0.7, 0.001));
      expect(detections.first.bottom, closeTo(0.7, 0.001));
    });

    test('parses channels-last [1, N, 7] pixel-scaled coordinates with letterbox padding', () {
      const int n = 2;
      final Float32List out = Float32List(1 * n * 7);

      final box0 = [320.0, 320.0, 320.0, 160.0, 0.08, 0.12, 0.78];
      for (int a = 0; a < 7; a++) {
        out[0 * 7 + a] = box0[a];
      }
      final box1 = [80.0, 200.0, 120.0, 80.0, 0.05, 0.72, 0.10];
      for (int a = 0; a < 7; a++) {
        out[1 * 7 + a] = box1[a];
      }

      final detections = LocalTobaccoDetector.parseYolo11Detections(
        outputData: out,
        outputShape: const [1, n, 7],
        labels: LocalTobaccoDetector.defaultLabels,
        inputSize: 640,
        origWidth: 800,
        origHeight: 400,
        scale: 0.8,
        padLeft: 0,
        padTop: 160,
      );

      expect(detections.length, 2);
      expect(detections.first.grade, 'B');
      expect(detections.first.rawLabel, 'Medium Quality');
      expect(detections.first.left, closeTo(0.25, 0.01));
      expect(detections.first.top, closeTo(0.25, 0.01));
      expect(detections.first.right, closeTo(0.75, 0.01));
      expect(detections.first.bottom, closeTo(0.75, 0.01));
      expect(detections[1].grade, 'C');
    });
  });

  group('LocalTobaccoDetector maturity classification (best.pt / yolo11n-cls)', () {
    test('maps Immature/Mature/Overripe to 3 Indonesian harvest readiness classes', () {
      final immature = LocalTobaccoDetector.maturitySpecForRawLabel('Immature');
      expect(immature.grade, '1');
      expect(immature.gradeName, 'Belum Matang (Masih Muda)');

      final mature = LocalTobaccoDetector.maturitySpecForRawLabel('Mature');
      expect(mature.grade, '2');
      expect(mature.gradeName, 'Matang');

      final overripe = LocalTobaccoDetector.maturitySpecForRawLabel('Overripe');
      expect(overripe.grade, '3');
      expect(overripe.gradeName, 'Terlalu Matang');
    });

    test('parses already-softmaxed [1, 3] classification probabilities sorted descending', () {
      final probs = LocalTobaccoDetector.parseYolo11Classification(
        outputData: Float32List.fromList([0.0836, 0.7603, 0.1561]),
        labels: LocalTobaccoDetector.defaultMaturityLabels,
      );

      expect(probs.length, 3);
      expect(probs[0].rawLabel, 'Mature');
      expect(probs[0].code, '2');
      expect(probs[0].label, 'Matang');
      expect(probs[0].confidence, closeTo(0.7603, 0.001));

      expect(probs[1].rawLabel, 'Overripe');
      expect(probs[1].code, '3');
      expect(probs[2].rawLabel, 'Immature');
      expect(probs[2].code, '1');
    });

    test('applies softmax fallback when raw classification output contains logits', () {
      final probs = LocalTobaccoDetector.parseYolo11Classification(
        outputData: Float32List.fromList([-1.0, 2.0, 0.0]),
        labels: LocalTobaccoDetector.defaultMaturityLabels,
      );

      expect(probs.length, 3);
      expect(probs.first.rawLabel, 'Mature');
      final total = probs.fold<double>(0.0, (sum, e) => sum + e.confidence);
      expect(total, closeTo(1.0, 0.0001));
    });
  });

  group('Detection UI widgets', () {
    testWidgets('DetectionScreen lets farmer switch between Grade and Maturity modes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: DetectionScreen(onBack: () {}),
        ),
      );
      await tester.pump();

      expect(find.text('GRADE TEMBAKAU'), findsOneWidget);
      expect(find.text('SIAP PANEN'), findsOneWidget);
      expect(find.text('-- PINDAI GRADE --'), findsOneWidget);

      await tester.tap(find.text('SIAP PANEN'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('-- CEK KEMATANGAN --'), findsOneWidget);
      expect(find.text('MODE KEMATANGAN // SIAP PANEN'), findsOneWidget);
    });

    testWidgets('DetectionResultSheet renders all 3 maturity scores for harvest readiness', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      const maturityResult = DetectionResult(
        mode: TobaccoDetectionMode.maturity,
        grade: '2',
        gradeName: 'Matang',
        badge: '2. MATANG • SIAP PANEN OPTIMAL',
        title: 'Matang — Siap Panen!',
        description: 'Daun telah mencapai kematangan fisiologis terbaik.',
        photoTip: LocalTobaccoDetector.defaultMaturityPhotoTip,
        confidencePercent: 86.4,
        inferenceMs: 42,
        rawLabel: 'Mature',
        classProbabilities: [
          TobaccoClassProbability(
            rawLabel: 'Mature',
            code: '2',
            label: 'Matang',
            confidence: 0.864,
          ),
          TobaccoClassProbability(
            rawLabel: 'Overripe',
            code: '3',
            label: 'Terlalu Matang',
            confidence: 0.092,
          ),
          TobaccoClassProbability(
            rawLabel: 'Immature',
            code: '1',
            label: 'Belum Matang (Masih Muda)',
            confidence: 0.044,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDetectionResultSheet(context, maturityResult),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('OFFLINE TFLITE // SIAP PANEN'), findsOneWidget);
      expect(find.text('Matang — Siap Panen!'), findsOneWidget);
      expect(find.text('2. MATANG'), findsOneWidget);
      expect(find.text('3. TERLALU MATANG'), findsOneWidget);
      expect(find.text('1. BELUM MATANG (MASIH MUDA)'), findsOneWidget);
      expect(find.text('86.4%'), findsOneWidget);
    });
  });
}

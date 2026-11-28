import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

typedef TflitePreparedInput<M> = ({Float32List tensorData, M meta});

/// Native TFLite binary (.so / framework) tersedia di Android dan iOS.
bool get isNativeTfliteSupported => Platform.isAndroid || Platform.isIOS;

Future<Uint8List> readLocalFileBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('File foto tidak ditemukan di perangkat: $path');
  }
  return file.readAsBytes();
}

Widget? buildLocalFileImage(String? path) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return Image.file(file, fit: BoxFit.contain);
}

Future<R> runNativeTfliteInference<M, R>({
  required Uint8List modelBytes,
  required TflitePreparedInput<M> Function(int inputSize) prepareInput,
  required R Function(List<int> outputShape, Float32List outputData, M meta)
      parseOutput,
}) {
  return Isolate.run(() {
    final options = InterpreterOptions()..threads = 4;
    final interpreter = Interpreter.fromBuffer(modelBytes, options: options);
    try {
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final inputShape = inputTensor.shape; // Umumnya [1, 640, 640, 3]
      final outputShape = outputTensor.shape; // Detect: [1, 7, 8400], Classify: [1, 3]

      final int inputHeight = inputShape.length >= 3 ? inputShape[1] : 640;
      final int inputWidth = inputShape.length >= 3 ? inputShape[2] : 640;
      final int inputSize = math.min(inputHeight, inputWidth);

      final prepared = prepareInput(inputSize);

      // Salin flat Float32List langsung ke memori C tensor (tanpa alokasi list 4D berat)
      inputTensor.data = prepared.tensorData.buffer.asUint8List(
        prepared.tensorData.offsetInBytes,
        prepared.tensorData.lengthInBytes,
      );

      interpreter.invoke();

      // Salin ke buffer Uint8List baru agar terjamin 4-byte aligned untuk Float32List
      final alignedOutBytes = Uint8List.fromList(outputTensor.data);
      final outputFloats = alignedOutBytes.buffer.asFloat32List();
      return parseOutput(outputShape, outputFloats, prepared.meta);
    } finally {
      interpreter.close();
    }
  });
}

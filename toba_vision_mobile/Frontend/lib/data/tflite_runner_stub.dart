import 'dart:typed_data';

import 'package:flutter/widgets.dart';

typedef TflitePreparedInput<M> = ({Float32List tensorData, M meta});

bool get isNativeTfliteSupported => false;

Future<Uint8List> readLocalFileBytes(String path) {
  throw UnsupportedError(
    'Pembacaan file lokal TFLite tidak didukung di platform Web.',
  );
}

Widget? buildLocalFileImage(String? path) => null;

Future<R> runNativeTfliteInference<M, R>({
  required Uint8List modelBytes,
  required TflitePreparedInput<M> Function(int inputSize) prepareInput,
  required R Function(List<int> outputShape, Float32List outputData, M meta)
      parseOutput,
}) {
  throw UnsupportedError(
    'Inferensi native TFLite (dart:ffi) tidak tersedia di platform Web.',
  );
}

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CurrencyDetector {
  static const _path = 'assets/models/mata_uang_mobilenet.tflite';
  final Interpreter _interpreter;
  static const _inputWidth = 256, _inputHeight = 256;
  final _classes = [
    '1.000',
    '10.000',
    '100.000',
    '2.000',
    '20.000',
    '5.000',
    '50.000',
  ];

  CurrencyDetector._create(this._interpreter);

  static Future<CurrencyDetector> load() async {
    final interpreter = await Interpreter.fromAsset(_path);
    return CurrencyDetector._create(interpreter);
  }

  Detection detect(CameraImage image) {
    final img = _convertToImage(image);
    return detectFromImage(img);
  }

  Detection detectFromImage(Image image) {
    final input = _preprocess(image).reshape([1, _inputHeight, _inputWidth, 3]);
    final output = List.filled(
      1 * _classes.length,
      0.0,
    ).reshape([1, _classes.length]);

    _interpreter.run(input, output);

    final predictions = output[0] as List<double>;
    final maxConfidence = predictions.reduce((a, b) => a > b ? a : b);
    final predictedClass = predictions.indexOf(maxConfidence);
    final confidence = maxConfidence * 100.0;

    return Detection(_classes[predictedClass], confidence);
  }

  Float32List _preprocess(Image image) {
    final resized = copyResize(image, width: _inputWidth, height: _inputHeight);
    return _mobileNetV2Preprocessing(resized);
  }

  Float32List _mobileNetV2Preprocessing(Image image) {
    final buffer = Float32List(_inputWidth * _inputHeight * 3);
    int index = 0;

    for (var y = 0; y < _inputHeight; y++) {
      for (var x = 0; x < _inputWidth; x++) {
        final pixel = image.getPixel(x, y);

        // MobileNetV2 expects RGB format with values in [-1, 1]
        // Training used base_model without custom preprocessing
        buffer[index++] = (pixel.r / 127.5) - 1.0;
        buffer[index++] = (pixel.g / 127.5) - 1.0;
        buffer[index++] = (pixel.b / 127.5) - 1.0;
      }
    }
    return buffer;
  }

  void close() {
    _interpreter.close();
  }
}

Image _convertToImage(CameraImage image) {
  final group = image.format.group;
  switch (group) {
    case ImageFormatGroup.jpeg:
      return _convertJpegToImage(image);
    case ImageFormatGroup.yuv420:
      return _convertYuv420ToImage(image);
    case ImageFormatGroup.bgra8888:
      return _convertBgra8888ToImage(image);
    default:
      throw ArgumentError("Not supported: $group");
  }
}

Image _convertJpegToImage(CameraImage image) {
  final plane = image.planes[0];
  return decodeImage(plane.bytes)!;
}

Image _convertBgra8888ToImage(CameraImage image) {
  final plane = image.planes[0];
  final width = image.width;
  final height = image.height;

  return Image.fromBytes(
    width: width,
    height: height,
    bytes: plane.bytes.buffer,
    order: ChannelOrder.rgba,
  );
}

Image _convertYuv420ToImage(CameraImage image) {
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final width = image.width;
  final height = image.height;

  final img = Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
      final uvX = x ~/ 2;
      final uvY = y ~/ 2;
      final uValue = uPlane.bytes[uvY * uPlane.bytesPerRow + uvX];
      final vValue = vPlane.bytes[uvY * vPlane.bytesPerRow + uvX];

      final rgb = _yuvToRgb(yValue, uValue, vValue);
      img.setPixelRgb(x, y, rgb[0], rgb[1], rgb[2]);
    }
  }

  return img;
}

List<int> _yuvToRgb(int y, int u, int v) {
  // Convert YUV to RGB
  final yVal = y.toDouble();
  final uVal = u.toDouble() - 128;
  final vVal = v.toDouble() - 128;

  // Conversion formulas
  final r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
  final g = (yVal - 0.344 * uVal - 0.714 * vVal).clamp(0, 255).toInt();
  final b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

  return [r, g, b];
}

class Detection {
  String nominal;
  double confidence;

  Detection(this.nominal, this.confidence);
}

import 'package:flutter/material.dart';
import 'package:mata_uang/detector.dart';

class CurrencyInformer extends StatelessWidget {
  final Detection? detection;

  const CurrencyInformer(this.detection, {super.key});

  static const _minConfidence = 80.0;

  bool _isConfident() {
    return detection != null && detection!.confidence > _minConfidence;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: detection != null,
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5, // Lower half
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xE6FFFFFF),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x33000000),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isConfident() ? detection!.nominal : '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isConfident()
                    ? '${(detection!.confidence).toStringAsFixed(1)}% Confidence'
                    : '',
                style: const TextStyle(fontSize: 24, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

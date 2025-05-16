import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mata_uang/currency_informer.dart';
import 'package:mata_uang/detector.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraFeed extends StatefulWidget {
  const CameraFeed({super.key});
  @override
  State<StatefulWidget> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  CameraController? _controller;

  CurrencyDetector? _detector;

  Detection? _detected;
  Timer? _inferenceThrottle;
  bool _isProcessing = false;
  DateTime? _lastProcessingTime;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _detector = await CurrencyDetector.load();
      await _initCamera();
      await _initController();
      _controller!.startImageStream((CameraImage image) async {
        if (_isProcessing) return;

        final now = DateTime.now();
        if (_lastProcessingTime != null &&
            now.difference(_lastProcessingTime!).inMilliseconds < 1000) {
          return;
        }

        _isProcessing = true;
        _lastProcessingTime = now;

        try {
          final result = _detector!.detect(image);
          if (mounted) {
            setState(() => _detected = result);
          }
        } finally {
          _isProcessing = false;
        }
      });
    });
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _detector?.close();
    _inferenceThrottle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: SafeArea(
        child: Positioned(
          child: Stack(
            children: [
              CameraPreview(_controller!),
              CurrencyInformer(_detected),
            ],
          ),
        ),
      ),
    );
  }

  void _requestPermissions() {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.storage,
    ];
    if (!kIsWeb) {
      permissions.map((p) async {
        final status = await p.status;
        if (!status.isGranted) await p.request();
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final availCams = await availableCameras();
      if (availCams.isNotEmpty) {
        final camera = availCams.first;
        _controller = CameraController(camera, ResolutionPreset.low);
      } else {
        showErr("No cameras are available");
      }
    } catch (e) {
      showErr("Error initializing camera: $e");
    }
  }

  Future<void> _initController() {
    return _controller!
        .initialize()
        .then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        })
        .catchError((e) {
          if (e is CameraException) {
            switch (e.code) {
              case 'CameraAccessDenied':
                showErr("Access to camera is denied");
                break;
              default:
                break;
            }
          }
        });
  }

  void showErr(String msg) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }
}

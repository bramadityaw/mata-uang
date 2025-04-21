import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mata_uang/currency_informer.dart';
import 'package:mata_uang/model.dart';
import 'package:permission_handler/permission_handler.dart';

import './util.dart';

class CameraFeed extends StatefulWidget {
  const CameraFeed({super.key});
  @override
  State<StatefulWidget> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  late List<CameraDescription> cameras;
  CameraController? controller;

  String? nominal;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initCamera();
      await _initController();
      setState(() {});
    });
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    if (controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    controller!.startImageStream(setNominal);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [CameraPreview(controller!), CurrencyInformer(nominal)],
        ),
      ),
    );
  }

  void setNominal(CameraImage img) {
    final data = img.planes.map((p) => p.bytes).toList();
    nominal = NominalRecognizer.process(data);
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
        cameras = availCams;
        // TODO: Detect whether ResolutionPreset can be set to high.
        controller = CameraController(availCams.first, ResolutionPreset.low);
      } else {
        showErr("No cameras are available");
      }
    } catch (e) {
      showErr("Error initializing camera: $e");
    }
  }

  Future<void> _initController() {
    return controller!
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

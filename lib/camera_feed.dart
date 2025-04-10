import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import './util.dart';

class CameraFeed extends StatefulWidget {
  const CameraFeed({super.key});
  @override
  State<StatefulWidget> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<CameraFeed> {
  late List<CameraDescription> cameras;
  late CameraController controller;

  File? imageFile;

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
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CameraPreview(controller),
            Align(
              alignment: Alignment.bottomCenter,
              child: _cameraControls(),
              //child: SizedBox(
              //  child: ColoredBox(
              //    color: Colors.black,
              //  ),
              //),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraControls() {
    return
    // Padding(
    // padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0 * 8),
    // child:
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        ),
        Column(
          children: [
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        ),
        Column(children: []),
      ],
    );
  }

  void _pickImage(ImageSource src) async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: src);
    if (file == null) return;
    setState(() {
      imageFile = File(file.path);
    });
    todo();
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
        controller = CameraController(availCams.first, ResolutionPreset.high);
      } else {
        showErr("No cameras are available");
      }
    } catch (e) {
      showErr("Error initializing camera: $e");
    }
  }

  Future<void> _initController() {
    return controller
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {});
          }
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

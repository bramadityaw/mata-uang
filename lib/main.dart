import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import './camera_feed.dart';

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) exit(1);
  };
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraFeed(),
      title: "Mata Uang",
    );
  }
}

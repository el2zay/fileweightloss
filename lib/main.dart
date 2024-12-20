import 'package:fileweightloss_gui/home.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:process_run/process_run.dart';
import 'package:window_size/window_size.dart';

import 'dart:io';

String ffmpegPath = "";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(810, 600));
  }
  getFFmpegPath();
  runApp(const MainApp());
}

String getFFmpegPath() {
  // var result = await Process.run('which', [
  //   'ffmpeg'
  // ]);
  // if (result.exitCode == 0) {
  //   ffmpegPath = result.stdout.trim();
  // } else {
  //   return result.stderr;
  // }
  ffmpegPath = whichSync('ffmpeg') ?? "";
  return ffmpegPath;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 3, 15, 32),
        primaryColor: Colors.white,
        hintColor: Colors.white.withAlpha(10),
        focusColor: Colors.white.withAlpha(20),
        splashFactory: NoSplash.splashFactory,
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(overlayColor: WidgetStateProperty.all(Colors.transparent)),
        ),
      ),
    );
  }
}

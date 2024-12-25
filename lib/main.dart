import 'package:fileweightloss/home.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_size/window_size.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

import 'dart:io';

String ffmpegPath = "";
bool installingFFmpeg = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMinSize(const Size(810, 600));
  }

  ffmpegPath = getFFmpegPath();
  runApp(const MainApp());
}

Future<bool> installFfmpeg() async {
  String url;
  if (Platform.isMacOS) {
    url = 'https://evermeet.cx/ffmpeg/getrelease/zip';
  } else if (Platform.isWindows) {
    url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
  } else {
    url = 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz';
  }

  // Si les url ne renvoient rien
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    final appDir = Directory.systemTemp.createTempSync('ffmpeg');
    for (final file in archive) {
      final filename = path.join(appDir.path, file.name);
      if (file.isFile) {
        final data = file.content as List<int>;
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }

    final files = appDir.listSync(recursive: true);
    for (final file in files) {
      if (file.path.endsWith('ffmpeg') || file.path.endsWith('ffmpeg.exe')) {
        final ffmpegFile = File(file.path);
        ffmpegFile.copySync(path.join(Directory.systemTemp.path, 'ffmpeg'));
        ffmpegPath = path.join(Directory.systemTemp.path, 'ffmpeg');
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', [
            '+x',
            ffmpegPath
          ]);
        }
        break;
      }
    }
    print('FFmpeg installé avec succès');
    return true;
  } else {
    print('Échec du téléchargement de FFmpeg');
    return false;
  }
}

String getFFmpegPath() {
  final ffmpegFile = File(path.join(Directory.systemTemp.path, 'ffmpeg'));
  if (ffmpegFile.existsSync()) {
    return ffmpegFile.path;
  } else {
    return '';
  }
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

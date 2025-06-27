import 'package:fileweightloss/pages/home.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'dart:io';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

var ffmpegPath = "";
String gsPath = "";
String magickPath = "";
bool installingFFmpeg = false;
bool isSettingsPage = false;
final exeDir = File(Platform.resolvedExecutable).parent;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  if (Platform.isMacOS) {
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
      ),
    );
  }
  await GetStorage.init("MyStorage");
  ensureStorageDirectoryExists();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  InitializationSettings initializationSettings = InitializationSettings(
    macOS: const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
    linux: LinuxInitializationSettings(defaultActionName: 'Open', defaultIcon: AssetsLinuxIcon("assets/app_icon.png")),
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  HttpOverrides.global = MyHttpOverrides();
  final box = GetStorage("MyStorage", getStoragePath());
  box.initStorage;
  box.writeIfNull("ffmpegPath", "");
  box.writeIfNull("gsPath", "");
  box.writeIfNull("magickPath", "");

  ffmpegPath = getFFmpegPath();
  gsPath = getGsPath();
  magickPath = getMagickPath();

  box.writeIfNull("totalFiles", 0);
  box.writeIfNull("totalSize", 0);
  box.writeIfNull("checkUpdates", true);
  box.writeIfNull("defaultOutputPath", "");
  box.writeIfNull("changeOutputName", true);
  box.writeIfNull("outputName", ".compressed");

  runApp(Phoenix(child: const MainApp()));

  await Future.delayed(Duration.zero, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<bool> installFfmpeg() async {
  if (Platform.isLinux) {
    openInBrowser("https://ffmpeg.org/download.html#build-linux");
    return false;
  }

  String url;
  if (Platform.isMacOS) {
    url = 'https://evermeet.cx/ffmpeg/getrelease/zip';
  } else {
    url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
  }

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    final String appDir;
    if (Platform.isMacOS) {
      appDir = path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'fileweightloss');
    } else {
      appDir = path.join(Platform.environment['TEMP']!, 'fileweightloss');
    }

    for (final file in archive) {
      final filename = path.join(appDir, file.name);
      if (file.isFile) {
        final data = file.content as List<int>;
        File(filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(filename).createSync(recursive: true);
      }
    }

    final files = Directory(appDir).listSync(recursive: true);
    for (final file in files) {
      if (file.path.endsWith('ffmpeg') || file.path.endsWith('ffmpeg.exe')) {
        final ffmpegFile = File(file.path);
        final String ffmpegDestination;
        if (Platform.isMacOS) {
          ffmpegDestination = path.join(appDir, 'ffmpeg');
        } else if (Platform.isWindows) {
          ffmpegDestination = path.join(appDir, 'ffmpeg.exe');
        } else {
          ffmpegDestination = path.join(Directory.systemTemp.path, 'ffmpeg');
        }
        ffmpegFile.copySync(ffmpegDestination);
        ffmpegPath = ffmpegDestination;
        if (Platform.isMacOS) {
          await Process.run('chmod', [
            '+x',
            ffmpegPath
          ]);
        }
        break;
      }
    }
    try {
      for (final file in files) {
        if (file is Directory) {
          file.deleteSync(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression du dossier.');
    }

    debugPrint('FFmpeg installé avec succès');
    return true;
  } else {
    debugPrint('Échec du téléchargement de FFmpeg');
    return false;
  }
}

String getFFmpegPath([bool? noBox]) {
  final box = GetStorage("MyStorage", getStoragePath());

  if (Platform.isWindows) {
    final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'ffmpeg.exe');
    if (File(appBinPath).existsSync()) {
      box.write('ffmpegPath', appBinPath);
      return appBinPath;
    }
  }

  if (box.read("ffmpegPath") != "" && File(box.read('ffmpegPath')).existsSync() || noBox == false) {
    return box.read('ffmpegPath');
  } else {
    box.write("ffmpegPath", "");
  }

  try {
    final result = Platform.isWindows
        ? Process.runSync("powershell", [
            "(get-command ffmpeg.exe).Path"
          ])
        : Process.runSync('which', [
            'ffmpeg'
          ]);
    if (Platform.isWindows) {
      if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
        final path = result.stdout.trim();
        box.write('ffmpegPath', path);
        return path;
      }
    } else if (result.exitCode == 0) {
      final path = result.stdout.trim();
      box.write('ffmpegPath', path);
      return path;
    }
  } catch (e) {
    debugPrint('Erreur lors de la recherche de Ffmpeg');
  }

  File ffmpegFile;

  if (Platform.isMacOS) {
    ffmpegFile = File(path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'fileweightloss', 'ffmpeg'));
  } else if (Platform.isWindows) {
    ffmpegFile = File(path.join(Platform.environment['TEMP']!, 'fileweightloss', 'ffmpeg.exe'));
  } else {
    ffmpegFile = File(path.join(Directory.systemTemp.path, 'ffmpeg'));
  }
  if (ffmpegFile.existsSync()) {
    return ffmpegFile.path;
  } else {
    return '';
  }
}

String getGsPath([bool? noBox]) {
  final box = GetStorage("MyStorage", getStoragePath());

  if (Platform.isWindows) {
    final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'gs', 'gswin64c.exe');
    if (File(appBinPath).existsSync()) {
      box.write('gsPath', appBinPath);
      return appBinPath;
    }
  }

  if (box.read("gsPath") != "" && File(box.read('gsPath')).existsSync() || noBox == false) {
    return box.read('gsPath');
  } else {
    box.write("gsPath", "");
    try {
      final result = Platform.isWindows
          ? Process.runSync("powershell", [
              "(get-command gswin64c.exe -ErrorAction SilentlyContinue).Path"
            ])
          : Process.runSync('which', [
              'gs'
            ]);

      if (Platform.isWindows) {
        if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
          final path = result.stdout.trim();
          box.write('gsPath', path);
          return path;
        }
      } else if (result.exitCode == 0) {
        final path = result.stdout.trim();
        box.write('gsPath', path);
        return path;
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche de Ghostscript');
    }
  }
  return "";
}

String getMagickPath([bool? noBox]) {
  final box = GetStorage("MyStorage", getStoragePath());

  if (Platform.isWindows) {
    final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'imagemagick', 'magick.exe');
    if (File(appBinPath).existsSync()) {
      box.write('magickPath', appBinPath);
      return appBinPath;
    }
  }

  if (box.read("magickPath") != "" && File(box.read('magickPath')).existsSync() || noBox == false) {
    return box.read('magickPath');
  } else {
    box.write("magickPath", "");
    try {
      final result = Platform.isWindows
          ? Process.runSync("powershell", [
              "(get-command magick.exe -ErrorAction SilentlyContinue).Path"
            ])
          : Process.runSync('which', [
              'magick'
            ]);

      if (Platform.isWindows) {
        if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
          final path = result.stdout.trim();
          box.write('magickPath', path);
          return path;
        }
      } else if (result.exitCode == 0) {
        final path = result.stdout.trim();
        box.write('magickPath', path);
        return path;
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche de ImageMagick');
    }
  }
  return "";
}

void ensureStorageDirectoryExists() {
  final storagePath = getStoragePath();
  if (storagePath.isNotEmpty) {
    final directory = Directory(storagePath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }
}

String getStoragePath() {
  if (Platform.isMacOS) {
    return path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'fileweightloss');
  } else if (Platform.isWindows) {
    return path.join(Platform.environment['APPDATA']!, 'fileweightloss');
  } else {
    return path.join(Platform.environment['HOME']!, '.fileweightloss');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      home: const HomePage(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
      localeResolutionCallback: (locale, supportedLocales) => getLocale(locale, supportedLocales),
      materialThemeBuilder: (context, theme) {
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, primary: Colors.white, seedColor: Colors.white),
          scaffoldBackgroundColor: Colors.black,
          cardColor: Colors.white.withAlpha(15),
          splashFactory: NoSplash.splashFactory,
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Locale getLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  final box = GetStorage("MyStorage", getStoragePath());
  if (box.read('language') != null) {
    return Locale(box.read('language'));
  }
  for (var supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode == locale?.languageCode) {
      return supportedLocale;
    }
  }
  return supportedLocales.last;
}

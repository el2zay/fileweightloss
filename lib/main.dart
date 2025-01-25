import 'package:fileweightloss/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:macos_window_utils/widgets/transparent_macos_sidebar.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'dart:io';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:macos_window_utils/macos_window_utils.dart';

String ffmpegPath = "";
bool installingFFmpeg = false;
bool isSettingsPage = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
    await WindowManipulator.initialize();
    WindowManipulator.makeTitlebarTransparent();
    WindowManipulator.enableFullSizeContentView();
    WindowManipulator.hideTitle();
  }
  await GetStorage.init();
  await hotKeyManager.unregisterAll();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initializationSettingsMacOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    macOS: initializationSettingsMacOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  HttpOverrides.global = MyHttpOverrides();
  ffmpegPath = getFFmpegPath();

  runApp(
    const TransparentMacOSSidebar(
      child: MainApp(),
    ),
  );
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

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final archive = ZipDecoder().decodeBytes(response.bodyBytes);
    final String appDir;
    if (Platform.isMacOS) {
      appDir = path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'fileweightloss');
    } else if (Platform.isWindows) {
      appDir = path.join(Platform.environment['TEMP']!, 'fileweightloss');
    } else {
      appDir = path.join(Directory.systemTemp.path, 'fileweightloss');
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
        if (Platform.isLinux || Platform.isMacOS) {
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

String getFFmpegPath() {
  final box = GetStorage();
  if (box.read("ffmpegPath") != null && File(box.read('ffmpegPath')).existsSync()) {
    return box.read('ffmpegPath');
  } else {
    box.remove('ffmpegPath');
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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.material(
      home: HomePage(),
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
  final box = GetStorage();
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

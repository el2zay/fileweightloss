import 'package:fileweightloss/pages/home.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logarte/logarte.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fileweightloss/l10n/app_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'dart:io';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:window_manager/window_manager.dart';

var ffmpegPath = "";
String gsPath = "";
String magickPath = "";
bool installingFFmpeg = false;
bool isSettingsPage = false;
final exeDir = File(Platform.resolvedExecutable).parent;

final Logarte logarte = Logarte(
  ignorePassword: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  saveLogs("Application starting - Platform: ${Platform.operatingSystem}");

  await windowManager.ensureInitialized();
  saveLogs("Window manager initialized");

  await hotKeyManager.unregisterAll();
  saveLogs("All hotkeys unregistered");

  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      titleBarStyle: Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
      size: const Size(810, 600),
      minimumSize: const Size(810, 600),
      center: true,
      windowButtonVisibility: true,
      title: "",
    ),
  );
  saveLogs("Window configured and ready to show");

  GetStorage('MyStorage', getStoragePath());

  await GetStorage.init("MyStorage");
  saveLogs("GetStorage initialized");

  ensureStorageDirectoryExists();
  saveLogs("Storage directory ensured");

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
  saveLogs("Local notifications initialized");

  HttpOverrides.global = MyHttpOverrides();
  saveLogs("HTTP overrides configured");

  final box = GetStorage("MyStorage", getStoragePath());
  box.initStorage;
  saveLogs("Storage box initialized at path: ${getStoragePath()}");

  // Initialize default values
  box.writeIfNull("ffmpegPath", "");
  box.writeIfNull("gsPath", "");
  box.writeIfNull("magickPath", "");
  box.writeIfNull("totalFiles", 0);
  box.writeIfNull("totalSize", 0);
  box.writeIfNull("checkUpdates", true);
  box.writeIfNull("defaultOutputPath", "");
  box.writeIfNull("changeOutputName", true);
  box.writeIfNull("minCompression", 10);
  box.writeIfNull("outputName", ".compressed");
  saveLogs("Default storage values initialized");

  // Initialize binary paths
  ffmpegPath = getFFmpegPath();
  gsPath = getGsPath();
  magickPath = getMagickPath();
  saveLogs("Binary paths initialized - FFmpeg: '$ffmpegPath', GS: '$gsPath', Magick: '$magickPath'");

  runApp(const MainApp());
  saveLogs("App widget started");

  await Future.delayed(Duration.zero, () async {
    await windowManager.show();
    await windowManager.focus();
    saveLogs("Window shown and focused");
  });
}

Future<bool> installFfmpeg() async {
  saveLogs("Starting FFmpeg installation for platform: ${Platform.operatingSystem}");

  if (Platform.isLinux) {
    saveLogs("Linux detected - opening browser for manual installation");
    openInBrowser("https://ffmpeg.org/download.html#build-linux");
    return false;
  }

  String url;
  if (Platform.isMacOS) {
    url = 'https://evermeet.cx/ffmpeg/getrelease/zip';
  } else {
    url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
  }
  saveLogs("Downloading FFmpeg from: $url");

  try {
    final response = await http.get(Uri.parse(url));
    saveLogs("Download response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      saveLogs("Download successful, extracting archive (${response.bodyBytes.length} bytes)");
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);

      saveLogs("Extracting to directory: ${getStoragePath()}");

      for (final file in archive) {
        final filename = path.join(getStoragePath(), file.name);
        if (file.isFile) {
          final data = file.content as List<int>;
          File(filename)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(filename).createSync(recursive: true);
        }
      }
      saveLogs("Archive extracted successfully");

      final files = Directory(getStoragePath()).listSync(recursive: true);
      saveLogs("Searching for FFmpeg executable in ${files.length} files");

      for (final file in files) {
        if (file.path.endsWith('ffmpeg') || file.path.endsWith('ffmpeg.exe')) {
          saveLogs("Found FFmpeg executable: ${file.path}");
          final ffmpegFile = File(file.path);
          final String ffmpegDestination;
          if (Platform.isWindows) {
            ffmpegDestination = path.join(getStoragePath(), 'ffmpeg.exe');
          } else {
            ffmpegDestination = path.join(getStoragePath(), 'ffmpeg');
          }

          ffmpegFile.copySync(ffmpegDestination);
          ffmpegPath = ffmpegDestination;
          saveLogs("FFmpeg copied to: $ffmpegDestination");

          if (Platform.isMacOS) {
            await Process.run('chmod', ['+x', ffmpegPath]);
            saveLogs("Execute permissions set for FFmpeg");
          }
          break;
        }
      }

      // Cleanup temporary files
      try {
        for (final file in files) {
          if (file is Directory) {
            file.deleteSync(recursive: true);
          }
        }
        saveLogs("Cleanup completed successfully");
      } catch (e) {
        saveLogs('Error during cleanup: $e');
      }

      saveLogs('FFmpeg installed successfully at: $ffmpegPath');
      return true;
    } else {
      saveLogs('FFmpeg download failed with status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    saveLogs('Error during FFmpeg installation: $e');
    return false;
  }
}

String getFFmpegPath([bool? noBox]) {
  saveLogs("Getting FFmpeg path (noBox: $noBox)");
  final box = GetStorage("MyStorage", getStoragePath());

  // if (Platform.isWindows) {
  //   final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'ffmpeg.exe');
  //   if (File(appBinPath).existsSync()) {
  //     saveLogs("Found bundled FFmpeg at: $appBinPath");
  //     box.write('ffmpegPath', appBinPath);
  //     return appBinPath;
  //   }
  // }

  if (box.read("ffmpegPath") != "" && File(box.read('ffmpegPath')).existsSync() || noBox == false) {
    final storedPath = box.read('ffmpegPath');
    saveLogs("Using stored FFmpeg path: $storedPath");
    return storedPath;
  } else {
    box.write("ffmpegPath", "");
  }

  try {
    saveLogs("Searching for FFmpeg in system PATH");
    final result =
        Platform.isWindows ? Process.runSync("powershell", ["(get-command ffmpeg.exe).Path"]) : Process.runSync('which', ['ffmpeg']);

    if (Platform.isWindows) {
      if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
        final path = result.stdout.trim();
        saveLogs("Found FFmpeg in system PATH: $path");
        box.write('ffmpegPath', path);
        return path;
      }
    } else if (result.exitCode == 0) {
      final path = result.stdout.trim();
      saveLogs("Found FFmpeg in system PATH: $path");
      box.write('ffmpegPath', path);
      return path;
    }
  } catch (e) {
    saveLogs('Error searching for FFmpeg in PATH: $e');
  }

  File ffmpegFile;

  if (Platform.isWindows) {
    ffmpegFile = File(path.join(getStoragePath(), 'ffmpeg.exe'));
  } else {
    ffmpegFile = File(path.join(getStoragePath(), 'ffmpeg'));
  }

  if (ffmpegFile.existsSync()) {
    saveLogs("Found local FFmpeg installation: ${ffmpegFile.path}");
    return ffmpegFile.path;
  } else {
    saveLogs("No FFmpeg installation found");
    return '';
  }
}

String getGsPath([bool? noBox]) {
  saveLogs("Getting Ghostscript path (noBox: $noBox)");
  final box = GetStorage("MyStorage", getStoragePath());

  // if (Platform.isWindows) {
  //   final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'gs', 'gswin64c.exe');
  //   if (File(appBinPath).existsSync()) {
  //     saveLogs("Found bundled Ghostscript at: $appBinPath");
  //     box.write('gsPath', appBinPath);
  //     return appBinPath;
  //   }
  // }

  if (box.read("gsPath") != "" && File(box.read('gsPath')).existsSync() || noBox == false) {
    final storedPath = box.read('gsPath');
    saveLogs("Using stored Ghostscript path: $storedPath");
    return storedPath;
  } else {
    box.write("gsPath", "");
    try {
      saveLogs("Searching for Ghostscript in system PATH");
      final result = Platform.isWindows
          ? Process.runSync("powershell", ["(get-command gswin64c.exe -ErrorAction SilentlyContinue).Path"])
          : Process.runSync('which', ['gs']);

      if (Platform.isWindows) {
        if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
          final path = result.stdout.trim();
          saveLogs("Found Ghostscript in system PATH: $path");
          box.write('gsPath', path);
          return path;
        }
      } else if (result.exitCode == 0) {
        final path = result.stdout.trim();
        saveLogs("Found Ghostscript in system PATH: $path");
        box.write('gsPath', path);
        return path;
      }
    } catch (e) {
      saveLogs('Error searching for Ghostscript in PATH: $e');
    }
  }

  saveLogs("No Ghostscript installation found");
  return "";
}

String getMagickPath([bool? noBox]) {
  saveLogs("Getting ImageMagick path (noBox: $noBox)");
  final box = GetStorage("MyStorage", getStoragePath());

  // if (Platform.isWindows) {
  //   final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'imagemagick', 'magick.exe');
  //   if (File(appBinPath).existsSync()) {
  //     saveLogs("Found bundled ImageMagick at: $appBinPath");
  //     box.write('magickPath', appBinPath);
  //     return appBinPath;
  //   }
  // }

  if (box.read("magickPath") != "" && File(box.read('magickPath')).existsSync() || noBox == false) {
    final storedPath = box.read('magickPath');
    saveLogs("Using stored ImageMagick path: $storedPath");
    return storedPath;
  } else {
    box.write("magickPath", "");
    try {
      saveLogs("Searching for ImageMagick in system PATH");
      final result = Platform.isWindows
          ? Process.runSync("powershell", ["(get-command magick.exe -ErrorAction SilentlyContinue).Path"])
          : Process.runSync('which', ['magick']);

      if (Platform.isWindows) {
        if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
          final path = result.stdout.trim();
          saveLogs("Found ImageMagick in system PATH: $path");
          box.write('magickPath', path);
          return path;
        }
      } else if (result.exitCode == 0) {
        final path = result.stdout.trim();
        saveLogs("Found ImageMagick in system PATH: $path");
        box.write('magickPath', path);
        return path;
      }
    } catch (e) {
      saveLogs('Error searching for ImageMagick in PATH: $e');
    }
  }

  saveLogs("No ImageMagick installation found");
  return "";
}

void ensureStorageDirectoryExists() {
  final storagePath = getStoragePath();
  saveLogs("Ensuring storage directory exists: $storagePath");

  if (storagePath.isNotEmpty) {
    final directory = Directory(storagePath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      saveLogs("Storage directory created successfully");
    } else {
      saveLogs("Storage directory already exists");
    }
  } else {
    saveLogs("Warning: Storage path is empty");
  }
}

String getStoragePath() {
  String storagePath;

  if (Platform.isMacOS) {
    storagePath = path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'fileweightloss');
  } else if (Platform.isWindows) {
    storagePath = path.join(Platform.environment['APPDATA']!, 'fileweightloss');
  } else {
    storagePath = path.join(Platform.environment['HOME']!, '.fileweightloss');
  }

  saveLogs("Storage path determined: $storagePath");
  return storagePath;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    saveLogs("Building MainApp widget");

    return ShadApp(
      home: const HomePage(),
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
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
      localeResolutionCallback: (locale, supportedLocales) {
        final resolvedLocale = getLocale(locale, supportedLocales);
        saveLogs("Locale resolved: ${resolvedLocale.languageCode} (requested: ${locale?.languageCode})");
        return resolvedLocale;
      },
      materialThemeBuilder: (context, theme) {
        saveLogs("Building material theme");
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
    saveLogs("Creating HTTP client with custom certificate callback");
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        saveLogs("Certificate validation bypassed for: $host:$port");
        return true;
      };
  }
}

Locale getLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  final box = GetStorage("MyStorage", getStoragePath());
  final storedLanguage = box.read('language');

  if (storedLanguage != null) {
    saveLogs("Using stored language preference: $storedLanguage");
    return Locale(storedLanguage);
  }

  for (var supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode == locale?.languageCode) {
      saveLogs("Matched system locale: ${supportedLocale.languageCode}");
      return supportedLocale;
    }
  }

  saveLogs("Using fallback locale: ${supportedLocales.last.languageCode}");
  return supportedLocales.last;
}

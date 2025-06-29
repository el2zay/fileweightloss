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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  logarte.log("Application starting - Platform: ${Platform.operatingSystem}");
  
  await windowManager.ensureInitialized();
  logarte.log("Window manager initialized");
  
  await hotKeyManager.unregisterAll();
  logarte.log("All hotkeys unregistered");

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
  logarte.log("Window configured and ready to show");

  await GetStorage.init("MyStorage");
  logarte.log("GetStorage initialized");
  
  ensureStorageDirectoryExists();
  logarte.log("Storage directory ensured");
  
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
  logarte.log("Local notifications initialized");

  HttpOverrides.global = MyHttpOverrides();
  logarte.log("HTTP overrides configured");
  
  final box = GetStorage("MyStorage", getStoragePath());
  box.initStorage;
  logarte.log("Storage box initialized at path: ${getStoragePath()}");
  
  // Initialize default values
  box.writeIfNull("ffmpegPath", "");
  box.writeIfNull("gsPath", "");
  box.writeIfNull("magickPath", "");
  box.writeIfNull("totalFiles", 0);
  box.writeIfNull("totalSize", 0);
  box.writeIfNull("checkUpdates", true);
  box.writeIfNull("defaultOutputPath", "");
  box.writeIfNull("changeOutputName", true);
  box.writeIfNull("outputName", ".compressed");
  logarte.log("Default storage values initialized");

  // Initialize binary paths
  ffmpegPath = getFFmpegPath();
  gsPath = getGsPath();
  magickPath = getMagickPath();
  logarte.log("Binary paths initialized - FFmpeg: '$ffmpegPath', GS: '$gsPath', Magick: '$magickPath'");

  runApp(const MainApp());
  logarte.log("App widget started");

  await Future.delayed(Duration.zero, () async {
    await windowManager.show();
    await windowManager.focus();
    logarte.log("Window shown and focused");
  });
}

Future<bool> installFfmpeg() async {
  logarte.log("Starting FFmpeg installation for platform: ${Platform.operatingSystem}");
  
  if (Platform.isLinux) {
    logarte.log("Linux detected - opening browser for manual installation");
    openInBrowser("https://ffmpeg.org/download.html#build-linux");
    return false;
  }

  String url;
  if (Platform.isMacOS) {
    url = 'https://evermeet.cx/ffmpeg/getrelease/zip';
  } else {
    url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
  }
  logarte.log("Downloading FFmpeg from: $url");

  try {
    final response = await http.get(Uri.parse(url));
    logarte.log("Download response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      logarte.log("Download successful, extracting archive (${response.bodyBytes.length} bytes)");
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      
      final String appDir;
      if (Platform.isMacOS) {
        appDir = path.join(Platform.environment['HOME']!, 'Library', 'Application Support', 'fileweightloss');
      } else {
        appDir = path.join(Platform.environment['TEMP']!, 'fileweightloss');
      }
      logarte.log("Extracting to directory: $appDir");

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
      logarte.log("Archive extracted successfully");

      final files = Directory(appDir).listSync(recursive: true);
      logarte.log("Searching for FFmpeg executable in ${files.length} files");
      
      for (final file in files) {
        if (file.path.endsWith('ffmpeg') || file.path.endsWith('ffmpeg.exe')) {
          logarte.log("Found FFmpeg executable: ${file.path}");
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
          logarte.log("FFmpeg copied to: $ffmpegDestination");
          
          if (Platform.isMacOS) {
            await Process.run('chmod', ['+x', ffmpegPath]);
            logarte.log("Execute permissions set for FFmpeg");
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
        logarte.log("Cleanup completed successfully");
      } catch (e) {
        logarte.log('Error during cleanup: $e');
      }

      logarte.log('FFmpeg installed successfully at: $ffmpegPath');
      return true;
    } else {
      logarte.log('FFmpeg download failed with status: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    logarte.log('Error during FFmpeg installation: $e');
    return false;
  }
}

String getFFmpegPath([bool? noBox]) {
  logarte.log("Getting FFmpeg path (noBox: $noBox)");
  final box = GetStorage("MyStorage", getStoragePath());

  if (Platform.isWindows) {
    final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'ffmpeg.exe');
    if (File(appBinPath).existsSync()) {
      logarte.log("Found bundled FFmpeg at: $appBinPath");
      box.write('ffmpegPath', appBinPath);
      return appBinPath;
    }
  }

  if (box.read("ffmpegPath") != "" && File(box.read('ffmpegPath')).existsSync() || noBox == false) {
    final storedPath = box.read('ffmpegPath');
    logarte.log("Using stored FFmpeg path: $storedPath");
    return storedPath;
  } else {
    box.write("ffmpegPath", "");
  }

  try {
    logarte.log("Searching for FFmpeg in system PATH");
    final result = Platform.isWindows
        ? Process.runSync("powershell", ["(get-command ffmpeg.exe).Path"])
        : Process.runSync('which', ['ffmpeg']);
        
    if (Platform.isWindows) {
      if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
        final path = result.stdout.trim();
        logarte.log("Found FFmpeg in system PATH: $path");
        box.write('ffmpegPath', path);
        return path;
      }
    } else if (result.exitCode == 0) {
      final path = result.stdout.trim();
      logarte.log("Found FFmpeg in system PATH: $path");
      box.write('ffmpegPath', path);
      return path;
    }
  } catch (e) {
    logarte.log('Error searching for FFmpeg in PATH: $e');
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
    logarte.log("Found local FFmpeg installation: ${ffmpegFile.path}");
    return ffmpegFile.path;
  } else {
    logarte.log("No FFmpeg installation found");
    return '';
  }
}

String getGsPath([bool? noBox]) {
  logarte.log("Getting Ghostscript path (noBox: $noBox)");
  final box = GetStorage("MyStorage", getStoragePath());

  if (Platform.isWindows) {
    final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'gs', 'gswin64c.exe');
    if (File(appBinPath).existsSync()) {
      logarte.log("Found bundled Ghostscript at: $appBinPath");
      box.write('gsPath', appBinPath);
      return appBinPath;
    }
  }

  if (box.read("gsPath") != "" && File(box.read('gsPath')).existsSync() || noBox == false) {
    final storedPath = box.read('gsPath');
    logarte.log("Using stored Ghostscript path: $storedPath");
    return storedPath;
  } else {
    box.write("gsPath", "");
    try {
      logarte.log("Searching for Ghostscript in system PATH");
      final result = Platform.isWindows
          ? Process.runSync("powershell", ["(get-command gswin64c.exe -ErrorAction SilentlyContinue).Path"])
          : Process.runSync('which', ['gs']);

      if (Platform.isWindows) {
        if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
          final path = result.stdout.trim();
          logarte.log("Found Ghostscript in system PATH: $path");
          box.write('gsPath', path);
          return path;
        }
      } else if (result.exitCode == 0) {
        final path = result.stdout.trim();
        logarte.log("Found Ghostscript in system PATH: $path");
        box.write('gsPath', path);
        return path;
      }
    } catch (e) {
      logarte.log('Error searching for Ghostscript in PATH: $e');
    }
  }
  
  logarte.log("No Ghostscript installation found");
  return "";
}

String getMagickPath([bool? noBox]) {
  logarte.log("Getting ImageMagick path (noBox: $noBox)");
  final box = GetStorage("MyStorage", getStoragePath());

  if (Platform.isWindows) {
    final appBinPath = path.join(exeDir.path, 'data', 'flutter_assets', 'assets', 'bin', 'windows', 'imagemagick', 'magick.exe');
    if (File(appBinPath).existsSync()) {
      logarte.log("Found bundled ImageMagick at: $appBinPath");
      box.write('magickPath', appBinPath);
      return appBinPath;
    }
  }

  if (box.read("magickPath") != "" && File(box.read('magickPath')).existsSync() || noBox == false) {
    final storedPath = box.read('magickPath');
    logarte.log("Using stored ImageMagick path: $storedPath");
    return storedPath;
  } else {
    box.write("magickPath", "");
    try {
      logarte.log("Searching for ImageMagick in system PATH");
      final result = Platform.isWindows
          ? Process.runSync("powershell", ["(get-command magick.exe -ErrorAction SilentlyContinue).Path"])
          : Process.runSync('which', ['magick']);

      if (Platform.isWindows) {
        if (result.stdout.trim().isNotEmpty && !result.stdout.contains('CommandNotFoundException')) {
          final path = result.stdout.trim();
          logarte.log("Found ImageMagick in system PATH: $path");
          box.write('magickPath', path);
          return path;
        }
      } else if (result.exitCode == 0) {
        final path = result.stdout.trim();
        logarte.log("Found ImageMagick in system PATH: $path");
        box.write('magickPath', path);
        return path;
      }
    } catch (e) {
      logarte.log('Error searching for ImageMagick in PATH: $e');
    }
  }
  
  logarte.log("No ImageMagick installation found");
  return "";
}

void ensureStorageDirectoryExists() {
  final storagePath = getStoragePath();
  logarte.log("Ensuring storage directory exists: $storagePath");
  
  if (storagePath.isNotEmpty) {
    final directory = Directory(storagePath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      logarte.log("Storage directory created successfully");
    } else {
      logarte.log("Storage directory already exists");
    }
  } else {
    logarte.log("Warning: Storage path is empty");
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
  
  logarte.log("Storage path determined: $storagePath");
  return storagePath;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    logarte.log("Building MainApp widget");
    
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
      localeResolutionCallback: (locale, supportedLocales) {
        final resolvedLocale = getLocale(locale, supportedLocales);
        logarte.log("Locale resolved: ${resolvedLocale.languageCode} (requested: ${locale?.languageCode})");
        return resolvedLocale;
      },
      materialThemeBuilder: (context, theme) {
        logarte.log("Building material theme");
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
    logarte.log("Creating HTTP client with custom certificate callback");
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) {
      logarte.log("Certificate validation bypassed for: $host:$port");
      return true;
    };
  }
}

Locale getLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  final box = GetStorage("MyStorage", getStoragePath());
  final storedLanguage = box.read('language');
  
  if (storedLanguage != null) {
    logarte.log("Using stored language preference: $storedLanguage");
    return Locale(storedLanguage);
  }
  
  for (var supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode == locale?.languageCode) {
      logarte.log("Matched system locale: ${supportedLocale.languageCode}");
      return supportedLocale;
    }
  }
  
  logarte.log("Using fallback locale: ${supportedLocales.last.languageCode}");
  return supportedLocales.last;
}
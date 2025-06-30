// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:fileweightloss/pages/settings.dart';
import 'package:fileweightloss/src/utils/formats.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:fileweightloss/src/utils/scripts.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/widgets/compress_card.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_selector/file_selector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final Map<String, String> errors = {};

class _HomePageState extends State<HomePage> with WindowListener {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Map<XFile, List> dict = {};
  int totalOriginalSize = 0;
  int totalCompressedSize = 0;
  bool dragging = false;
  List<XFile>? result = [];
  bool deleteOriginals = false;
  bool keepMetadata = true;
  String? outputDir;
  bool compressed = false;
  bool isCompressing = false;
  bool errorFfmpeg = false;
  bool canceled = false;
  Map<int, int> quality = {
    0: 1,
    1: 70,
    2: 1,
  };
  int format = -1;
  int fps = 30;
  int tabValue = 0;
  int notifId = 0;
  XFile? coverFile;
  final box = GetStorage("MyStorage", getStoragePath());
  String name = "";

  HotKey settingsHotKey = HotKey(
    key: PhysicalKeyboardKey.comma,
    modifiers: [
      Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
    ],
    scope: HotKeyScope.inapp,
  );

  final HotKey quitHotKey = HotKey(
    key: PhysicalKeyboardKey.keyQ,
    modifiers: [
      Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
    ],
    scope: HotKeyScope.inapp,
  );

  @override
  void initState() {
    super.initState();
    saveLogs("HomePage initState started");

    windowManager.addListener(this);

    if (box.read("defaultOutputPath") != "") {
      outputDir = box.read("defaultOutputPath");
      saveLogs("Default output path loaded: $outputDir");
    } else {
      outputDir = null;
      saveLogs("No default output path set");
    }

    hotKeyManager.register(
      quitHotKey,
      keyDownHandler: (hotKey) async {
        saveLogs("Quit hotkey pressed");
        await onWindowClose();
      },
    );

    hotKeyManager.register(
      settingsHotKey,
      keyDownHandler: (hotKey) {
        saveLogs("Settings hotkey pressed");
        if (!isSettingsPage) {
          showShadDialog(
            context: context,
            builder: (context) {
              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.height * 0.825,
                  child: const SettingsPage(),
                ),
              );
            },
          );
        }
      },
    );

    if (box.read("checkUpdates") == true) {
      saveLogs("Checking for updates enabled");
      _checkUpdates();
    } else {
      saveLogs("Update checking disabled");
    }

    saveLogs("HomePage initState completed");
  }

  @override
  void dispose() {
    saveLogs("HomePage disposing");
    windowManager.removeListener(this);
    progressNotifier.dispose();
    super.dispose();
  }

  void setCompressing(bool value) {
    saveLogs("Setting compression state to: $value");
    setState(() {
      isCompressing = value;
      windowManager.setPreventClose(value);
    });
  }

  Future<void> _checkUpdates() async {
    saveLogs("Starting update check");
    try {
      if (await getUpdates() != null) {
        saveLogs("New version available, showing dialog");
        showShadDialog(
          context: context,
          builder: (context) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 500,
                ),
                child: ShadDialog(
                  title: Text(AppLocalizations.of(context)!.newVersionAvailable),
                  description: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 200,
                        child: Markdown(data: box.read("latestDescription")),
                      ),
                    ],
                  ),
                  actions: [
                    ShadButton(
                      onPressed: () {
                        final downloadUrl = Platform.isWindows
                            ? "https://fwl.bassinecorp.fr/ms-store"
                            : Platform.isMacOS
                                ? "https://github.com/el2zay/fileweightloss/releases/latest/download/File.Weight.Loss.dmg"
                                : "https://github.com/el2zay/fileweightloss/releases/latest/";
                        saveLogs("Opening download URL: $downloadUrl");
                        openInBrowser(downloadUrl);
                      },
                      child: Text(AppLocalizations.of(context)!.download),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        saveLogs("No updates available");
      }
    } catch (e) {
      saveLogs("Error checking for updates: $e");
    }
  }

  @override
  Future<void> onWindowClose() async {
    saveLogs("Window close requested");
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && !compressed) {
      saveLogs("Showing quit confirmation dialog");
      showShadDialog(
          context: context,
          builder: (context) {
            return Center(
              child: ShadDialog(
                title: Text(AppLocalizations.of(context)!.confirmQuit),
                description: Text(AppLocalizations.of(context)!.quitWarning),
                actions: [
                  ShadButton.secondary(
                    onPressed: () {
                      saveLogs("Force quit confirmed");
                      windowManager.setPreventClose(false);
                      windowManager.close();
                    },
                    child: Text(AppLocalizations.of(context)!.quit),
                  ),
                  ShadButton(
                    onPressed: () {
                      saveLogs("Quit cancelled");
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ],
              ),
            );
          });
    } else {
      saveLogs("Destroying window");
      windowManager.destroy();
    }
  }

  Future getUpdates() async {
    saveLogs("Getting updates information");
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      var currentVersion = packageInfo.version;
      var latestVersion = box.read('latestVersion') ?? '';
      var latestVersionExpire = box.read('latestVersionExpire') ?? 0;
      String description = "";

      saveLogs("Current version: $currentVersion");

      if (latestVersionExpire < DateTime.now().millisecondsSinceEpoch) {
        saveLogs("Cached version info expired, clearing cache");
        box.remove('latestVersion');
        box.remove('latestVersionExpire');
        box.remove('latestDescription');
        latestVersion = '';
      } else {
        saveLogs("Using cached version info");
        return null;
      }

      if (latestVersion.isEmpty) {
        saveLogs("Fetching latest version from GitHub API");
        final response = await http.get(Uri.parse('https://api.github.com/repos/el2zay/fileweightloss/releases/latest'));
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
          latestVersion = jsonData['tag_name'];
          description = jsonData['body'];

          saveLogs("Latest version fetched: $latestVersion");

          box.write('latestVersion', latestVersion);
          box.write('latestVersionExpire', DateTime.now().add(const Duration(hours: 6)).millisecondsSinceEpoch);
          box.write('latestDescription', description);
        } else {
          saveLogs("Failed to fetch latest version, status code: ${response.statusCode}");
        }
      }

      if (latestVersion != currentVersion) {
        saveLogs("Update available: $currentVersion -> $latestVersion");
        return [
          latestVersion
        ];
      }

      saveLogs("No update needed");
      return null;
    } catch (e) {
      saveLogs("Error in getUpdates: $e");
      return null;
    }
  }

  Future<void> pickFile() async {
    saveLogs("Opening file picker");
    try {
      final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(
          label: 'custom',
          extensions: getFormats(),
        ),
      ]);

      saveLogs("Selected ${files.length} files");

      Map<String, String> newErrors = {};
      Map<XFile, List<dynamic>> newList = {};

      for (var file in files) {
        saveLogs("Processing file: ${file.name}");
        if (!getFormats().contains(file.name.split(".").last)) {
          saveLogs("Error Unsupported file format: ${file.name.split(".").last}");
          newErrors.addAll({
            file.path: AppLocalizations.of(context)!.unsupportedFileFormat
          });
          continue;
        } else {
          final fileSize = File(file.path).lengthSync();
          final xFile = XFile(file.path);
          if (dict.keys.any((existingFile) => existingFile.path == xFile.path)) {
            saveLogs("File already in list: ${file.name}");
            continue;
          }
          saveLogs("Added file: ${file.name} ($fileSize bytes)");
          newList[xFile] = [
            fileSize,
            0,
            ValueNotifier<double>(0.0),
            file.name.split(".").last == "pdf"
                ? 2
                : getFormats().sublist(getFormats().length - 10, getFormats().length).contains(file.name.split(".").last)
                    ? 1
                    : 0,
            "",
          ];
        }
      }

      setState(() {
        errors.addAll(newErrors);
        saveLogs("Total errors: ${errors.length}");
        saveLogs("Errors dict : $errors");
        dict.addAll(newList);
        if (dict.isNotEmpty && outputDir == null) {
          outputDir = path.dirname(dict.keys.first.path);
          saveLogs("Auto-set output directory: $outputDir");
        }
      });
    } catch (e) {
      saveLogs("Error in pickFile: $e");
    }
  }

  void pickCover() async {
    saveLogs("Opening cover image picker");
    try {
      result = await openFiles(
        acceptedTypeGroups: <XTypeGroup>[
          const XTypeGroup(
            label: 'images',
            extensions: [
              'jpg',
              'jpeg',
              'png',
            ],
          ),
        ],
      );

      setState(() {
        if (result == null) {
          coverFile = null;
          saveLogs("No cover image selected");
        } else {
          coverFile = result!.first;
          saveLogs("Cover image selected: ${coverFile!.name}");
        }
      });
    } catch (e) {
      saveLogs("Error in pickCover: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (ffmpegPath.isEmpty)
          ? buildDialog(context, errorFfmpeg, setState)
          : Padding(
              padding: EdgeInsets.only(top: Platform.isMacOS ? 15 : 0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: GestureDetector(
                        child: const Icon(CupertinoIcons.settings),
                        onTap: () {
                          saveLogs("Settings button tapped");
                          showShadDialog(
                            context: context,
                            builder: (context) {
                              return Center(
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.75,
                                  height: MediaQuery.of(context).size.height * 0.825,
                                  child: const SettingsPage(),
                                ),
                              );
                            },
                          );
                        },
                        onLongPress: () {
                          saveLogs("Settings button long pressed - showing debug");
                          logarte.attach(context: context, visible: true);
                        },
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: dottedContainer(
                              compressed
                                  ? done()
                                  : dict.isNotEmpty
                                      ? notEmptyList()
                                      : emptyList(),
                              false),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShadTabs<int>(
                                value: tabValue,
                                tabBarConstraints: const BoxConstraints(maxWidth: 400),
                                contentConstraints: const BoxConstraints(maxWidth: 400),
                                decoration: const ShadDecoration(
                                  color: Colors.white10,
                                ),
                                tabs: [
                                  ShadTab(
                                    value: 0,
                                    content: Column(
                                      children: [
                                        buildCard(
                                          context,
                                          0,
                                          isCompressing,
                                          outputDir,
                                          (value) => setState(() => outputDir = value),
                                          quality[0]!,
                                          (value) => setState(() => quality[0] = value),
                                          deleteOriginals,
                                          (value) => setState(() => deleteOriginals = value),
                                          format,
                                          (value) => setState(() => format = value),
                                          coverFile,
                                          pickCover,
                                          fps,
                                          (value) => setState(() => fps = value.toInt()),
                                        ),
                                      ],
                                    ),
                                    onPressed: () {
                                      saveLogs("Switched to Videos tab");
                                      setState(() => tabValue = 0);
                                    },
                                    child: Text(AppLocalizations.of(context)!.videos),
                                  ),
                                  ShadTab(
                                    value: 1,
                                    content: buildCard(
                                      context,
                                      1,
                                      isCompressing,
                                      outputDir,
                                      (value) => setState(() => outputDir = value),
                                      quality[1]!,
                                      (value) => setState(() => quality[1] = value),
                                      deleteOriginals,
                                      (value) => setState(() => deleteOriginals = value),
                                      null,
                                      null,
                                      null,
                                      null,
                                      null,
                                      null,
                                      keepMetadata,
                                      (value) => setState(() => keepMetadata = value),
                                    ),
                                    onPressed: () {
                                      saveLogs("Switched to Images tab");
                                      setState(() => tabValue = 1);
                                    },
                                    child: const Text("Images"),
                                  ),
                                  ShadTab(
                                    value: 2,
                                    onPressed: () {
                                      saveLogs("Switched to PDF tab");
                                      setState(() => tabValue = 2);
                                    },
                                    content: buildCard(
                                      context,
                                      2,
                                      isCompressing,
                                      outputDir,
                                      (value) => setState(() => outputDir = value),
                                      quality[2]!,
                                      (value) => setState(() => quality[2] = value),
                                      deleteOriginals,
                                      (value) => setState(() => deleteOriginals = value),
                                    ),
                                    child: const Text("PDF"),
                                  ),
                                ],
                              ),
                              if (getMagickPath() == "" && tabValue == 1 || getGsPath() == "" && tabValue == 2) ...[
                                const SizedBox(height: 15),
                                Text(
                                  (tabValue == 1)
                                      ? AppLocalizations.of(context)!.magickRequired
                                      : (tabValue == 2)
                                          ? AppLocalizations.of(context)!.gsRequired
                                          : "",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 15),
                              ] else
                                const SizedBox(height: 30),
                              ShadButton.outline(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                enabled: !(isCompressing || dict.isEmpty || outputDir == null || (quality[0] == -1 && format == -1)),
                                onPressed: (isCompressing || dict.isEmpty || outputDir == null || (quality[0] == -1 && format == -1))
                                    ? null
                                    : () async {
                                        saveLogs("Starting compression process");
                                        saveLogs("Files to process: ${dict.length}");
                                        saveLogs("Output directory: $outputDir");
                                        saveLogs("Quality settings: $quality");
                                        saveLogs("Format: $format");

                                        setState(() {
                                          canceled = false;
                                          setCompressing(true);
                                        });

                                        final files = List.from(dict.keys);
                                        for (var file in files) {
                                          if (!dict.containsKey(file)) {
                                            saveLogs("File no longer in dict, skipping: ${file.name}");
                                            continue;
                                          }

                                          saveLogs("Processing file: ${file.name}");

                                          String ext = "";
                                          int compressedSize = 0;
                                          final path = file.path;
                                          final fileName = file.name;
                                          final lastDotIndex = fileName.lastIndexOf('.');

                                          name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex) + "${box.read("changeOutputName") == true && quality[0] != -1 ? box.read("outputName") : ""}";
                                          final formatsList = getFormats().sublist(getFormats().length - 10, getFormats().length);

                                          ext = (lastDotIndex == -1) ? '' : fileName.substring(lastDotIndex + 1);

                                          final size = dict[file]![0];
                                          totalOriginalSize += size as int;
                                          dict[file]![1] = 1;

                                          saveLogs("File extension: $ext, Size: $size bytes");

                                          if (ext == "pdf") {
                                            saveLogs("Compressing PDF with quality: ${quality[2]}");
                                            compressedSize = await compressPdf(context, path, name, size, outputDir!, quality[2]!, onProgress: (progress) {
                                              setState(() {
                                                if (dict.containsKey(file) && dict[file] != null && dict[file]![2] != null) {
                                                  dict[file]![2].value = progress;
                                                  dict[file]?[4] = outputPathNotifier.value.toString();
                                                }
                                              });
                                            });
                                          } else if (formatsList.contains(ext)) {
                                            saveLogs("Compressing image with quality: ${quality[1]}, keepMetadata: $keepMetadata");
                                            compressedSize = await compressImage(context, path, name, size, outputDir!, quality[1]!, keepMetadata, onProgress: (progress) {
                                              setState(() {
                                                if (dict.containsKey(file) && dict[file] != null && dict[file]![2] != null) {
                                                  dict[file]![2].value = progress;
                                                  dict[file]?[4] = outputPathNotifier.value.toString();
                                                }
                                              });
                                            });
                                          } else {
                                            if (format == 0) {
                                              ext = "mp4";
                                            } else if (format == 1) {
                                              ext = "mp3";
                                            } else if (format == 2) {
                                              ext = "gif";
                                            }

                                            saveLogs("Compressing media to $ext with quality: ${quality[0]}, fps: $fps");
                                            compressedSize = await compressMedia(context, path, name, ext, size, quality[0]!, fps, deleteOriginals, outputDir!, coverFile?.path, onProgress: (progress) {
                                              setState(() {
                                                if (dict.containsKey(file) && dict[file] != null && dict[file]![2] != null) {
                                                  dict[file]![2].value = progress;
                                                  dict[file]?[4] = outputPathNotifier.value.toString();
                                                }
                                              });
                                            });
                                          }

                                          if (compressedSize == -1) {
                                            saveLogs("Compression failed for file: ${file.name}");
                                            // errors.addAll(file);
                                            continue;
                                          } else if (compressedSize == 0) {
                                            saveLogs("Compression cancelled for file: ${file.name}");
                                            dict[file]![1] = 2;
                                            continue;
                                          }

                                          saveLogs("File compressed successfully: ${file.name}, compressed size: $compressedSize bytes");
                                          totalCompressedSize += compressedSize;
                                          box.write("totalFiles", box.read("totalFiles") + 1);
                                          dict[file]?[1] = 2;
                                        }

                                        setState(() {
                                          if (!canceled) compressed = true;
                                          final totalSize = totalOriginalSize - totalCompressedSize;
                                          box.write("totalSize", box.read("totalSize") + totalSize);
                                        });

                                        saveLogs("Compression process completed. Total saved: ${totalOriginalSize - totalCompressedSize} bytes");

                                        if (!canceled && (Platform.isMacOS || Platform.isLinux)) {
                                          saveLogs("Requesting notification permissions");
                                          final result = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
                                                alert: true,
                                                sound: true,
                                                critical: true,
                                              );

                                          if (result != null && result) {
                                            saveLogs("Showing completion notification");
                                            final currentLocal = getLocale(null, [
                                              const Locale('en'),
                                              const Locale('fr')
                                            ]);
                                            await flutterLocalNotificationsPlugin.show(
                                              notifId++,
                                              errors.isEmpty ? AppLocalizations.of(context)!.filesReady : AppLocalizations.of(context)!.endError,
                                              (errors.length == dict.keys.length)
                                                  ? AppLocalizations.of(context)!.endErrorDescription0
                                                  : (errors.isNotEmpty)
                                                      ? AppLocalizations.of(context)!.endErrorDescription1
                                                      : AppLocalizations.of(context)!.doneMessage((currentLocal == const Locale("fr") && format == -1)
                                                          ? "compressés"
                                                          : (currentLocal == const Locale("fr") && format != -1)
                                                              ? "convertis"
                                                              : (currentLocal == const Locale("en") && format == -1)
                                                                  ? "compressed"
                                                                  : "converted"),
                                              const NotificationDetails(
                                                macOS: DarwinNotificationDetails(sound: 'default'),
                                              ),
                                            );
                                          } else {
                                            saveLogs("Notification permission denied");
                                          }
                                        }
                                      },
                                child: Text(AppLocalizations.of(context)!.compress, style: TextStyle(fontSize: 15, color: isCompressing || dict.isEmpty || outputDir == null || (quality[0] == -1 && format == -1) ? Colors.white60 : Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  Widget dottedContainer(
    child,
    bool gestureDetector,
  ) {
    return GestureDetector(
      onTap: () {
        if (dict.isEmpty || gestureDetector) {
          saveLogs("Dotted container tapped, opening file picker");
          pickFile();
        }
      },
      child: DropTarget(
        onDragDone: (detail) async {
          saveLogs("Files dropped: ${detail.files.length}");
          for (var file in detail.files) {
            saveLogs("Processing dropped file: ${file.name}");
            if (!getFormats().contains(file.name.split(".").last)) {
              saveLogs("Unsupported dropped file format: ${file.name.split(".").last}");
              errors.addAll({
                file.path: AppLocalizations.of(context)!.unsupportedFileFormat
              });
              continue;
            } else {
              final fileSize = File(file.path).lengthSync();
              final xFile = XFile(file.path);
              final ext = file.name.split(".").last;

              if (dict.keys.any((existingFile) => existingFile.path == xFile.path)) {
                saveLogs("Dropped file already in list: ${file.name}");
                continue;
              }

              saveLogs("Added dropped file: ${file.name} ($fileSize bytes)");
              dict[XFile(file.path)] = [
                fileSize,
                0,
                ValueNotifier<double>(0.0),
                ext == "pdf"
                    ? 2
                    : getFormats().sublist(getFormats().length - 10, getFormats().length).contains(ext)
                        ? 1
                        : 0,
                "",
              ];
            }
          }
          setState(() {
            if (dict.isNotEmpty && outputDir == null) {
              outputDir = path.dirname(dict.keys.first.path);
              saveLogs("Auto-set output directory from dropped files: $outputDir");
            }
          });
        },
        onDragEntered: (detail) {
          saveLogs("Drag entered");
          setState(() {
            dragging = true;
          });
        },
        onDragExited: (detail) {
          saveLogs("Drag exited");
          setState(() {
            dragging = false;
          });
        },
        child: DottedBorder(
          customPath: (size) {
            if (gestureDetector) {
              return Path()
                // Uniquement en haut
                ..moveTo(0, 0)
                ..lineTo(size.width, 0);
            } else {
              return Path()
                ..addRRect(
                  RRect.fromRectAndRadius(
                    Rect.fromLTWH(0, 0, size.width, size.height),
                    const Radius.circular(10),
                  ),
                );
            }
          },
          borderType: BorderType.RRect,
          strokeWidth: 2,
          color: const Color(0xFFCED4DA),
          radius: const Radius.circular(8),
          dashPattern: const [
            8,
            2
          ],
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: dragging ? Colors.white.withAlpha(20) : Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget emptyList() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Transform.rotate(
        //   angle: mousePosition.dx / 100,
        //   child: const Icon(CupertinoIcons.up_arrow),
        // ),
        const Icon(
          CupertinoIcons.arrow_up,
          size: 50,
        ),
        const SizedBox(height: 15),
        Text(
          dragging ? AppLocalizations.of(context)!.dropNow : AppLocalizations.of(context)!.dropFiles,
          style: const TextStyle(
            color: Color(0xFFCED4DA),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Visibility(
          visible: !dragging,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text(
            AppLocalizations.of(context)!.clickAdd,
            style: const TextStyle(
              color: Color(0xFFCED4DA),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget notEmptyList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: dict.length,
            itemBuilder: (context, index) {
              final file = dict.keys.elementAt(index);
              final fileData = dict.values.elementAt(index);
              final fileName = file.name;
              final fileSize = ((fileData[0] as int) / 1000000).round();
              final compressionState = fileData[1];
              return ListTile(
                leading: const SizedBox(),
                minLeadingWidth: 5,
                key: ValueKey(file),
                title: Text(fileName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (compressionState == 0 && isCompressing)
                          ? "${AppLocalizations.of(context)!.waiting} — $fileSize Mo"
                          : compressionState == 1
                              ? "${AppLocalizations.of(context)!.compressing} — $fileSize Mo "
                              : compressionState == 2
                                  ? errors.containsKey(file.path)
                                      ? AppLocalizations.of(context)!.error
                                      : AppLocalizations.of(context)!.completed
                                  : "${AppLocalizations.of(context)!.size} : $fileSize Mo",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    if (compressionState == 0)
                      const ShadProgress(
                        minHeight: 5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        value: 0,
                      )
                    else if (compressionState == 1)
                      ValueListenableBuilder<double>(
                        valueListenable: fileData[2] as ValueNotifier<double>,
                        builder: (context, progress, child) {
                          return ShadProgress(
                            minHeight: 5,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            value: progress,
                          );
                        },
                      )
                    else if (compressionState == 2)
                      const ShadProgress(
                        minHeight: 5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        value: 1,
                      )
                    else
                      const SizedBox(),
                    const SizedBox(height: 10)
                  ],
                ),
                trailing: (compressionState != 2)
                    ? IconButton(
                        hoverColor: Colors.transparent,
                        icon: const Icon(
                          CupertinoIcons.clear_thick,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          if (compressionState == 0) {
                            saveLogs("Removing file from queue: ${file.name}");
                            dict.remove(file);
                            setState(() {});
                          } else if (compressionState == 1) {
                            saveLogs("Cancelling compression for file: ${file.name}");
                            cancelCompression(
                                dict[file]![3] == 0
                                    ? ffmpegPath
                                    : dict[file]![3] == 1
                                        ? magickPath
                                        : gsPath,
                                dict[file]![4]);
                            if (dict.length == 1) {
                              saveLogs("Last file cancelled, stopping compression");
                              setState(() {
                                canceled = true;
                                dict.clear();
                                setCompressing(false);
                              });
                            } else {
                              dict[file]![1] = 2;
                              setState(() {});
                            }
                          }
                        },
                      )
                    : null,
              );
            },
          ),
        ),
        if (!isCompressing)
          Padding(
            padding: const EdgeInsets.all(0),
            child: SizedBox(
              height: 100,
              child: dottedContainer(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.dropFiles, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context)!.clickAdd, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                true,
              ),
            ),
          ),
      ],
    );
  }

  Widget done() {
    final totalSize = totalOriginalSize - totalCompressedSize;
    final inPercent = (totalSize / totalOriginalSize) * 100;

    saveLogs("Compression completed - Total original: $totalOriginalSize, Total compressed: $totalCompressedSize, Saved: $totalSize bytes (${inPercent.toStringAsFixed(2)}%)");

    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (errors.isEmpty) const Icon(CupertinoIcons.check_mark_circled_solid, size: 60, color: CupertinoColors.systemGreen) else Icon(errors.length == dict.keys.length ? CupertinoIcons.xmark_circle : CupertinoIcons.exclamationmark_circle, size: 60, color: CupertinoColors.systemRed),
              Text(
                errors.isEmpty ? AppLocalizations.of(context)!.filesReady : AppLocalizations.of(context)!.endError,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                errors.isNotEmpty && dict.length == 1
                    ? errors.values.first
                    : errors.length == dict.keys.length
                        ? AppLocalizations.of(context)!.endErrorDescription0
                        : errors.isNotEmpty && errors.length != dict.keys.length
                            ? AppLocalizations.of(context)!.endErrorDescription1
                            : (quality[0] == -1 || inPercent.round() < 0)
                                ? AppLocalizations.of(context)!.convertedMessage(
                                    format == 0
                                        ? "MP4"
                                        : format == 1
                                            ? "MP3"
                                            : format == 2
                                                ? "GIF"
                                                : "",
                                  )
                                : AppLocalizations.of(context)!.compressedMessage(inPercent.round()),
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () {
                    saveLogs("Starting new compression session");
                    ffmpegPath = getFFmpegPath();
                    setState(() {
                      compressed = false;
                      setCompressing(false);
                      dict.clear();
                      errors.clear();
                    });
                  },
                  style: TextButton.styleFrom(overlayColor: Colors.transparent),
                  child: Text(AppLocalizations.of(context)!.clickNew, style: TextStyle(color: Colors.blue[800], fontSize: 16))),
            ],
          ),
        ),
        if (errors.length > 1 || errors.length == dict.keys.length)
          ShadButton.outline(
              onPressed: () => showShadDialog(
                  context: context,
                  builder: (context) {
                    return ShadDialog(
                      title: Text("${AppLocalizations.of(context)!.error}s"),
                      description: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ...errors.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: SelectableText("• ${entry.key}: ${entry.value}"),
                          );
                        }),
                        TextButton(
                          style: TextButton.styleFrom(overlayColor: Colors.transparent),
                          child: Text(AppLocalizations.of(context)!.reportError, style: TextStyle(color: Colors.blue[800], fontSize: 14)),
                          onPressed: () async {
                            final logsFile = await saveLogs("Opening email client for error report");

                            final logsContent = File(logsFile).readAsStringSync();
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: 'el2zay.contact@gmail.com',
                              query: '''subject=Erreur.s dans l'application&body=
====================== Erreurs renvoyées ==========================
${Uri.encodeComponent(errors.entries.map((e) => "${e.key}: ${e.value}").join("\n"))}
====================== Paramètres choisis ==========================
Vidéos : Qualité ${quality[0]} - Format ${format == 0 ? "MP4" : format == 1 ? "MP3" : format == 2 ? "GIF" : "Aucun"} - FPS $fps - Supprimer les originaux ${deleteOriginals ? "Oui" : "Non"} 
Images : Qualité ${quality[1]} - Supprimer les originaux ${deleteOriginals ? "Oui" : "Non"} - Garder les métadonnées ${keepMetadata ? "Oui" : "Non"}
PDF : Qualité ${quality[2]} - Supprimer les originaux ${deleteOriginals ? "Oui" : "Non"}
Langue : ${box.read("language")}
====================== Logs ======================
$logsContent
''',
                            );
                            openInBrowser(emailLaunchUri.toString());
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(AppLocalizations.of(context)!.helpUsWithAttachments, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                      scrollable: true,
                    );
                  }),
              child: Text(AppLocalizations.of(context)!.seeErrors))
        else
          ShadButton.outline(
            onPressed: () {
              saveLogs("Opening output files in explorer");
              for (var i = 0; i < dict.length; i++) {
                final file = dict.keys.elementAt(i);
                if (errors.containsKey(file.path)) {
                  continue;
                }
                openInExplorer(dict[file]![4]);
              }
            },
            child: Text(Platform.isMacOS ? AppLocalizations.of(context)!.openFinder : AppLocalizations.of(context)!.openExplorer),
          ),
        const SizedBox(height: 50),
      ],
    );
  }

  @override
  void onWindowFocus() {
    saveLogs("Window gained focus");
    setState(() {});
  }
}

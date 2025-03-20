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

class _HomePageState extends State<HomePage> with WindowListener {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Map<XFile, List> dict = {};
  final List<XFile> errors = [];
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
  final box = GetStorage();
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
    windowManager.addListener(this);
    if (box.read("defaultOutputPath") != "") {
      outputDir = box.read("defaultOutputPath");
    } else {
      outputDir = null;
    }

    hotKeyManager.register(
      quitHotKey,
      keyDownHandler: (hotKey) async {
        await onWindowClose();
      },
    );

    hotKeyManager.register(
      settingsHotKey,
      keyDownHandler: (hotKey) {
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

    if (box.read("checkUpdates") == true) _checkUpdates();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    progressNotifier.dispose();
    super.dispose();
  }

// Pour que ce soit a jour dans le initstate
  void setCompressing(bool value) {
    setState(() {
      isCompressing = value;
      windowManager.setPreventClose(value); // Met à jour preventClose en fonction de isCompressing
    });
  }

  Future<void> _checkUpdates() async {
    if (await getUpdates() != null) {
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
                title: Text(AppLocalizations.of(context)!.nouvelleVersion),
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
                      openInBrowser(
                        Platform.isWindows
                            ? "https://github.com/el2zay/fileweightloss/releases/latest/download/File.Weight.Loss.exe" // TODO Lien microsoft store
                            : Platform.isMacOS
                                ? "https://github.com/el2zay/fileweightloss/releases/latest/download/File.Weight.Loss.dmg"
                                : "https://github.com/el2zay/fileweightloss/releases/latest/",
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.telecharger),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Future<void> onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && isCompressing) {
      showShadDialog(
          context: context,
          builder: (context) {
            return Center(
              child: ShadDialog(
                title: Text(AppLocalizations.of(context)!.quitterDemande),
                description: Text(AppLocalizations.of(context)!.quitterDescription),
                actions: [
                  ShadButton.secondary(
                    onPressed: () {
                      windowManager.setPreventClose(false);
                      windowManager.close();
                    },
                    child: Text(AppLocalizations.of(context)!.quitter),
                  ),
                  ShadButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(AppLocalizations.of(context)!.annuler),
                  ),
                ],
              ),
            );
          });
    } else {
      windowManager.destroy();
    }
  }

  Future getUpdates() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var currentVersion = packageInfo.version;
    var latestVersion = box.read('latestVersion') ?? '';
    var latestVersionExpire = box.read('latestVersionExpire') ?? 0;
    String description = "";

    if (latestVersionExpire < DateTime.now().millisecondsSinceEpoch) {
      box.remove('latestVersion');
      box.remove('latestVersionExpire');
      box.remove('latestDescription');
      latestVersion = '';
    } else {
      return null;
    }

    if (latestVersion.isEmpty) {
      final response = await http.get(Uri.parse('https://api.github.com/repos/el2zay/fileweightloss/releases/latest'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
        latestVersion = jsonData['tag_name'];
        description = jsonData['body'];

        box.write('latestVersion', latestVersion);
        box.write('latestVersionExpire', DateTime.now().add(const Duration(hours: 6)).millisecondsSinceEpoch);
        box.write('latestDescription', description);
      }
    }

    if (latestVersion != currentVersion) {
      return [
        latestVersion,
      ];
    }
    return null;
  }

  Future<void> pickFile() async {
    final List<XFile> files = await openFiles(acceptedTypeGroups: <XTypeGroup>[
      XTypeGroup(
        label: 'custom',
        extensions: getFormats(),
      ),
    ]);

    List<XFile> newErrors = [];
    Map<XFile, List<dynamic>> newList = {};

    for (var file in files) {
      if (!getFormats().contains(file.name.split(".").last)) {
        newErrors.add(file);
        continue;
      } else {
        final fileSize = File(file.path).lengthSync();
        final xFile = XFile(file.path);
        if (dict.keys.any((existingFile) => existingFile.path == xFile.path)) {
          continue;
        }
        newList[xFile] = [
          fileSize,
          0,
          ValueNotifier<double>(0.0)
        ];
      }
    }

    setState(() {
      errors.addAll(newErrors);
      dict.addAll(newList);
      if (dict.isNotEmpty && outputDir == null) {
        outputDir = path.dirname(dict.keys.first.path);
      }
    });
  }

  void pickCover() async {
    // Pick une image pour la couverture
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
      } else {
        coverFile = result!.first;
      }
    });
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
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.settings),
                        onPressed: () {
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
                                    onPressed: () => setState(() => tabValue = 0),
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
                                    onPressed: () => setState(() => tabValue = 1),
                                    child: const Text("Images"),
                                  ),
                                  ShadTab(
                                    value: 2,
                                    onPressed: () => setState(() => tabValue = 2),
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
                                      ? AppLocalizations.of(context)!.preventMagick
                                      : (tabValue == 2)
                                          ? AppLocalizations.of(context)!.preventGs
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
                                        setState(() {
                                          setCompressing(true);
                                        });
                                        final files = List.from(dict.keys);
                                        for (var file in files) {
                                          if (!dict.containsKey(file)) {
                                            continue;
                                          }
                                          String ext = "";
                                          int compressedSize = 0;
                                          final path = file.path;
                                          final fileName = file.name;
                                          final lastDotIndex = fileName.lastIndexOf('.');

                                          name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex) + "${box.read("changeOutputName") == true && quality[0] != -1 ? box.read("outputName") : ""}";
                                          final formatsList = getFormats().sublist(getFormats().length - 10, getFormats().length);

                                          if (format == 0) {
                                            ext = "mp4";
                                          } else if (format == 1) {
                                            ext = "mp3";
                                          } else if (format == 2) {
                                            ext = "gif";
                                          } else {
                                            ext = (lastDotIndex == -1) ? '' : fileName.substring(lastDotIndex + 1);
                                          }

                                          final size = dict[file]![0];
                                          totalOriginalSize += size as int;
                                          dict[file]![1] = 1;
                                          if (ext == "pdf") {
                                            compressedSize = await compressPdf(path, name, size, outputDir!, quality[2]!, onProgress: (progress) {
                                              setState(() {
                                                dict[file]![2].value = progress;
                                              });
                                            });
                                          } else if (formatsList.contains(ext)) {
                                            compressedSize = await compressImage(path, name, size, outputDir!, quality[1]!, keepMetadata, onProgress: (progress) {
                                              setState(() {
                                                dict[file]![2].value = progress;
                                              });
                                            });
                                          } else {
                                            compressedSize = await compressMedia(path, name, ext, size, quality[0]!, fps, deleteOriginals, outputDir!, coverFile?.path, onProgress: (progress) {
                                              setState(() {
                                                dict[file]![2].value = progress;
                                              });
                                            });
                                          }
                                          if (compressedSize == -1) {
                                            errors.add(file);
                                            continue;
                                          }
                                          totalCompressedSize += compressedSize;
                                          box.write("totalFiles", box.read("totalFiles") + 1);
                                          dict[file]?[1] = 2;
                                        }
                                        setState(() {
                                          if (!canceled) compressed = true;
                                          final totalSize = totalOriginalSize - totalCompressedSize;
                                          box.write("totalSize", box.read("totalSize") + totalSize);
                                        });
                                        if (Platform.isMacOS || Platform.isLinux) {
                                          final result = await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
                                                alert: true,
                                                sound: true,
                                                critical: true,
                                              );

                                          if (result != null && result) {
                                            final currentLocal = getLocale(null, [
                                              const Locale('en'),
                                              const Locale('fr')
                                            ]);
                                            await flutterLocalNotificationsPlugin.show(
                                              notifId++,
                                              errors.isEmpty ? AppLocalizations.of(context)!.prets : AppLocalizations.of(context)!.erreurFin,
                                              (errors.length == dict.keys.length)
                                                  ? AppLocalizations.of(context)!.erreurFinDescription0
                                                  : (errors.isNotEmpty)
                                                      ? AppLocalizations.of(context)!.erreurFinDescription1
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
                                          }
                                        }
                                      },
                                child: Text(AppLocalizations.of(context)!.compresser, style: TextStyle(fontSize: 15, color: isCompressing || dict.isEmpty || outputDir == null || (quality[0] == -1 && format == -1) ? Colors.white60 : Colors.white)),
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
        if (dict.isEmpty || gestureDetector) pickFile();
      },
      child: DropTarget(
        onDragDone: (detail) async {
          for (var file in detail.files) {
            if (!getFormats().contains(file.name.split(".").last)) {
              errors.add(XFile(file.path));
              continue;
            } else {
              final fileSize = File(file.path).lengthSync();
              final xFile = XFile(file.path);
              final ext = file.name.split(".").last;

              if (dict.keys.any((existingFile) => existingFile.path == xFile.path)) {
                continue;
              }
              // Récupérer l'extension du fichier
              dict[XFile(file.path)] = [
                fileSize,
                0,
                ValueNotifier<double>(0.0),
                ext == "pdf"
                    ? 2
                    : getFormats().sublist(getFormats().length - 10, getFormats().length).contains(ext)
                        ? 1
                        : 0
              ];
            }
          }
          setState(() {
            if (dict.isNotEmpty && outputDir == null) {
              outputDir = path.dirname(dict.keys.first.path);
            }
          });
        },
        onDragEntered: (detail) {
          setState(() {
            dragging = true;
          });
        },
        onDragExited: (detail) {
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
          dragging ? AppLocalizations.of(context)!.lacher : AppLocalizations.of(context)!.deposez,
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
            AppLocalizations.of(context)!.ajouter,
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
    final fileExt = format == 0
        ? "mp4"
        : format == 1
            ? "mp3"
            : format == 2
                ? "gif"
                : name.split('.').last;
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
                          ? "${AppLocalizations.of(context)!.attente} — $fileSize Mo"
                          : compressionState == 1
                              ? "${AppLocalizations.of(context)!.compression} — $fileSize Mo "
                              : compressionState == 2
                                  ? errors.contains(file)
                                      ? AppLocalizations.of(context)!.erreur
                                      : AppLocalizations.of(context)!.termine
                                  : "${AppLocalizations.of(context)!.taille} : $fileSize Mo",
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
                            dict.remove(file);
                            setState(() {});
                          } else if (compressionState == 1) {
                            cancelCompression(
                                dict[file]![3] == 0
                                    ? ffmpegPath
                                    : dict[file]![3] == 1
                                        ? magickPath
                                        : gsPath,
                                "$outputDir/$name.$fileExt");
                            if (dict.length == 1) {
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
                    Text(AppLocalizations.of(context)!.deposez, style: const TextStyle(fontSize: 18)),
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
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (errors.isEmpty) const Icon(CupertinoIcons.check_mark_circled_solid, size: 60, color: CupertinoColors.systemGreen) else Icon(errors.length == dict.keys.length ? CupertinoIcons.xmark_circle : CupertinoIcons.exclamationmark_circle, size: 60, color: CupertinoColors.systemRed),
              Text(
                errors.isEmpty ? AppLocalizations.of(context)!.prets : AppLocalizations.of(context)!.erreurFin,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                errors.length == dict.keys.length
                    ? AppLocalizations.of(context)!.erreurFinDescription0
                    : errors.isNotEmpty
                        ? AppLocalizations.of(context)!.erreurFinDescription1
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
              ),
              const SizedBox(height: 5),
              TextButton(
                  onPressed: () {
                    ffmpegPath = getFFmpegPath();
                    setState(() {
                      compressed = false;
                      setCompressing(false);
                      dict.clear();
                      errors.clear();
                    });
                  },
                  style: TextButton.styleFrom(overlayColor: Colors.transparent),
                  child: Text(AppLocalizations.of(context)!.clickNew, style: TextStyle(color: Colors.blue[800]))),
            ],
          ),
        ),
        if (errors.length != dict.length)
          ShadButton.outline(
            onPressed: () {
              for (var i = 0; i < dict.length; i++) {
                final file = dict.keys.elementAt(i);
                if (errors.contains(file)) {
                  continue;
                }
                final fileName = file.name;
                final fileExt = format == 0
                    ? "mp4"
                    : format == 1
                        ? "mp3"
                        : format == 2
                            ? "gif"
                            : fileName.split('.').last;
                final lastDotIndex = fileName.lastIndexOf('.');
                final name = (lastDotIndex == -1) ? fileName : "${fileName.substring(0, lastDotIndex)}${box.read("changeOutputName") == true && quality[0] != -1 ? box.read("outputName") : ""}";
                openInExplorer("$outputDir/$name.$fileExt");
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
    setState(() {});
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/pages/settings.dart';
import 'package:fileweightloss/src/utils/script.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:fileweightloss/src/widgets/dropdown.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Map<XFile, List> dict = {};
  final List<XFile> errors = [];
  int totalOriginalSize = 0;
  int totalCompressedSize = 0;
  bool dragging = false;
  FilePickerResult? result;
  bool deleteOriginals = false;
  String? outputDir;
  bool compressed = false;
  bool isCompressing = false;
  bool errorFfmpeg = false;
  bool canceled = false;
  int quality = 1;
  int format = -1;
  int fps = 30;
  int notifId = 0;
  XFile? coverFile;
  final box = GetStorage();

  static const formats = [
    "aa",
    "aac",
    "aax",
    "ac3",
    "ac4",
    "act",
    "adp",
    "adx",
    "aea",
    "afc",
    "aiff",
    "alaw",
    "amr",
    "amrnb",
    "amrwb",
    "ape",
    "aptx",
    "aptx_hd",
    "caf",
    "codec2",
    "codec2raw",
    "daud",
    "dfpwm",
    "dss",
    "dts",
    "dtshd",
    "eac3",
    "flac",
    "g722",
    "g723_1",
    "g726",
    "g726le",
    "gsm",
    "iacm",
    "lc3",
    "mlp",
    "mmf",
    "mp2",
    "mp3",
    "mulaw",
    "oga",
    "ogg",
    "opus",
    "pcm_s16be",
    "pcm_s16le",
    "pcm_s24be",
    "pcm_s24le",
    "pcm_s32be",
    "pcm_s32le",
    "pcm_u16be",
    "pcm_u16le",
    "pcm_u24be",
    "pcm_u24le",
    "pcm_u32be",
    "pcm_u32le",
    "qcp",
    "ral",
    "rm",
    "snd",
    "sox",
    "spdif",
    "srt",
    "sup",
    "tta",
    "voc",
    "wav",
    "w64",
    "wv",
    "3g2",
    "3gp",
    "4xm",
    "amv",
    "asf",
    "avi",
    "avs",
    "avs2",
    "avs3",
    "bethsoftvid",
    "bfi",
    "bink",
    "c93",
    "cdxl",
    "cine",
    "daala",
    "dav",
    "dcstr",
    "dfa",
    "dhav",
    "dirac",
    "dnxhd",
    "dpx",
    "dxa",
    "dv",
    "eacmv",
    "flv",
    "h261",
    "h263",
    "h264",
    "h265",
    "hevc",
    "idcin",
    "ipmovie",
    "jpegxl",
    "jpegls",
    "lxf",
    "matroska",
    "mjpeg",
    "mov",
    "mp4",
    "mpeg",
    "mpegts",
    "mxf",
    "nut",
    "obu",
    "ogv",
    "rmvb",
    "roq",
    "rv",
    "smk",
    "swf",
    "thp",
    "v210",
    "vc1",
    "vc1test",
    "vcd",
    "vivo",
    "vmd",
    "vob",
    "vp8",
    "vp9",
    "mp3",
    "wvm"
  ];

  HotKey hotKey = HotKey(
    key: PhysicalKeyboardKey.comma,
    modifiers: [
      Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
    ],
    scope: HotKeyScope.inapp,
  );

  @override
  void initState() {
    super.initState();
    if (box.read("defaultOutputPath") != "") {
      outputDir = box.read("defaultOutputPath");
    } else {
      outputDir = null;
    }

    hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) {
        if (!isSettingsPage) {
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const SettingsPage()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    progressNotifier.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    result = await FilePicker.platform.pickFiles(
      allowCompression: false,
      allowMultiple: true,
      allowedExtensions: formats,
      type: FileType.custom,
    );
    if (result == null) return;

    List<XFile> newErrors = [];
    Map<XFile, List<dynamic>> newList = {};

    for (var file in result!.files) {
      if (!formats.contains(file.name.split(".").last)) {
        newErrors.add(XFile(file.path ?? ""));
        continue;
      } else {
        final xFile = XFile(file.path ?? "");
        if (dict.keys.any((existingFile) => existingFile.path == xFile.path)) {
          continue;
        }
        newList[xFile] = [
          file.size,
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
    result = await FilePicker.platform.pickFiles(
      allowCompression: false,
      allowMultiple: false,
      type: FileType.image,
    );

    setState(() {
      if (result == null) {
        coverFile = null;
      } else {
        coverFile = XFile(result!.files.first.path ?? "");
      }
    });
  }

  void openInExplorer(String path) async {
    if (Platform.isWindows) {
      String escapedPath = path.replaceAll('/', '\\');
      await Process.run("explorer", [
        "/select,",
        escapedPath
      ]);
    } else if (Platform.isMacOS) {
      await Process.run("open", [
        "-R",
        path
      ]);
    } else if (Platform.isLinux) {
      await Process.run("xdg-open", [
        path
      ]);
    }
  }

  Widget _showFfmpegDialog() {
    if (Platform.isMacOS) {
      return buildMacosDialog(context, errorFfmpeg, setState);
    } else if (Platform.isWindows) {
      return buildWindowsDialog(context, errorFfmpeg, setState);
    } else {
      return buildDefaultDialog(context, errorFfmpeg, setState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (ffmpegPath.isEmpty)
          ? _showFfmpegDialog()
          : Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => const SettingsPage()),
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
                          children: [
                            Card(
                              color: Theme.of(context).cardColor,
                              margin: const EdgeInsets.all(5),
                              child: Column(
                                children: [
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      AppLocalizations.of(context)!.sortie,
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: TextAlign.left,
                                    ),
                                    trailing: TextButton(
                                      onPressed: isCompressing
                                          ? null
                                          : () async {
                                              outputDir = (await FilePicker.platform.getDirectoryPath())!;
                                              setState(() {
                                                outputDir = outputDir;
                                              });
                                            },
                                      style: ButtonStyle(overlayColor: WidgetStateProperty.all(Colors.transparent)),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.2),
                                        child: Text(
                                          (path.basename(outputDir ?? AppLocalizations.of(context)!.parcourir)),
                                          style: TextStyle(fontSize: 14, color: isCompressing ? Colors.white38 : Colors.blue[800]),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 8, right: 4),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      AppLocalizations.of(context)!.qualite,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    trailing: buildDropdownButton(
                                        context,
                                        isCompressing,
                                        {
                                          "Original": -1,
                                          AppLocalizations.of(context)!.haute: 0,
                                          AppLocalizations.of(context)!.bonne: 1,
                                          AppLocalizations.of(context)!.moyenne: 2,
                                          AppLocalizations.of(context)!.faible: 3,
                                        },
                                        quality, (value) {
                                      setState(() {
                                        quality = value;
                                      });
                                    }),
                                    contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 8, right: isCompressing ? 14 : 4),
                                  ),
                                  const Divider(),
                                  ListTile(
                                    dense: true,
                                    title: const Text(
                                      "Format",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    trailing: buildDropdownButton(
                                        context,
                                        isCompressing,
                                        {
                                          "Original": -1,
                                          "MP4": 0,
                                          "MP3": 1,
                                          "GIF": 2,
                                        },
                                        format, (value) {
                                      setState(() {
                                        format = value;
                                      });
                                    }),
                                    contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 8, right: isCompressing ? 14 : 4),
                                  ),
                                  if (format == 1) ...[
                                    const Divider(),
                                    ListTile(
                                      dense: true,
                                      title: const Text(
                                        "Cover",
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      trailing: SizedBox(
                                        width: coverFile != null ? MediaQuery.of(context).size.width * 0.2 : null,
                                        child: TextButton(
                                          onPressed: pickCover,
                                          child: Text(
                                            coverFile == null ? AppLocalizations.of(context)!.parcourir : coverFile!.name,
                                            style: TextStyle(fontSize: 14, color: isCompressing ? Colors.white38 : Colors.blue[800]),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.only(left: 8),
                                    ),
                                  ],
                                  if (format == 2) ...[
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 4),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "FPS $fps",
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          SliderTheme(
                                            data: SliderTheme.of(context).copyWith(disabledActiveTrackColor: Colors.white10, disabledInactiveTrackColor: Colors.white10, thumbColor: Colors.white, overlayColor: WidgetStateColor.resolveWith((states) => Colors.transparent), activeTrackColor: !isCompressing ? Theme.of(context).indicatorColor : Colors.black),
                                            child: Slider(
                                              min: 10,
                                              max: 30,
                                              divisions: 20,
                                              value: fps.toDouble(),
                                              onChanged: !isCompressing
                                                  ? (value) {
                                                      setState(() {
                                                        fps = value.toInt();
                                                      });
                                                    }
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Divider(),
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      AppLocalizations.of(context)!.supprimer,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    trailing: Transform.scale(
                                      scale: Platform.isMacOS ? 0.70 : 0.75,
                                      child: Switch.adaptive(
                                        value: deleteOriginals,
                                        activeColor: isCompressing ? Colors.white38 : Colors.blue[800],
                                        onChanged: (value) {
                                          if (isCompressing) return;
                                          setState(() {
                                            deleteOriginals = value;
                                          });
                                        },
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.only(left: 8, right: 4, bottom: 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                                onPressed: (isCompressing || dict.isEmpty || outputDir == null || (quality == -1 && format == -1))
                                    ? null
                                    : () async {
                                        setState(() {
                                          isCompressing = true;
                                        });
                                        final files = List.from(dict.keys);
                                        for (var file in files) {
                                          if (!dict.containsKey(file)) {
                                            continue;
                                          }
                                          String ext = "";
                                          final path = file.path;
                                          final fileName = file.name;
                                          final lastDotIndex = fileName.lastIndexOf('.');
                                          final name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex);
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
                                          var compressedSize = await compressFile(path, name, ext, size, quality, fps, deleteOriginals, outputDir!, coverFile?.path, onProgress: (progress) {
                                            setState(() {
                                              dict[file]![2].value = progress;
                                            });
                                          });
                                          if (compressedSize == -1) {
                                            errors.add(file);
                                            continue;
                                          }
                                          totalCompressedSize += compressedSize;
                                          dict[file]![1] = 2;
                                        }
                                        setState(() {
                                          if (!canceled) compressed = true;
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
                                                macOS: DarwinNotificationDetails(sound: 'default', badgeNumber: 0),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).hintColor,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                ),
                                child: Text(AppLocalizations.of(context)!.compresser, style: TextStyle(fontSize: 15, color: isCompressing || dict.isEmpty || outputDir == null || (quality == -1 && format == -1) ? Colors.white60 : Colors.white))),
                            // const SizedBox(height: 50),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //   children: [
                            //     IconButton(
                            //       icon: const Icon(CupertinoIcons.star, color: Colors.white, size: 30),
                            //       onPressed: () {},
                            //     ),
                            //     IconButton(
                            //       icon: Image.asset('assets/lucide/coffee.png', color: Colors.white, width: 30),
                            //       onPressed: () {},
                            //     ),
                            //     IconButton(
                            //       icon: Image.asset('assets/lucide/github.png', color: Colors.white, width: 30),
                            //       onPressed: () {},
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
            if (!formats.contains(file.name.split(".").last)) {
              errors.add(XFile(file.path));
              continue;
            } else {
              final fileSize = File(file.path).lengthSync();
              final xFile = XFile(file.path);
              if (dict.keys.any((existingFile) => existingFile.path == xFile.path)) {
                continue;
              }
              dict[XFile(file.path)] = [
                fileSize,
                0,
                ValueNotifier<double>(0.0)
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
              color: dragging ? Theme.of(context).focusColor : Theme.of(context).hintColor,
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
                                      ? AppLocalizations.of(context)!.termine
                                      : AppLocalizations.of(context)!.erreur
                                  : "${AppLocalizations.of(context)!.taille} : $fileSize Mo",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    if (compressionState == 0)
                      LinearProgressIndicator(
                        value: 0,
                        valueColor: AlwaysStoppedAnimation(Colors.indigo[700]!),
                        backgroundColor: Colors.white10,
                      )
                    else if (compressionState == 1)
                      ValueListenableBuilder<double>(
                        valueListenable: fileData[2] as ValueNotifier<double>,
                        builder: (context, progress, child) {
                          return LinearProgressIndicator(
                            value: progress,
                            valueColor: AlwaysStoppedAnimation(Colors.indigo[700]!),
                            backgroundColor: Colors.white10,
                          );
                        },
                      )
                    else if (compressionState == 2)
                      LinearProgressIndicator(
                        value: 1,
                        valueColor: AlwaysStoppedAnimation(Colors.indigo[700]!),
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
                            cancelCompression();
                            if (dict.length == 1) {
                              setState(() {
                                canceled = true;
                                dict.clear();
                                isCompressing = false;
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
                        : (quality == -1 || inPercent.round() < 0)
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
                      isCompressing = false;
                      dict.clear();
                      errors.clear();
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.clickNew, style: TextStyle(color: Colors.blue[800]))),
            ],
          ),
        ),
        // if (errors.isNotEmpty)
        // Expanded(
        //   child: ListView.builder(
        //     itemCount: errors.length,
        //     itemBuilder: (context, index) {
        //       final file = errors[index];
        //       return ListTile(
        //         title: Text(file.name),
        //         subtitle: Text(AppLocalizations.of(context)!.erreur),
        //         trailing: IconButton(
        //           icon: const Icon(
        //             CupertinoIcons.clear_thick,
        //             color: Colors.grey,
        //             size: 20,
        //           ),
        //           onPressed: () {
        //             errors.remove(file);
        //             setState(() {});
        //           },
        //         ),
        //       );
        //     },
        //   ),
        // ),
        if (errors.length != dict.length)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
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
                final name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex);
                openInExplorer("$outputDir/$name.${(quality != -1) ? "compressed." : ""}$fileExt");
              }
            },
            child: Text(Platform.isMacOS ? AppLocalizations.of(context)!.openFinder : AppLocalizations.of(context)!.openExplorer),
          ),
        const SizedBox(height: 50),
      ],
    );
  }
}

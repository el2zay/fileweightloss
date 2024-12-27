import 'dart:async';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/src/utils/script.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  int quality = 1;

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
    "webm",
    "wvm"
  ];

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
    List<XFile> newErrors = [];
    Map<XFile, List<dynamic>> newList = {};

    for (var file in result!.files) {
      if (!formats.contains(file.name.split(".").last)) {
        newErrors.add(XFile(file.path ?? ""));
        continue;
      } else {
        final duration = await getFileDuration(file.path ?? "");
        newList[XFile(file.path ?? "")] = [
          file.size,
          duration,
          0,
          ValueNotifier<double>(0.0)
        ];
      }
    }

    setState(() {
      errors.addAll(newErrors);
      dict.addAll(newList);
      if (dict.isNotEmpty) {
        outputDir = path.dirname(dict.keys.first.path);
      }
    });
  }

  Future<int> getFileDuration(path) async {
    final player = Player();
    await player.open(Media(path));
    final duration = await player.stream.duration.first;
    String durationString = duration.toString();
    var time = durationString.split(':');
    var hours = int.parse(time[0]);
    var minutes = int.parse(time[1]);
    var seconds = double.parse(time[2]);
    var totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
    var totalSecondsInt = totalSeconds.toInt();

    await player.dispose();
    return totalSecondsInt;
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
          : Row(
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
                                title: const Text(
                                  "Dossier de sortie",
                                  style: TextStyle(fontSize: 13),
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
                                      (path.basename(outputDir ?? "Parcourir")),
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
                                title: const Text(
                                  "Qualité",
                                  style: TextStyle(fontSize: 13),
                                ),
                                trailing: !isCompressing
                                    ? DropdownButtonHideUnderline(
                                        child: DropdownButton(
                                          isDense: true,
                                          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                                          style: const TextStyle(fontSize: 14),
                                          alignment: Alignment.centerRight,
                                          focusColor: Colors.transparent,
                                          value: quality,
                                          onChanged: (value) {
                                            if (isCompressing) return;
                                            setState(() {
                                              quality = value!;
                                            });
                                          },
                                          items: const [
                                            DropdownMenuItem(
                                              value: 0,
                                              child: Text("Haute"),
                                            ),
                                            DropdownMenuItem(
                                              value: 1,
                                              child: Text("Bonne"),
                                            ),
                                            DropdownMenuItem(
                                              value: 2,
                                              child: Text("Moyenne"),
                                            ),
                                            DropdownMenuItem(
                                              value: 3,
                                              child: Text("Faible"),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        quality == 0
                                            ? "Haute"
                                            : quality == 1
                                                ? "Bonne"
                                                : quality == 2
                                                    ? "Moyenne"
                                                    : "Faible",
                                        style: const TextStyle(fontSize: 14, color: Colors.white38)),
                                contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 8, right: isCompressing ? 14 : 4),
                              ),
                              const Divider(),
                              ListTile(
                                dense: true,
                                title: const Text(
                                  "Supprimer les originaux",
                                  style: TextStyle(fontSize: 13),
                                ),
                                trailing: Transform.scale(
                                  scale: Platform.isMacOS ? 0.70 : 0.75,
                                  child: Switch.adaptive(
                                    value: deleteOriginals,
                                    activeColor: isCompressing ? Colors.white38 : Colors.blue[800],
                                    thumbColor: WidgetStateProperty.all(Colors.white),
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
                            onPressed: (isCompressing || dict.isEmpty || outputDir == null)
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
                                      final path = file.path;
                                      final fileName = file.name;
                                      final lastDotIndex = fileName.lastIndexOf('.');
                                      final name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex);
                                      final ext = (lastDotIndex == -1) ? '' : fileName.substring(lastDotIndex + 1);
                                      final size = dict[file]![0];
                                      totalOriginalSize += size as int;
                                      dict[file]![2] = 1;
                                      var compressedSize = await compressFile(path, name, ext, size, dict[file]![1], quality, deleteOriginals, outputDir!, onProgress: (progress) {
                                        setState(() {
                                          dict[file]![3].value = progress;
                                        });
                                      });
                                      totalCompressedSize += compressedSize;
                                      dict[file]![2] = 2;
                                    }
                                    setState(() {
                                      compressed = true;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).hintColor,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            ),
                            child: Text("Compresser", style: TextStyle(fontSize: 15, color: (isCompressing || dict.isEmpty || outputDir == null) ? Colors.white60 : Colors.white))),
                        // const SizedBox(height: 50),
                        // TextButton.icon(
                        //   onPressed: () {},
                        //   label: const Text(
                        //     "Donnez-nous votre avis",
                        //     style: TextStyle(color: Colors.white),
                        //   ),
                        //   icon: const Icon(CupertinoIcons.star, color: Colors.white),
                        // ),
                      ],
                    ),
                  ),
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
              final duration = await getFileDuration(file.path);
              final fileSize = File(file.path).lengthSync();
              dict[XFile(file.path)] = [
                fileSize,
                duration,
                0,
                ValueNotifier<double>(0.0)
              ];
            }
          }
          setState(() {
            if (dict.isNotEmpty) {
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
          dragging ? "Vous pouvez lâcher !" : "Déposez vos fichiers ici",
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
          child: const Text(
            "ou cliquez pour sélectionner vos fichiers",
            style: TextStyle(
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
              final compressionState = fileData[2];
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
                          ? "En attente — $fileSize Mo"
                          : compressionState == 1
                              ? "Compression en cours... — $fileSize Mo "
                              : compressionState == 2
                                  ? "Terminé"
                                  : "Taille : $fileSize Mo",
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
                        valueListenable: fileData[3] as ValueNotifier<double>,
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
                trailing: (compressionState == 0)
                    ? IconButton(
                        hoverColor: Colors.transparent,
                        icon: const Icon(
                          CupertinoIcons.clear_thick,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          dict.remove(file);
                          setState(() {});
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
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déposez vos fichiers ici", style: TextStyle(color: Colors.white, fontSize: 18)),
                    SizedBox(height: 10),
                    Text("ou cliquez pour en ajouter", style: TextStyle(color: Colors.white, fontSize: 16)),
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
    final inPercent = totalSize / totalOriginalSize * 100;
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.check_mark_circled_solid, size: 60, color: CupertinoColors.systemGreen),
              const SizedBox(height: 15),
              const Text(
                "Vos fichiers sont prêts ! ",
                style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Au total vos fichiers sont ${inPercent.round()}% plus légers.",
                style: const TextStyle(color: Colors.white, fontSize: 18),
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
                  child: Text("Cliquez ici pour compresser de nouveaux fichiers", style: TextStyle(color: Colors.blue[800]))),
            ],
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: () {
            final fileName = dict.keys.elementAt(0).name;
            final fileExt = fileName.split('.').last;
            final lastDotIndex = fileName.lastIndexOf('.');
            final name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex);
            openInExplorer("$outputDir/$name.compressed.$fileExt");
          },
          child: const Text("Ouvrir dans le Finder", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

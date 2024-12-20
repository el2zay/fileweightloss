import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss_gui/main.dart';
import 'package:fileweightloss_gui/src/utils/script.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:media_kit/media_kit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool installingFFmpeg = false;
  final Map<XFile, List> list = {};
  final List<XFile> errors = [];
  int totalOriginalSize = 0;
  int totalCompressedSize = 0;
  bool dragging = false;
  FilePickerResult? result;
  bool deleteOriginals = false;
  bool openExplorer = true;
  String? outputDir;
  bool compressed = false;
  bool isCompressing = false;

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

  Future<void> _pickFile() async {
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
          duration
        ];
      }
    }

    setState(() {
      errors.addAll(newErrors);
      list.addAll(newList);
    });
  }

  Future getFileDuration(path) async {
    final player = Player();
    await player.open(Media(path));
    final duration = await player.stream.duration.first;
    await player.dispose();
    return duration;
  }

  void openInExplorer(String? path) async {
    if (path == null) return;
    if (openExplorer) {
      if (Platform.isWindows) {
        await Process.run("explorer", [
          "/select,",
          outputDir!
        ]);
      } else if (Platform.isMacOS) {
        await Process.run("open", [
          "-R",
          outputDir!
        ]);
      } else if (Platform.isLinux) {
        await Process.run("xdg-open", [
          outputDir!
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (ffmpegPath.isEmpty)
          ? AlertDialog(
              title: Text(
                installingFFmpeg ? "Veuillez patienter" : "Module requis",
                style: const TextStyle(fontSize: 16),
              ),
              content: installingFFmpeg
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Text("Installation en cours", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text("Un module (ffmpeg) est requis pour continuer. Voulez-vous l'installer ?"),
              actions: [
                if (!installingFFmpeg) ...[
                  TextButton(
                    onPressed: () {
                      exit(0);
                    },
                    child: const Text("Fermer", style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        final Uri url = Uri.parse('https://www.ffmpeg.org/download.html');
                        if (!await launchUrl(url)) {
                          throw Exception('Could not launch $url');
                        }
                        // setState(() {

                        // installingFFmpeg = true;
                        // });
                      },
                      child: const Text("Installer le module", style: TextStyle(color: Colors.white))),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      if (list.isEmpty) _pickFile();
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
                            list[XFile(file.path)] = [
                              fileSize,
                              duration
                            ];
                          }
                        }
                        setState(() {});
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: DottedBorder(
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
                              child: compressed
                                  ? done()
                                  : list.isNotEmpty
                                      ? notEmptyList()
                                      : emptyList()),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          color: Theme.of(context).hintColor,
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
                                    child: Text((outputDir?.split("/").last ?? "Parcourir"), style: TextStyle(fontSize: 14, color: isCompressing ? Colors.white38 : Colors.blue[800]))),
                                contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 8, right: 4),
                              ),
                              const Divider(),
                              ListTile(
                                dense: true,
                                title: const Text(
                                  "Supprimer les originaux",
                                  style: TextStyle(fontSize: 13),
                                ),
                                trailing: Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
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
                                contentPadding: const EdgeInsets.only(left: 8, right: 4),
                              ),
                              const Divider(),
                              ListTile(
                                dense: true,
                                title: const Text(
                                  "Afficher dans l'explorateur",
                                  style: TextStyle(fontSize: 13),
                                ),
                                trailing: Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: openExplorer,
                                    activeColor: isCompressing ? Colors.white38 : Colors.blue[800],
                                    thumbColor: WidgetStateProperty.all(Colors.white),
                                    onChanged: (value) {
                                      if (isCompressing) return;
                                      setState(() {
                                        openExplorer = value;
                                      });
                                    },
                                  ),
                                ),
                                contentPadding: const EdgeInsets.only(left: 8, right: 4),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                            onPressed: (isCompressing || list.isEmpty || outputDir == null)
                                ? null
                                : () async {
                                    setState(() {
                                      isCompressing = true;
                                    });
                                    for (var file in list.keys) {
                                      final path = file.path;
                                      final fileName = file.name;
                                      final lastDotIndex = fileName.lastIndexOf('.');
                                      final name = (lastDotIndex == -1) ? fileName : fileName.substring(0, lastDotIndex);
                                      final ext = (lastDotIndex == -1) ? '' : fileName.substring(lastDotIndex + 1);
                                      final size = list[file]![0];
                                      totalOriginalSize += size as int;
                                      var compressedSize = await compressFile(path, name, ext, size, 0, deleteOriginals, outputDir!);
                                      totalCompressedSize += compressedSize;
                                    }
                                    setState(() {
                                      compressed = true;
                                    });
                                    // Nom de la fonction à appeler pour ouvrir l'explorateur
                                    if (openExplorer) openInExplorer(outputDir);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).hintColor,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            ),
                            child: Text("Compresser", style: TextStyle(fontSize: 15, color: (isCompressing || list.isEmpty || outputDir == null) ? Colors.white60 : Colors.white))),
                        const SizedBox(height: 50),
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
        if (list.isNotEmpty)
          Expanded(
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final key = list.keys.elementAt(oldIndex);
                final value = list.remove(key);
                final entries = list.entries.toList();
                entries.insert(newIndex, MapEntry(key, value!));
                list
                  ..clear()
                  ..addEntries(entries);
                setState(() {});
              },
              children: [
                for (var index = 0; index < list.length; index++)
                  ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(CupertinoIcons.bars, color: Colors.grey),
                    ),
                    key: ValueKey(list.keys.elementAt(index)),
                    title: Text(list.keys.elementAt(index).name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Taille : ${((list.values.elementAt(index)[0] as int) / 1000000).round()} Mo",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: 0.35,
                          valueColor: AlwaysStoppedAnimation(Colors.indigo[700]!),
                          backgroundColor: Colors.white10,
                        )
                      ],
                    ),
                    trailing: IconButton(
                      hoverColor: Colors.transparent,
                      icon: const Icon(
                        CupertinoIcons.clear_thick,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        list.remove(list.keys.elementAt(index));
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _pickFile,
            child: const Text("Ajouter des fichiers", style: TextStyle(color: Colors.white))),
        const SizedBox(
          height: 50,
        )
      ],
    );
  }

  Widget done() {
    final totalSize = totalOriginalSize - totalCompressedSize;
    final inPercent = totalSize / totalOriginalSize * 100;
    return Column(
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
              setState(() {
                compressed = false;
                isCompressing = false;
                list.clear();
                errors.clear();
              });
            },
            child: Text("Cliquez ici pour compresser de nouveaux fichiers", style: TextStyle(color: Colors.blue[800]))),
      ],
    );
  }
}

import 'package:file_selector/file_selector.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:fileweightloss/src/widgets/select.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:fileweightloss/l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:io';

Widget buildCard(BuildContext context, int type, bool isCompressing, String? outputDir, Function(String?) setStateOutputDir, int quality,
    Function(int) setStateQuality, bool deleteOriginals, Function(bool) setStateDeleteOriginals,
    [int? format,
    Function(int)? setStateFormat,
    XFile? coverFile,
    VoidCallback? pickCover,
    int? fps,
    Function(double)? setStateFps,
    bool? keepMetadata,
    Function(bool)? setStateKeepMetadata]) {
  saveLogs("Building compression card - Type: $type, IsCompressing: $isCompressing, Quality: $quality, Format: $format, FPS: $fps");

  return ShadCard(
    backgroundColor: Theme.of(context).cardColor,
    padding: const EdgeInsets.all(0),
    child: Column(
      children: [
        ListTile(
          dense: false,
          minTileHeight: 40,
          title: Text(
            AppLocalizations.of(context)!.outputDirectory,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
          ),
          trailing: ShadButton.ghost(
            hoverBackgroundColor: Colors.transparent,
            enabled: !isCompressing,
            onPressed: isCompressing
                ? null
                : () async {
                    saveLogs("Opening directory picker for output directory");
                    String? selectedDirectory = await getDirectoryPath();
                    if (selectedDirectory != null) {
                      saveLogs("Output directory selected: $selectedDirectory");
                      setStateOutputDir(selectedDirectory);
                    } else {
                      saveLogs("No output directory selected");
                    }
                  },
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.15),
              child: Text(
                (outputDir != null ? path.basename(outputDir) : AppLocalizations.of(context)!.browse),
                style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ),
          contentPadding: const EdgeInsets.only(top: 5, bottom: 0, left: 8),
        ),
        const Divider(),
        ListTile(
          title: Padding(
            padding: const EdgeInsets.only(left: 8, top: 4, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppLocalizations.of(context)!.quality} ${type == 1 ? "$quality% – ${quality >= 80 ? AppLocalizations.of(context)!.high : quality >= 60 ? AppLocalizations.of(context)!.good : quality >= 40 ? AppLocalizations.of(context)!.medium : AppLocalizations.of(context)!.low}" : ""}",
                  style: const TextStyle(fontSize: 14, fontFeatures: [
                    FontFeature.tabularFigures(),
                  ]),
                ),
                const SizedBox(height: 5),
                if (type == 1) ...[
                  ShadSlider(
                    initialValue: 70,
                    divisions: 89,
                    min: 1,
                    max: 90,
                    trackHeight: 2,
                    thumbRadius: 8,
                    enabled: !isCompressing,
                    onChanged: !isCompressing
                        ? (value) {
                            saveLogs("Image quality slider changed to: ${value.toInt()}%");
                            setStateQuality(value.toInt());
                          }
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -4),
                    horizontalTitleGap: 0,
                    title: Text(
                      AppLocalizations.of(context)!.keepMetadata,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Transform.scale(
                      scale: Platform.isMacOS ? 0.70 : 0.75,
                      child: Switch.adaptive(
                        value: keepMetadata!,
                        thumbColor: WidgetStateProperty.resolveWith((states) => Colors.black),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white,
                        onChanged: (value) {
                          if (isCompressing) return;
                          saveLogs("Keep metadata toggle changed to: $value");
                          setStateKeepMetadata!(value);
                        },
                      ),
                    ),
                    contentPadding: type != 1 ? const EdgeInsets.only(top: 4, bottom: 0, right: 4) : const EdgeInsets.all(0),
                  ),
                ],
              ],
            ),
          ),
          trailing: type != 1
              ? buildSelect(
                  context,
                  isCompressing,
                  {
                    if (type == 0) "Original": -1,
                    AppLocalizations.of(context)!.high: 0,
                    AppLocalizations.of(context)!.good: 1,
                    AppLocalizations.of(context)!.medium: 2,
                    AppLocalizations.of(context)!.low: 3,
                  },
                  quality, (value) {
                  String qualityLabel = value == -1
                      ? "Original"
                      : value == 0
                          ? "High"
                          : value == 1
                              ? "Good"
                              : value == 2
                                  ? "Medium"
                                  : "Low";
                  saveLogs("Quality select changed to: $value ($qualityLabel)");
                  setStateQuality(value);
                })
              : null,
          contentPadding: const EdgeInsets.all(0),
        ),
        const Divider(),
        if (type == 0) ...[
          ListTile(
            dense: false,
            title: const Text(
              "Format",
              style: TextStyle(fontSize: 14),
            ),
            trailing: buildSelect(
                context,
                isCompressing,
                {
                  "Original": -1,
                  "MP4": 0,
                  "MP3": 1,
                  "GIF": 2,
                },
                (format != null) ? format : -1, (value) {
              String formatLabel = value == -1
                  ? "Original"
                  : value == 0
                      ? "MP4"
                      : value == 1
                          ? "MP3"
                          : "GIF";
              saveLogs("Format select changed to: $value ($formatLabel)");
              setStateFormat!(value);
            }),
            contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 8),
          ),
          if (format == 1) ...[
            const Divider(),
            ListTile(
              dense: true,
              title: const Text(
                "Cover",
                style: TextStyle(fontSize: 14),
              ),
              trailing: SizedBox(
                width: coverFile != null ? MediaQuery.of(context).size.width * 0.2 : null,
                child: ShadButton.ghost(
                  hoverBackgroundColor: Colors.transparent,
                  enabled: !isCompressing,
                  onPressed: () {
                    if (isCompressing) return;
                    saveLogs("Cover picker button pressed");
                    if (pickCover != null) {
                      pickCover();
                    }
                  },
                  child: Text(
                    coverFile == null ? AppLocalizations.of(context)!.browse : coverFile.name,
                    style: TextStyle(fontSize: 14, color: Colors.blue[800]),
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
                    style: const TextStyle(fontSize: 14),
                  ),
                  ShadSlider(
                    min: 10,
                    max: 60,
                    divisions: 50,
                    trackHeight: 2,
                    thumbRadius: 8,
                    enabled: !isCompressing,
                    initialValue: fps!.toDouble(),
                    onChanged: !isCompressing
                        ? (value) {
                            saveLogs("FPS slider changed to: ${value.toInt()}");
                            setStateFps!(value);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
          const Divider(),
        ],
        ListTile(
          dense: true,
          title: Text(
            AppLocalizations.of(context)!.deleteOriginals,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Transform.scale(
            scale: Platform.isMacOS ? 0.70 : 0.75,
            child: Switch.adaptive(
              value: deleteOriginals,
              thumbColor: WidgetStateProperty.resolveWith((states) => Colors.black),
              activeColor: Colors.white,
              activeTrackColor: Colors.white,
              onChanged: (value) {
                if (isCompressing) return;
                saveLogs("Delete originals toggle changed to: $value");
                setStateDeleteOriginals(value);
              },
            ),
          ),
          contentPadding: const EdgeInsets.only(left: 8, right: 4, bottom: 4),
        ),
      ],
    ),
  );
}

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/src/widgets/select.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:io';

Widget buildCard(
    BuildContext context,
    int type,
    bool isCompressing,
    String? outputDir,
    Function(String?) setStateOutputDir,
    int quality,
    Function(int) setStateQuality,
    bool deleteOriginals,
    Function(bool) setStateDeleteOriginals,
    [int? format,
    Function(int)? setStateFormat,
    XFile? coverFile,
    VoidCallback? pickCover,
    int? fps,
    Function(double)? setStateFps]) {
  return ShadCard(
    backgroundColor: Theme.of(context).cardColor,
    padding: const EdgeInsets.all(0),
    child: Column(
      children: [
        ListTile(
          dense: false,
          minTileHeight: 40,
          title: Text(
            AppLocalizations.of(context)!.sortie,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.left,
          ),
          trailing: ShadButton.ghost(
            hoverBackgroundColor: Colors.transparent,
            enabled: !isCompressing,
            onPressed: isCompressing
                ? null
                : () async {
                    String? selectedDirectory =
                        await FilePicker.platform.getDirectoryPath();
                    setStateOutputDir(selectedDirectory);
                  },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.15),
              child: Text(
                (outputDir != null
                    ? path.basename(outputDir)
                    : AppLocalizations.of(context)!.parcourir),
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
          dense: false,
          title: Text(
            AppLocalizations.of(context)!.qualite,
            style: const TextStyle(fontSize: 13),
          ),
          trailing: buildSelect(
              context,
              isCompressing,
              {
                if (type == 0) "Original": -1,
                AppLocalizations.of(context)!.haute: 0,
                AppLocalizations.of(context)!.bonne: 1,
                AppLocalizations.of(context)!.moyenne: 2,
                AppLocalizations.of(context)!.faible: 3,
              },
              quality, (value) {
            setStateQuality(value);
          }),
          contentPadding: EdgeInsets.only(
              top: 0, bottom: 0, left: 8, right: isCompressing ? 14 : 4),
        ),
        const Divider(),
        if (type == 0) ...[
          ListTile(
            dense: false,
            title: const Text(
              "Format",
              style: TextStyle(fontSize: 13),
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
              setStateFormat!(value);
            }),
            contentPadding: EdgeInsets.only(
                top: 0, bottom: 0, left: 8, right: isCompressing ? 14 : 4),
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
                width: coverFile != null
                    ? MediaQuery.of(context).size.width * 0.2
                    : null,
                child: ShadButton.ghost(
                  hoverBackgroundColor: Colors.transparent,
                  enabled: !isCompressing,
                  onPressed: pickCover,
                  child: Text(
                    coverFile == null
                        ? AppLocalizations.of(context)!.parcourir
                        : coverFile.name,
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
                    style: const TextStyle(fontSize: 13),
                  ),
                  ShadSlider(
                    min: 10,
                    max: 30,
                    divisions: 20,
                    trackHeight: 2,
                    thumbRadius: 8,
                    enabled: !isCompressing,
                    initialValue: fps!.toDouble(),
                    onChanged: !isCompressing
                        ? (value) {
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
            AppLocalizations.of(context)!.supprimer,
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Transform.scale(
            scale: Platform.isMacOS ? 0.70 : 0.75,
            child: Switch.adaptive(
              value: deleteOriginals,
              thumbColor:
                  WidgetStateProperty.resolveWith((states) => Colors.black),
              activeColor: Colors.white,
              activeTrackColor: Colors.white,
              onChanged: (value) {
                if (isCompressing) return;
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

import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:fileweightloss/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> pickBin() async {
  final box = GetStorage("MyStorage", getStoragePath());
  final file = await openFile(acceptedTypeGroups: [
    XTypeGroup(label: 'FFmpeg', extensions: [
      Platform.isWindows ? 'exe' : ''
    ])
  ]);

  if (file != null) {
    ffmpegPath = file.path;
    box.write('ffmpegPath', ffmpegPath);
  }
}

@override
Widget buildDialog(BuildContext context, bool errorFfmpeg, Function setState) {
  return installingFFmpeg
      ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.installing,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        )
      : ShadDialog.alert(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            AppLocalizations.of(context)!.requiredModule,
          ),
          description: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.ffmpegRequired,
            ),
          ),
          actions: [
            // Tout à gauche
            ShadButton.outline(
                child: Text(AppLocalizations.of(context)!.retry),
                onPressed: () {
                  // Réessayer de get le chemin de ffmpeg
                  ffmpegPath = getFFmpegPath();
                  if (ffmpegPath.isNotEmpty) {
                    Phoenix.rebirth(context);
                  } else {
                    setState(() {
                      errorFfmpeg = true;
                    });
                  }
                }),
            const Spacer(),
            ShadButton.outline(
              child: Text(AppLocalizations.of(context)!.locateFfmpeg),
              onPressed: () async {
                await pickBin();
                setState(() {
                  errorFfmpeg = false;
                });
              },
            ),
            const SizedBox(width: 10),
            ShadButton(
              child: Text(AppLocalizations.of(context)!.install),
              onPressed: () async {
                setState(() {
                  installingFFmpeg = true;
                });
                final success = await installFfmpeg();
                setState(() {
                  installingFFmpeg = false;
                  if (!success) errorFfmpeg = true;
                });
              },
            ),
          ],
        );
}

import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/utils/restart_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> pickBin() async {
  logarte.log("Opening binary file picker");
  final box = GetStorage("MyStorage", getStoragePath());
  
  try {
    final file = await openFile(acceptedTypeGroups: [
      XTypeGroup(label: 'FFmpeg', extensions: [
        Platform.isWindows ? 'exe' : ''
      ])
    ]);

    if (file != null) {
      logarte.log("Binary file selected: ${file.path}");
      ffmpegPath = file.path;
      box.write('ffmpegPath', ffmpegPath);
      logarte.log("FFmpeg path saved to storage: $ffmpegPath");
    } else {
      logarte.log("No binary file selected");
    }
  } catch (e) {
    logarte.log("Error picking binary file: $e");
  }
}

@override
Widget buildDialog(BuildContext context, bool errorFfmpeg, Function setState) {
  logarte.log("Building dialog - Installing FFmpeg: $installingFFmpeg, Error FFmpeg: $errorFfmpeg");
  
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
                  logarte.log("Retry button pressed - attempting to locate FFmpeg");
                  // Réessayer de get le chemin de ffmpeg
                  ffmpegPath = getFFmpegPath();
                  if (ffmpegPath.isNotEmpty) {
                    logarte.log("FFmpeg found on retry: $ffmpegPath - restarting app");
                    RestartHelper.restartApp();
                  } else {
                    logarte.log("FFmpeg still not found on retry");
                    setState(() {
                      errorFfmpeg = true;
                    });
                  }
                }),
            const Spacer(),
            ShadButton.outline(
              child: Text(AppLocalizations.of(context)!.locateFfmpeg),
              onPressed: () async {
                logarte.log("Locate FFmpeg button pressed");
                await pickBin();
                setState(() {
                  errorFfmpeg = false;
                });
                logarte.log("Dialog state updated after binary selection");
              },
            ),
            const SizedBox(width: 10),
            ShadButton(
              child: Text(AppLocalizations.of(context)!.install),
              onPressed: () async {
                logarte.log("Install FFmpeg button pressed");
                setState(() {
                  installingFFmpeg = true;
                });
                logarte.log("Starting FFmpeg installation process");
                
                final success = await installFfmpeg();
                
                setState(() {
                  installingFFmpeg = false;
                  if (!success) errorFfmpeg = true;
                });
                
                if (success) {
                  logarte.log("FFmpeg installation completed successfully");
                } else {
                  logarte.log("FFmpeg installation failed");
                }
              },
            ),
          ],
        );
}
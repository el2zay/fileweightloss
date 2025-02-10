import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> pickBin() async {
  final box = GetStorage();
  final file = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: (Platform.isWindows)
        ? [
            'exe'
          ]
        : [
            ''
          ],
  );

  if (file != null) {
    ffmpegPath = file.files.single.path!;
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
                AppLocalizations.of(context)!.installation,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        )
      : ShadDialog.alert(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            AppLocalizations.of(context)!.moduleRequis,
          ),
          description: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.ffmpegRequired,
            ),
          ),
          actions: [
            ShadButton.outline(
              child: Text(AppLocalizations.of(context)!.locateFfmpeg),
              onPressed: () async {
                await pickBin();
                setState(() {
                  errorFfmpeg = false;
                });
              },
            ),
            ShadButton(
              child: Text(AppLocalizations.of(context)!.installer),
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

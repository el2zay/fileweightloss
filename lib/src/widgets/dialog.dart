import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> pickFfmpeg() async {
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

Widget buildMacosDialog(BuildContext context, bool errorFfmpeg, Function setState) {
  return MacosTheme(
    data: MacosThemeData.dark(),
    child: installingFFmpeg
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.installation,
                  textAlign: TextAlign.center,
                  style: MacosTheme.of(context).typography.title2.copyWith(color: Colors.white),
                ),
              ],
            ),
          )
        : MacosAlertDialog(
            horizontalActions: false,
            appIcon: Image.asset("assets/icon_macos.png"),
            title: Text(
              AppLocalizations.of(context)!.moduleRequis,
              style: MacosTheme.of(context).typography.headline.copyWith(color: Colors.white),
            ),
            message: Text(
              AppLocalizations.of(context)!.ffmpegRequired,
              textAlign: TextAlign.center,
              style: MacosTypography.of(context).subheadline.copyWith(color: Colors.white),
            ),
            primaryButton: PushButton(
              secondary: true,
              controlSize: ControlSize.large,
              child: Text(AppLocalizations.of(context)!.locateFfmpeg, style: const TextStyle(color: Colors.white)),
              onPressed: () async {
                await pickFfmpeg();
                setState(() {
                  errorFfmpeg = false;
                });
              },
            ),
            secondaryButton: PushButton(
              controlSize: ControlSize.large,
              child: Text(AppLocalizations.of(context)!.installer, style: const TextStyle(color: Colors.white)),
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
          ),
  );
}

Widget buildWindowsDialog(BuildContext context, bool errorFfmpeg, Function setState) {
  return installingFFmpeg
      ? fluent.FluentTheme(
          data: fluent.FluentThemeData(),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const fluent.ProgressRing(),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.installation,
                  textAlign: TextAlign.center,
                  style: MacosTheme.of(context).typography.title2.copyWith(color: Colors.white),
                )
              ],
            ),
          ),
        )
      : fluent.FluentTheme(
          data: fluent.FluentThemeData.dark(),
          child: fluent.ContentDialog(
            title: Text(
              AppLocalizations.of(context)!.moduleRequis,
            ),
            content: Text(
              AppLocalizations.of(context)!.ffmpegRequired,
              style: const TextStyle(color: fluent.Colors.white),
            ),
            actions: [
              fluent.FilledButton(
                style: fluent.ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(fluent.Colors.grey),
                ),
                child: const Text('Localiser', style: TextStyle(color: fluent.Colors.white)),
                onPressed: () async {
                  await pickFfmpeg();
                  setState(() {
                    errorFfmpeg = false;
                  });
                },
              ),
              fluent.FilledButton(
                style: fluent.ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(fluent.Colors.blue),
                ),
                child: const Text('Installer', style: TextStyle(color: fluent.Colors.white)),
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
          ),
        );
}

Widget buildDefaultDialog(BuildContext context, bool errorFfmpeg, Function setState) {
  return AlertDialog(
    title: Text(
      installingFFmpeg ? AppLocalizations.of(context)!.pleaseWait : AppLocalizations.of(context)!.moduleRequis,
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
              Text(AppLocalizations.of(context)!.installation, style: const TextStyle(color: Colors.white)),
            ],
          )
        : Text(errorFfmpeg ? AppLocalizations.of(context)!.installationError : AppLocalizations.of(context)!.ffmpegRequired),
    actions: [
      if (!installingFFmpeg) ...[
        TextButton(
          onPressed: () {
            pickFfmpeg();
            setState(() {
              errorFfmpeg = false;
            });
          },
          child: Text(AppLocalizations.of(context)!.locate, style: const TextStyle(color: Colors.white)),
        ),
        if (!errorFfmpeg)
          ElevatedButton(
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
            child: Text(AppLocalizations.of(context)!.installModule, style: const TextStyle(color: Colors.white)),
          ),
      ],
    ],
  );
}

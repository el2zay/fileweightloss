import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

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
                  "Installation en cours",
                  textAlign: TextAlign.center,
                  style: MacosTheme.of(context).typography.title2.copyWith(color: Colors.white),
                ),
              ],
            ),
          )
        : MacosAlertDialog(
            appIcon: Image.asset("assets/icon_macos.png"),
            title: Text(
              "Module requis",
              style: MacosTheme.of(context).typography.headline.copyWith(color: Colors.white),
            ),
            message: Text(
              "Un module (ffmpeg) est requis pour continuer. Voulez-vous l'installer ?",
              textAlign: TextAlign.center,
              style: MacosTypography.of(context).subheadline.copyWith(color: Colors.white),
            ),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              child: const Text('Installer', style: TextStyle(color: Colors.white)),
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
            secondaryButton: PushButton(
              secondary: true,
              controlSize: ControlSize.large,
              child: const Text('Fermer', style: TextStyle(color: Colors.white)),
              onPressed: () {},
            )),
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
                  "Installation en cours",
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
            title: const Text(
              "Module requis",
            ),
            content: const Text(
              "Un module (ffmpeg) est requis pour continuer. Voulez-vous l'installer ?",
              style: TextStyle(color: fluent.Colors.white),
            ),
            actions: [
              fluent.FilledButton(
                style: fluent.ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(fluent.Colors.grey),
                ),
                child: const Text('Fermer', style: TextStyle(color: fluent.Colors.white)),
                onPressed: () => exit(0),
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
        : Text(errorFfmpeg ? "Désolé mais une erreur s'est produite\nAssurez-vous d'être connecté à Internet." : "Un module (ffmpeg) est requis pour continuer. Voulez-vous l'installer ?"),
    actions: [
      if (!installingFFmpeg) ...[
        TextButton(
          onPressed: () {
            exit(0);
          },
          child: const Text("Fermer", style: TextStyle(color: Colors.white)),
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
            child: const Text("Installer le module", style: TextStyle(color: Colors.white)),
          ),
      ],
    ],
  );
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ffmpegController = TextEditingController(text: getFFmpegPath());
  final _gsController = TextEditingController(text: getGsPath());
  final _defaultOutputController = TextEditingController(text: GetStorage().read("defaultOutputPath"));
  final _formKey = GlobalKey<ShadFormState>();
  final box = GetStorage();
  int showFinalMessage = 0; // 0 = No, 1 = Success, 2 = Error
  bool alreadyPressed = false;

  final languages = {
    'en': 'English',
    'fr': 'Français',
  };

  @override
  void initState() {
    super.initState();
    isSettingsPage = true;
  }

  @override
  void dispose() {
    isSettingsPage = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentLocale = getLocale(View.of(context).platformDispatcher.locale, WidgetsBinding.instance.platformDispatcher.locales);
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.parametres, style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ShadForm(
        key: _formKey,
        child: ListView(
          children: [
            pathField(
              context,
              _ffmpegController,
              AppLocalizations.of(context)!.currentPath("FFmpeg"),
              "ffmpegPath",
              (value) {
                if (value!.isEmpty) {
                  return AppLocalizations.of(context)!.cheminVide;
                } else if (!File(value).existsSync()) {
                  return AppLocalizations.of(context)!.pathErreur("fichier");
                }
                return null;
              },
              () async {
                await pickBin();
                setState(() {});
              },
              null,
              AppLocalizations.of(context)!.ffmpegTooltip,
            ),
            pathField(
              context,
              _gsController,
              AppLocalizations.of(context)!.currentPath("GhostScript"),
              "gsPath",
              (value) {
                if (value!.isNotEmpty && !File(value).existsSync()) {
                  return AppLocalizations.of(context)!.pathErreur("fichier");
                }
                return null;
              },
              () async {
                await pickBin();
                setState(() {});
              },
              () {
                showShadDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return ShadDialog(
                          title: Text("${AppLocalizations.of(context)!.installer} GhostScript"),
                          description: showFinalMessage == 0
                              ? RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.white70),
                                    children: [
                                      TextSpan(text: AppLocalizations.of(context)!.toInstall),
                                      TextSpan(
                                        text: AppLocalizations.of(context)!.ici,
                                        style: const TextStyle(decoration: TextDecoration.underline),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            if (Platform.isMacOS) openInBrowser("https://files.bassinecorp.fr/Ghostscript-10.04.0.pkg");
                                            if (Platform.isWindows) openInBrowser("https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/gs10040w64.exe");
                                            if (Platform.isLinux) openInBrowser("https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/gs_10.04.0_amd64_snap.tgz");
                                          },
                                      ),
                                      const TextSpan(text: " "),
                                      TextSpan(text: AppLocalizations.of(context)!.installerGs),
                                    ],
                                  ),
                                )
                              : showFinalMessage == 1
                                  ? finalMessage(context, false)
                                  : finalMessage(context, true),
                          actions: [
                            ShadButton(
                              child: const Text('OK'),
                              onPressed: () {
                                if (alreadyPressed) {
                                  Navigator.pop(context);
                                  setStateDialog(() {
                                    alreadyPressed = false;
                                    showFinalMessage = 0;
                                  });
                                } else {
                                  setStateDialog(() {
                                    alreadyPressed = true;
                                    _gsController.text = getGsPath(true);
                                    if (_gsController.text.isEmpty) {
                                      showFinalMessage = 2;
                                    } else {
                                      showFinalMessage = 1;
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              AppLocalizations.of(context)!.tooltipGhostscript,
            ),
            pathField(context, _defaultOutputController, AppLocalizations.of(context)!.dossierParDefaut, "defaultOutputPath", (value) {
              if (value != null && value.isNotEmpty && !Directory(value).existsSync()) {
                return AppLocalizations.of(context)!.pathErreur("dossier");
              } else if (value == null || value.isEmpty) {
                box.remove("defaultOutputPath");
              }
              return null;
            }, () async {
              final dirPath = (await FilePicker.platform.getDirectoryPath())!;
              _defaultOutputController.text = dirPath;
              box.write("defaultOutputPath", dirPath);
              setState(() {});
            }),
            ListTile(
              title: Text(AppLocalizations.of(context)!.langue),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180),
                    child: ShadSelect<String>(
                      placeholder: Text(currentLocale.languageCode == 'fr' ? 'Français' : 'English'),
                      options: [
                        ...languages.entries.map((e) => ShadOption(value: e.key, child: Text(e.value))),
                      ],
                      selectedOptionBuilder: (context, value) => Text(languages[value]!),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            currentLocale = Locale(value);
                            box.write("language", value);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.redemarrer,
                    style: const TextStyle(fontSize: 14),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ListTile(
                title: Text(
                  AppLocalizations.of(context)!.checkUpdates,
                ),
                trailing: Transform.scale(
                  scale: Platform.isMacOS ? 0.70 : 0.75,
                  child: Switch.adaptive(
                    value: box.read("checkUpdates") ?? false,
                    thumbColor: WidgetStateProperty.resolveWith((states) => Colors.black),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        box.write("checkUpdates", value);
                      });
                    },
                  ),
                ),
              ),
            ),
            const Divider(
              color: Colors.white12,
            ),
            const SizedBox(height: 15),
            ListTile(
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${box.read("totalFiles")} ${AppLocalizations.of(context)!.fichiersTraites}", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 5),
                  Text("${formatSize(box.read("totalSize"))} ${AppLocalizations.of(context)!.economises}", style: const TextStyle(fontSize: 15)),
                ],
              ),
              trailing: ShadButton.outline(
                  child: Text(AppLocalizations.of(context)!.reset),
                  onPressed: () {
                    box.write("totalFiles", 0);
                    box.write("totalSize", 0);
                    setState(() {});
                  }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShadTooltip(
                  builder: (context) => Text(AppLocalizations.of(context)!.coffee),
                  child: IconButton(
                      onPressed: () {
                        openInBrowser("https://ko-fi.com/el2zay");
                      },
                      icon: const Icon(LucideIcons.coffee, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => Text(AppLocalizations.of(context)!.repo),
                  child: IconButton(
                      onPressed: () {
                        openInBrowser("https://github.com/el2zay/fileweightloss");
                      },
                      icon: const Icon(LucideIcons.github, size: 25)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget pathField(BuildContext context, TextEditingController controller, String title, String valueToSave, FormFieldValidator<String> validator, VoidCallback onPressed, [VoidCallback? secondOnPress, String? tolltip]) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          tolltip != null
              ? ShadTooltip(
                  builder: (context) => Text(tolltip, textAlign: TextAlign.center),
                  child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        LucideIcons.circleHelp,
                        size: 20,
                        color: Colors.white,
                      )),
                )
              : const SizedBox(width: 0),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: ShadInputFormField(
              controller: controller,
              onSubmitted: (value) {
                if (_formKey.currentState!.saveAndValidate()) {
                  box.write(valueToSave, controller.text);
                }
              },
              validator: validator,
            ),
          ),
          const SizedBox(width: 20),
          ShadButton.outline(
            onPressed: () {
              onPressed();
            },
            // TODO pourquoi explorer bouge quand il y a une erreur du validator
            child: Text(AppLocalizations.of(context)!.explorer),
          ),
          const SizedBox(width: 5),
          if (secondOnPress != null)
            ShadButton.outline(
              onPressed: () {
                secondOnPress();
              },
              child: Text(AppLocalizations.of(context)!.installer),
            )
        ],
      ),
    );
  }
}

Widget finalMessage(context, error) {
  return Column(
    children: [
      Icon(
        error ? CupertinoIcons.xmark_circle : CupertinoIcons.check_mark_circled_solid,
        color: error == true ? Colors.red : CupertinoColors.systemGreen,
        size: 50,
      ),
      const SizedBox(height: 10),
      Text(!error ? AppLocalizations.of(context)!.gsSuccess0 : AppLocalizations.of(context)!.gsError0, style: const TextStyle(fontSize: 20, color: Colors.white)),
      Text(!error ? AppLocalizations.of(context)!.gsSuccess1 : AppLocalizations.of(context)!.gsError1, style: const TextStyle(fontSize: 15, color: Colors.white70)),
    ],
  );
}

String formatSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(2)} Ko';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(2)} Mo';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} Go';
}

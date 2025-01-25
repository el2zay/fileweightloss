import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
// TODO mettre settings en sheet

class _SettingsPageState extends State<SettingsPage> {
  final _ffmpegController = TextEditingController(text: getFFmpegPath());
  final _defaultOutputController = TextEditingController(text: GetStorage().read("defaultOutputPath"));
  final _formKey = GlobalKey<ShadFormState>();
  final box = GetStorage();

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
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.parametres, style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
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
              AppLocalizations.of(context)!.ffmpegPath,
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
                await pickFfmpeg();
                setState(() {});
              },
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
            const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  Widget pathField(BuildContext context, TextEditingController controller, String title, String valueToSave, FormFieldValidator<String> validator, VoidCallback onPressed) {
    return ListTile(
      title: Text(title),
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
          )
        ],
      ),
    );
  }
}

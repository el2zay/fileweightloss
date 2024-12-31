import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ffmpegController = TextEditingController(text: getFFmpegPath());
  final _defaultOutputController = TextEditingController(text: GetStorage().read("defaultOutputPath"));
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  @override
  Widget build(BuildContext context) {
    var currentLocale = getLocale(View.of(context).platformDispatcher.locale, WidgetsBinding.instance.platformDispatcher.locales);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.parametres),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
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
                  return AppLocalizations.of(context)!.fichierErreur;
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
                return AppLocalizations.of(context)!.dossierErreur;
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: currentLocale.languageCode,
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                print(value);
                                currentLocale = Locale(value);
                                box.write("language", value);
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'fr',
                              child: Text('Français'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AppLocalizations.of(context)!.redemarrer,
                    style: const TextStyle(fontSize: 15),
                  ),
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
            child: TextFormField(
              controller: controller,
              onFieldSubmitted: (value) {
                if (_formKey.currentState!.validate()) {
                  box.write(valueToSave, value);
                }
              },
              validator: validator,
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
              shape: WidgetStateProperty.all(const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(40)))),
              backgroundColor: WidgetStateProperty.all(Colors.indigo[900]),
            ),
            onPressed: onPressed,
            child: Text(AppLocalizations.of(context)!.explorer),
          ),
        ],
      ),
    );
  }
}

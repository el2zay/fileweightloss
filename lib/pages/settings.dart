import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Paramètres'),
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
              _ffmpegController,
              "Chemin actuel de FFmpeg",
              "ffmpegPath",
              (value) {
                if (value!.isEmpty) {
                  return 'Veuillez entrer un chemin valide';
                } else if (!File(value).existsSync()) {
                  return 'Le fichier n\'existe pas';
                }
                return null;
              },
              () async {
                await pickFfmpeg();
                setState(() {});
              },
            ),
            pathField(_defaultOutputController, "Dossier de sortie par défaut", "defaultOutputPath", (value) {
              if (value != null && value.isNotEmpty && !Directory(value).existsSync()) {
                return 'Le dossier n\'existe pas';
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
          ],
        ),
      ),
    );
  }

  Widget pathField(TextEditingController controller, String title, String valueToSave, FormFieldValidator<String> validator, VoidCallback onPressed) {
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
            child: const Text('Explorer'),
          ),
        ],
      ),
    );
  }
}

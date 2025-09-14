import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fileweightloss/l10n/app_localizations.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:fileweightloss/src/utils/restart_helper.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _ffmpegController = TextEditingController(text: getFFmpegPath());
  final _gsController = TextEditingController(text: getGsPath());
  final _magickController = TextEditingController(text: getMagickPath());
  final box = GetStorage("MyStorage", getStoragePath());
  final _defaultOutputController = TextEditingController(text: GetStorage("MyStorage").read("defaultOutputPath"));
  final _outputNameController = TextEditingController(text: GetStorage("MyStorage").read("outputName"));
  final _formKey = GlobalKey<ShadFormState>();
  int showFinalMessage = 0; // 0 = No, 1 = Success, 2 = Error
  bool alreadyPressed = false;

  final languages = {
    'en': 'English',
    'fr': 'Français',
  };

  @override
  void initState() {
    super.initState();
    saveLogs("SettingsPage initialized");
    isSettingsPage = true;

    saveLogs("Controller values - FFmpeg: '${_ffmpegController.text}', GS: '${_gsController.text}', Magick: '${_magickController.text}'");
    saveLogs("Default output path: '${_defaultOutputController.text}'");
    saveLogs("Output name suffix: '${_outputNameController.text}'");
  }

  @override
  void dispose() {
    saveLogs("SettingsPage disposing");
    isSettingsPage = false;

    _ffmpegController.dispose();
    _gsController.dispose();
    _magickController.dispose();
    _defaultOutputController.dispose();
    _outputNameController.dispose();

    super.dispose();
  }

  //! Trouver une meilleure solution

  // void installer() async {
  //   saveLogs("Starting ImageMagick installation process");

  //   try {
  //     saveLogs("Extracting ImageMagick archive from /Users/elie/7.1.1-47.zip");
  //     final extractResult = await Process.run('tar', [
  //       'xvzf',
  //       '/Users/elie/7.1.1-47.zip',
  //       '-C',
  //       '/Users/elie',
  //     ]);

  //     if (extractResult.exitCode != 0) {
  //       saveLogs('Error during extraction: ${extractResult.stderr}');
  //       return;
  //     }
  //     saveLogs("Archive extracted successfully");

  //     const imageMagickBinPath = '/Users/elie/7.1.1-47/bin';
  //     const imageMagickLibPath = '/Users/elie/7.1.1-47/lib';
  //     final currentPath = Platform.environment['PATH'] ?? '';

  //     saveLogs("ImageMagick paths - Bin: $imageMagickBinPath, Lib: $imageMagickLibPath");

  //     try {
  //       saveLogs("Removing quarantine attribute from magick binary");
  //       await Process.run('xattr', ['-d', 'com.apple.quarantine', '$imageMagickBinPath/magick']);
  //       saveLogs('Quarantine removed for magick');
  //     } catch (e) {
  //       saveLogs('Error removing quarantine for magick: $e');
  //     }

  //     // Remove quarantine from specific dylib files
  //     final dylibFiles = [
  //       "/Users/elie/7.1.1-47/lib/libMagick++-7.Q16HDRI.5.dylib",
  //       "/Users/elie/7.1.1-47/lib/libMagickCore-7.Q16HDRI.10.dylib",
  //       "/Users/elie/7.1.1-47/lib/libMagickWand-7.Q16HDRI.10.dylib"
  //     ];

  //     for (final dylibPath in dylibFiles) {
  //       try {
  //         await Process.run('xattr', ['-d', 'com.apple.quarantine', dylibPath]);
  //         saveLogs("Quarantine removed for: $dylibPath");
  //       } catch (e) {
  //         saveLogs('Error removing quarantine for $dylibPath: $e');
  //       }
  //     }

  //     saveLogs('Attempting to execute magick version command...');
  //     saveLogs("Magick path: $imageMagickBinPath/magick");

  //     try {
  //       final result = await Process.run(
  //         '$imageMagickBinPath/magick',
  //         ['-version'],
  //         environment: {
  //           'PATH': '$imageMagickBinPath:$currentPath',
  //           'DYLD_LIBRARY_PATH': imageMagickLibPath,
  //           'MAGICK_HOME': '/Users/elie/7.1.1-47'
  //         },
  //       );

  //       saveLogs("Magick execution result: $result");
  //       saveLogs('Exit code: ${result.exitCode}');
  //       saveLogs('Stdout: ${result.stdout}');
  //       saveLogs('Stderr: ${result.stderr}');

  //       if (result.exitCode == 0) {
  //         saveLogs('ImageMagick installed successfully: ${result.stdout}');

  //         box.write("magickPath", '$imageMagickBinPath/magick');
  //         _magickController.text = '$imageMagickBinPath/magick';
  //         saveLogs("ImageMagick path saved to storage: ${_magickController.text}");

  //         setState(() {
  //           showFinalMessage = 1;
  //         });
  //       } else {
  //         saveLogs('Error during ImageMagick installation: ${result.stderr}');
  //         setState(() {
  //           showFinalMessage = 2;
  //         });
  //       }
  //     } catch (e) {
  //       saveLogs('Exception during magick execution: $e');
  //       setState(() {
  //         showFinalMessage = 2;
  //       });
  //     }
  //   } catch (e) {
  //     saveLogs('Exception during installation: $e');
  //     setState(() {
  //       showFinalMessage = 2;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    var currentLocale = getLocale(View.of(context).platformDispatcher.locale, WidgetsBinding.instance.platformDispatcher.locales);
    saveLogs("Building SettingsPage with locale: ${currentLocale.languageCode}");

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: () {
            saveLogs("Settings page closed via X button");
            Navigator.pop(context);
          },
        ),
      ),
      body: ShadForm(
        key: _formKey,
        child: ListView(
          children: [
            if (!Platform.isWindows) ...[
              PathField(
                context: context,
                controller: _ffmpegController,
                title: AppLocalizations.of(context)!.currentPath("FFmpeg"),
                valueToSave: "ffmpegPath",
                validator: (value) {
                  if (value!.isEmpty) {
                    saveLogs("FFmpeg path validation failed: empty path");
                    return AppLocalizations.of(context)!.emptyPath;
                  } else if (!File(value).existsSync()) {
                    saveLogs("FFmpeg path validation failed: file doesn't exist at $value");
                    return AppLocalizations.of(context)!.filePathError;
                  }
                  saveLogs("FFmpeg path validation passed: $value");
                  return null;
                },
                onPressed: () async {
                  saveLogs("Opening file picker for FFmpeg binary");
                  await pickBin();
                  setState(() {});
                },
                formKey: _formKey,
                box: box,
                tooltip: AppLocalizations.of(context)!.ffmpegTooltip,
              ),
              PathField(
                context: context,
                controller: _gsController,
                title: AppLocalizations.of(context)!.currentPath("GhostScript"),
                valueToSave: "gsPath",
                validator: (value) {
                  if (value!.isNotEmpty && !File(value).existsSync()) {
                    saveLogs("GhostScript path validation failed: file doesn't exist at $value");
                    return AppLocalizations.of(context)!.filePathError;
                  }
                  saveLogs("GhostScript path validation passed: $value");
                  return null;
                },
                onPressed: () async {
                  saveLogs("Opening file picker for GhostScript binary");
                  await pickBin();
                  setState(() {});
                },
                secondOnPress: () {
                  saveLogs("Opening GhostScript installation dialog");
                  showShadDialog(
                    context: context,
                    builder: (context) {
                      return installationMessage("GhostScript");
                    },
                  );
                },
                formKey: _formKey,
                box: box,
                tooltip: AppLocalizations.of(context)!.tooltipGhostscript,
              ),
              PathField(
                context: context,
                controller: _magickController,
                title: AppLocalizations.of(context)!.currentPath("ImageMagick"),
                valueToSave: "magickPath",
                validator: (value) {
                  if (value!.isNotEmpty && !File(value).existsSync()) {
                    saveLogs("ImageMagick path validation failed: file doesn't exist at $value");
                    return AppLocalizations.of(context)!.filePathError;
                  }
                  saveLogs("ImageMagick path validation passed: $value");
                  return null;
                },
                onPressed: () async {
                  saveLogs("Opening file picker for ImageMagick binary");
                  await pickBin();
                  setState(() {});
                },
                secondOnPress: () {
                  saveLogs("Opening ImageMagick installation dialog");
                  showShadDialog(
                    context: context,
                    builder: (context) {
                      return installationMessage("ImageMagick");
                    },
                  );
                },
                formKey: _formKey,
                box: box,
                tooltip: AppLocalizations.of(context)!.tooltipImageMagick,
              ),
            ],
            PathField(
              context: context,
              controller: _defaultOutputController,
              title: AppLocalizations.of(context)!.defaultOutputDirectory,
              valueToSave: "defaultOutputPath",
              validator: (value) {
                if (value != null && value.isNotEmpty && !Directory(value).existsSync()) {
                  saveLogs("Default output directory validation failed: directory doesn't exist at $value");
                  return AppLocalizations.of(context)!.dirPathError;
                } else if (value == null || value.isEmpty) {
                  saveLogs("Default output directory cleared");
                  box.remove("defaultOutputPath");
                }
                saveLogs("Default output directory validation passed: $value");
                return null;
              },
              onPressed: () async {
                saveLogs("Opening directory picker for default output");
                final dirPath = await getDirectoryPath();
                if (dirPath != null) {
                  _defaultOutputController.text = dirPath;
                  box.write("defaultOutputPath", dirPath);
                  saveLogs("Default output directory set to: $dirPath");
                  setState(() {});
                } else {
                  saveLogs("No directory selected for default output");
                }
              },
              formKey: _formKey,
              box: box,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: settingsSwitch(AppLocalizations.of(context)!.changeCompressedName, "changeOutputName"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: ShadInput(
                      enabled: box.read("changeOutputName") ?? false,
                      readOnly: true,
                      placeholder: const Text("Nom du fichier"),
                      placeholderAlignment: Alignment.center,
                    ),
                  ),
                  Expanded(
                    child: ShadInputFormField(
                      enabled: box.read("changeOutputName") ?? false,
                      controller: _outputNameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[<>:"/\\|?*\x00-\x1F]')),
                        FilteringTextInputFormatter.deny(RegExp(r'[\x7F-\xFF]')),
                        FilteringTextInputFormatter.deny(RegExp(r"[']")),
                      ],
                      onSubmitted: (value) {
                        saveLogs("Output name submitted: '$value'");
                        if (value.isEmpty) {
                          saveLogs("Empty output name, disabling changeOutputName");
                          box.write("changeOutputName", false);
                        }
                        if (_formKey.currentState!.saveAndValidate()) {
                          box.write("outputName", _outputNameController.text);
                          saveLogs("Output name saved: '${_outputNameController.text}'");
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: ShadInput(
                      enabled: box.read("changeOutputName") ?? false,
                      readOnly: true,
                      placeholder: const Text("Extension"),
                      textAlign: TextAlign.center,
                      placeholderAlignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              title: Text("Efficacité de compression minimale requise : ${box.read("minCompression")}%"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  ShadSlider(
                    initialValue: box.read("minCompression")?.toDouble(),
                    min: 1.0,
                    max: 80.0,
                    divisions: 79,
                    onChanged: (value) {
                      saveLogs("Minimum compression changed to ${value.toInt()}%");
                      setState(() {
                        box.write("minCompression", value.toInt());
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text("Si la compression est inférieure à ${box.read("minCompression")}%, le fichier ne sera pas compressé.",
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              title: Text(AppLocalizations.of(context)!.language),
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
                          saveLogs("Language changed from ${currentLocale.languageCode} to $value");
                          setState(() {
                            currentLocale = Locale(value);
                            box.write("language", value);
                          });

                          saveLogs("Showing restart dialog for language change");
                          showShadDialog(
                            context: context,
                            builder: (context) {
                              return ShadDialog(
                                title: Text(AppLocalizations.of(context)!.restartRequired),
                                description: Text(AppLocalizations.of(context)!.restartNowQuestion),
                                actions: [
                                  ShadButton(
                                    child: Text(AppLocalizations.of(context)!.cancel),
                                    onPressed: () {
                                      saveLogs("Restart cancelled");
                                      Navigator.pop(context);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ShadButton.outline(
                                    child: Text(AppLocalizations.of(context)!.restart),
                                    onPressed: () {
                                      saveLogs("Restart confirmed, restarting app");
                                      Navigator.pop(context);
                                      RestartHelper.restartApp();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.restartRequired,
                    style: const TextStyle(fontSize: 14),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: settingsSwitch(AppLocalizations.of(context)!.checkUpdates, "checkUpdates"),
            ),
            const Divider(
              color: Colors.white12,
            ),
            const SizedBox(height: 15),
            ListTile(
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${box.read("totalFiles")} ${AppLocalizations.of(context)!.processedFiles}", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 5),
                  Text("${formatSize(box.read("totalSize"))} ${AppLocalizations.of(context)!.saved}", style: const TextStyle(fontSize: 15)),
                ],
              ),
              trailing: ShadButton.outline(
                  child: Text(AppLocalizations.of(context)!.reset),
                  onPressed: () {
                    saveLogs("Resetting statistics - Files: ${box.read("totalFiles")}, Size: ${box.read("totalSize")}");
                    box.write("totalFiles", 0);
                    box.write("totalSize", 0);
                    saveLogs("Statistics reset to 0");
                    setState(() {});
                  }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShadTooltip(
                  builder: (context) => Text(AppLocalizations.of(context)!.buyMeCoffee),
                  child: IconButton(
                      onPressed: () {
                        saveLogs("Opening Ko-fi donation link");
                        openInBrowser("https://ko-fi.com/el2zay");
                      },
                      icon: const Icon(LucideIcons.coffee, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => Text(AppLocalizations.of(context)!.githubRepository),
                  child: IconButton(
                      onPressed: () {
                        saveLogs("Opening GitHub repository");
                        openInBrowser("https://github.com/el2zay/fileweightloss");
                      },
                      icon: const Icon(LucideIcons.github, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => const Text("Twitter: el2zay"),
                  child: IconButton(
                      onPressed: () {
                        saveLogs("Opening Twitter profile");
                        openInBrowser("https://x.com/el2zay/");
                      },
                      icon: const Icon(LucideIcons.twitter, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => const Text("Telegram: el2zay"),
                  child: IconButton(
                      onPressed: () {
                        saveLogs("Opening Telegram profile");
                        openInBrowser("https://t.me/el2zay/");
                      },
                      icon: const Icon(LucideIcons.send, size: 23)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget settingsSwitch(String title, String valueToSave) {
    return ListTile(
      title: Text(title),
      trailing: Transform.scale(
        scale: Platform.isMacOS ? 0.70 : 0.75,
        child: Switch.adaptive(
          value: box.read(valueToSave) ?? false,
          thumbColor: WidgetStateProperty.resolveWith((states) => Colors.black),
          activeColor: Colors.white,
          activeTrackColor: Colors.white,
          onChanged: (value) {
            saveLogs("Settings switch toggled: $valueToSave = $value");
            setState(() {
              box.write(valueToSave, value);
            });
          },
        ),
      ),
    );
  }

  Widget finalMessage(context, name, error) {
    return Column(
      children: [
        Icon(
          error ? CupertinoIcons.xmark_circle : CupertinoIcons.check_mark_circled_solid,
          color: error == true ? Colors.red : CupertinoColors.systemGreen,
          size: 50,
        ),
        const SizedBox(height: 10),
        Text(!error ? AppLocalizations.of(context)!.installationSuccess(name) : AppLocalizations.of(context)!.installationError(name),
            style: const TextStyle(fontSize: 17, color: Colors.white)),
        const SizedBox(height: 10),
        Text(
            !error && name == "GhostScript"
                ? AppLocalizations.of(context)!.gsSuccess
                : !error && name == "ImageMagick"
                    ? AppLocalizations.of(context)!.magickSuccess
                    : AppLocalizations.of(context)!.installationErrorMessage,
            style: const TextStyle(fontSize: 15, color: Colors.white70))
      ],
    );
  }

  Widget installationMessage(name) {
    var brewPath = "";
    if (Platform.isMacOS) {
      saveLogs("Checking for Homebrew installation");
      final result = Process.runSync("which", ["brew"]);

      if (result.exitCode == 0) {
        brewPath = result.stdout.trim();
        saveLogs("Homebrew found at: $brewPath");
      } else {
        saveLogs("Homebrew not found in PATH");
      }
    }

    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return ShadDialog(
          title: Text("${AppLocalizations.of(context)!.install} $name"),
          description: showFinalMessage == 0 && brewPath.isEmpty
              ? SelectableText.rich(
                  TextSpan(
                    style: const TextStyle(color: Colors.white70),
                    children: [
                      if (!(name == "ImageMagick" && Platform.isMacOS)) ...[
                        TextSpan(text: AppLocalizations.of(context)!.toInstall(name)),
                        TextSpan(
                          text: AppLocalizations.of(context)!.here,
                          style: const TextStyle(decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              String downloadUrl = "";
                              if (Platform.isMacOS) {
                                downloadUrl = name == "GhostScript" ? "https://files.bassinecorp.fr/fwl/bin/Ghostscript-10.04.0.pkg" : "";
                              } else if (Platform.isWindows) {
                                downloadUrl = name == "GhostScript"
                                    ? "https://files.bassinecorp.fr/fwl/bin/gs10040w64.exe"
                                    : "https://files.bassinecorp.fr/fwl/bin/ImageMagick-7.1.1-47-Q16-HDRI-x64-dll.exe";
                              } else if (Platform.isLinux) {
                                downloadUrl = name == "GhostScript"
                                    ? "https://files.bassinecorp.fr/fwl/bin/gs_10.04.0_amd64_snap.tar"
                                    : "https://imagemagick.org/archive/binaries/magick";
                              }
                              saveLogs("Opening download URL for $name: $downloadUrl");
                              openInBrowser(downloadUrl);
                            },
                        ),
                        const TextSpan(text: " "),
                      ],
                      if (name == "GhostScript" || (name == "ImageMagick" && Platform.isWindows))
                        TextSpan(text: AppLocalizations.of(context)!.installGs1MagickWindows)
                      else if (name == "ImageMagick" && Platform.isLinux)
                        TextSpan(text: AppLocalizations.of(context)!.installMagickLinux)
                      else if (name == "ImageMagick" && Platform.isMacOS)
                        TextSpan(text: AppLocalizations.of(context)!.installMagickMacos),
                    ],
                  ),
                )
              : showFinalMessage == 0 && brewPath.isNotEmpty
                  ? SelectableText(AppLocalizations.of(context)!.brewMessage(name, name.toLowerCase()))
                  : showFinalMessage == 1
                      ? finalMessage(context, name, false)
                      : finalMessage(context, name, true),
          actions: [
            ShadButton(
              child: const Text('OK'),
              onPressed: () {
                if (alreadyPressed) {
                  saveLogs("Closing installation dialog for $name");
                  Navigator.pop(context);
                  setStateDialog(() {
                    alreadyPressed = false;
                    showFinalMessage = 0;
                  });
                } else {
                  saveLogs("Checking installation status for $name");
                  setStateDialog(() {
                    alreadyPressed = true;
                    if (name == "GhostScript") {
                      _gsController.text = getGsPath(true);
                      saveLogs("Updated GhostScript path: '${_gsController.text}'");
                    } else {
                      _magickController.text = getMagickPath(true);
                      saveLogs("Updated ImageMagick path: '${_magickController.text}'");
                    }

                    if (name == "GhostScript" && _gsController.text.isEmpty) {
                      saveLogs("GhostScript installation failed - path is empty");
                      showFinalMessage = 2;
                    } else if (name == "ImageMagick" && _magickController.text.isEmpty) {
                      saveLogs("ImageMagick installation failed - path is empty");
                      showFinalMessage = 2;
                    } else if ((name == "GhostScript" && _gsController.text.isNotEmpty) ||
                        (name == "ImageMagick" && _magickController.text.isNotEmpty)) {
                      saveLogs("$name installation successful");
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
  }

  String formatSize(int bytes) {
    String result;
    if (bytes < 1024) {
      result = '$bytes o';
    } else {
      final kb = bytes / 1024;
      if (kb < 1024) {
        result = '${kb.toStringAsFixed(2)} Ko';
      } else {
        final mb = kb / 1024;
        if (mb < 1024) {
          result = '${mb.toStringAsFixed(2)} Mo';
        } else {
          final gb = mb / 1024;
          result = '${gb.toStringAsFixed(2)} Go';
        }
      }
    }
    return result;
  }
}

class PathField extends StatelessWidget {
  final BuildContext context;
  final TextEditingController controller;
  final String title;
  final String valueToSave;
  final FormFieldValidator<String> validator;
  final VoidCallback onPressed;
  final VoidCallback? secondOnPress;
  final GlobalKey<ShadFormState> formKey;
  final GetStorage box;
  final String? tooltip;

  const PathField({
    super.key,
    required this.context,
    required this.controller,
    required this.title,
    required this.valueToSave,
    required this.validator,
    required this.onPressed,
    this.secondOnPress,
    required this.formKey,
    required this.box,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          tooltip != null
              ? ShadTooltip(
                  builder: (context) => Text(tooltip!, textAlign: TextAlign.center),
                  child: IconButton(
                      onPressed: () {
                        saveLogs("Tooltip shown for: $title");
                      },
                      icon: const Icon(
                        LucideIcons.circleQuestionMark,
                        size: 20,
                        color: Colors.white,
                      )),
                )
              : const SizedBox(width: 0),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ShadInputFormField(
                  controller: controller,
                  onSubmitted: (value) {
                    FocusScope.of(context).unfocus();
                    saveLogs("Path field submitted for $valueToSave: '$value'");
                    if (value.isEmpty) {
                      box.writeIfNull(valueToSave, value);
                      saveLogs("Path saved to storage: $valueToSave = '$value'");
                    }
                  },
                  onEditingComplete: () {
                    saveLogs("Path field editing completed for $valueToSave: '${controller.text}'");
                    if (formKey.currentState!.saveAndValidate()) {
                      box.write(valueToSave, controller.text);
                      saveLogs("Path saved to storage: $valueToSave = '${controller.text}'");
                    }
                  },
                  validator: validator,
                ),
              ),
              const SizedBox(width: 20),
              ShadButton.outline(
                onPressed: () {
                  saveLogs("Browse button pressed for: $title");
                  onPressed();
                },
                child: Text(AppLocalizations.of(context)!.browse),
              ),
              const SizedBox(width: 5),
              if (secondOnPress != null && (controller.text.isEmpty || !File(controller.text).existsSync()))
                ShadButton.outline(
                  onPressed: () {
                    saveLogs("Install button pressed for: $title");
                    secondOnPress!();
                  },
                  child: Text(AppLocalizations.of(context)!.install),
                )
            ],
          ),
        ],
      ),
    );
  }
}

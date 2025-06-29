import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:fileweightloss/src/utils/restart_helper.dart';
import 'package:fileweightloss/src/widgets/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    logarte.log("SettingsPage initialized");
    isSettingsPage = true;

    logarte.log("Controller values - FFmpeg: '${_ffmpegController.text}', GS: '${_gsController.text}', Magick: '${_magickController.text}'");
    logarte.log("Default output path: '${_defaultOutputController.text}'");
    logarte.log("Output name suffix: '${_outputNameController.text}'");
  }

  @override
  void dispose() {
    logarte.log("SettingsPage disposing");
    isSettingsPage = false;

    _ffmpegController.dispose();
    _gsController.dispose();
    _magickController.dispose();
    _defaultOutputController.dispose();
    _outputNameController.dispose();

    super.dispose();
  }

  void installer() async {
    logarte.log("Starting ImageMagick installation process");

    try {
      logarte.log("Extracting ImageMagick archive from /Users/elie/7.1.1-47.zip");
      final extractResult = await Process.run('tar', [
        'xvzf',
        '/Users/elie/7.1.1-47.zip',
        '-C',
        '/Users/elie',
      ]);

      if (extractResult.exitCode != 0) {
        logarte.log('Error during extraction: ${extractResult.stderr}');
        return;
      }
      logarte.log("Archive extracted successfully");

      const imageMagickBinPath = '/Users/elie/7.1.1-47/bin';
      const imageMagickLibPath = '/Users/elie/7.1.1-47/lib';
      final currentPath = Platform.environment['PATH'] ?? '';

      logarte.log("ImageMagick paths - Bin: $imageMagickBinPath, Lib: $imageMagickLibPath");

      try {
        logarte.log("Removing quarantine attribute from magick binary");
        await Process.run('xattr', [
          '-d',
          'com.apple.quarantine',
          '$imageMagickBinPath/magick'
        ]);
        logarte.log('Quarantine removed for magick');
      } catch (e) {
        logarte.log('Error removing quarantine for magick: $e');
      }

      // Remove quarantine from specific dylib files
      final dylibFiles = [
        "/Users/elie/7.1.1-47/lib/libMagick++-7.Q16HDRI.5.dylib",
        "/Users/elie/7.1.1-47/lib/libMagickCore-7.Q16HDRI.10.dylib",
        "/Users/elie/7.1.1-47/lib/libMagickWand-7.Q16HDRI.10.dylib"
      ];

      for (final dylibPath in dylibFiles) {
        try {
          await Process.run('xattr', [
            '-d',
            'com.apple.quarantine',
            dylibPath
          ]);
          logarte.log("Quarantine removed for: $dylibPath");
        } catch (e) {
          logarte.log('Error removing quarantine for $dylibPath: $e');
        }
      }

      logarte.log('Attempting to execute magick version command...');
      logarte.log("Magick path: $imageMagickBinPath/magick");

      try {
        final result = await Process.run(
          '$imageMagickBinPath/magick',
          [
            '-version'
          ],
          environment: {
            'PATH': '$imageMagickBinPath:$currentPath',
            'DYLD_LIBRARY_PATH': imageMagickLibPath,
            'MAGICK_HOME': '/Users/elie/7.1.1-47'
          },
        );

        logarte.log("Magick execution result: $result");
        logarte.log('Exit code: ${result.exitCode}');
        logarte.log('Stdout: ${result.stdout}');
        logarte.log('Stderr: ${result.stderr}');

        if (result.exitCode == 0) {
          logarte.log('ImageMagick installed successfully: ${result.stdout}');

          box.write("magickPath", '$imageMagickBinPath/magick');
          _magickController.text = '$imageMagickBinPath/magick';
          logarte.log("ImageMagick path saved to storage: ${_magickController.text}");

          setState(() {
            showFinalMessage = 1;
          });
        } else {
          logarte.log('Error during ImageMagick installation: ${result.stderr}');
          setState(() {
            showFinalMessage = 2;
          });
        }
      } catch (e) {
        logarte.log('Exception during magick execution: $e');
        setState(() {
          showFinalMessage = 2;
        });
      }
    } catch (e) {
      logarte.log('Exception during installation: $e');
      setState(() {
        showFinalMessage = 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentLocale = getLocale(View.of(context).platformDispatcher.locale, WidgetsBinding.instance.platformDispatcher.locales);
    logarte.log("Building SettingsPage with locale: ${currentLocale.languageCode}");

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
            logarte.log("Settings page closed via X button");
            Navigator.pop(context);
          },
        ),
      ),
      body: ShadForm(
        key: _formKey,
        child: ListView(
          children: [
            if (!Platform.isWindows) ...[
              pathField(
                context,
                _ffmpegController,
                AppLocalizations.of(context)!.currentPath("FFmpeg"),
                "ffmpegPath",
                (value) {
                  if (value!.isEmpty) {
                    logarte.log("FFmpeg path validation failed: empty path");
                    return AppLocalizations.of(context)!.emptyPath;
                  } else if (!File(value).existsSync()) {
                    logarte.log("FFmpeg path validation failed: file doesn't exist at $value");
                    return AppLocalizations.of(context)!.filePathError;
                  }
                  logarte.log("FFmpeg path validation passed: $value");
                  return null;
                },
                () async {
                  logarte.log("Opening file picker for FFmpeg binary");
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
                    logarte.log("GhostScript path validation failed: file doesn't exist at $value");
                    return AppLocalizations.of(context)!.filePathError;
                  }
                  logarte.log("GhostScript path validation passed: $value");
                  return null;
                },
                () async {
                  logarte.log("Opening file picker for GhostScript binary");
                  await pickBin();
                  setState(() {});
                },
                () {
                  logarte.log("Opening GhostScript installation dialog");
                  showShadDialog(
                    context: context,
                    builder: (context) {
                      return installationMessage("GhostScript");
                    },
                  );
                },
                AppLocalizations.of(context)!.tooltipGhostscript,
              ),
              pathField(
                context,
                _magickController,
                AppLocalizations.of(context)!.currentPath("ImageMagick"),
                "magickPath",
                (value) {
                  if (value!.isNotEmpty && !File(value).existsSync()) {
                    logarte.log("ImageMagick path validation failed: file doesn't exist at $value");
                    return AppLocalizations.of(context)!.filePathError;
                  }
                  logarte.log("ImageMagick path validation passed: $value");
                  return null;
                },
                () async {
                  logarte.log("Opening file picker for ImageMagick binary");
                  await pickBin();
                  setState(() {});
                },
                () {
                  logarte.log("Opening ImageMagick installation dialog");
                  showShadDialog(
                    context: context,
                    builder: (context) {
                      return installationMessage("ImageMagick");
                    },
                  );
                },
                AppLocalizations.of(context)!.tooltipImageMagick,
              ),
            ],
            pathField(
              context,
              _defaultOutputController,
              AppLocalizations.of(context)!.defaultOutputDirectory,
              "defaultOutputPath",
              (value) {
                if (value != null && value.isNotEmpty && !Directory(value).existsSync()) {
                  logarte.log("Default output directory validation failed: directory doesn't exist at $value");
                  return AppLocalizations.of(context)!.dirPathError;
                } else if (value == null || value.isEmpty) {
                  logarte.log("Default output directory cleared");
                  box.remove("defaultOutputPath");
                }
                logarte.log("Default output directory validation passed: $value");
                return null;
              },
              () async {
                logarte.log("Opening directory picker for default output");
                final dirPath = await getDirectoryPath();
                if (dirPath != null) {
                  _defaultOutputController.text = dirPath;
                  box.write("defaultOutputPath", dirPath);
                  logarte.log("Default output directory set to: $dirPath");
                  setState(() {});
                } else {
                  logarte.log("No directory selected for default output");
                }
              },
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
                        logarte.log("Output name submitted: '$value'");
                        if (value.isEmpty) {
                          logarte.log("Empty output name, disabling changeOutputName");
                          box.write("changeOutputName", false);
                        }
                        if (_formKey.currentState!.saveAndValidate()) {
                          box.write("outputName", _outputNameController.text);
                          logarte.log("Output name saved: '${_outputNameController.text}'");
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
                      logarte.log("Minimum compression changed to ${value.toInt()}%");
                      setState(() {
                        box.write("minCompression", value.toInt());
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text("Si la compression est inférieure à ${box.read("minCompression")}%, le fichier ne sera pas compressé.", style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
                          logarte.log("Language changed from ${currentLocale.languageCode} to $value");
                          setState(() {
                            currentLocale = Locale(value);
                            box.write("language", value);
                          });

                          logarte.log("Showing restart dialog for language change");
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
                                      logarte.log("Restart cancelled");
                                      Navigator.pop(context);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ShadButton.outline(
                                    child: Text(AppLocalizations.of(context)!.restart),
                                    onPressed: () {
                                      logarte.log("Restart confirmed, restarting app");
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
                    logarte.log("Resetting statistics - Files: ${box.read("totalFiles")}, Size: ${box.read("totalSize")}");
                    box.write("totalFiles", 0);
                    box.write("totalSize", 0);
                    logarte.log("Statistics reset to 0");
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
                        logarte.log("Opening Ko-fi donation link");
                        openInBrowser("https://ko-fi.com/el2zay");
                      },
                      icon: const Icon(LucideIcons.coffee, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => Text(AppLocalizations.of(context)!.githubRepository),
                  child: IconButton(
                      onPressed: () {
                        logarte.log("Opening GitHub repository");
                        openInBrowser("https://github.com/el2zay/fileweightloss");
                      },
                      icon: const Icon(LucideIcons.github, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => const Text("Twitter: el2zay"),
                  child: IconButton(
                      onPressed: () {
                        logarte.log("Opening Twitter profile");
                        openInBrowser("https://x.com/el2zay/");
                      },
                      icon: const Icon(LucideIcons.twitter, size: 25)),
                ),
                ShadTooltip(
                  builder: (context) => const Text("Telegram: el2zay"),
                  child: IconButton(
                      onPressed: () {
                        logarte.log("Opening Telegram profile");
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
                      onPressed: () {
                        logarte.log("Tooltip shown for: $title");
                      },
                      icon: const Icon(
                        LucideIcons.circleHelp,
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
                  onEditingComplete: () {
                    logarte.log("Path field editing completed for $valueToSave: '${controller.text}'");
                    if (_formKey.currentState!.saveAndValidate()) {
                      box.write(valueToSave, controller.text);
                      logarte.log("Path saved to storage: $valueToSave = '${controller.text}'");
                    }
                  },
                  validator: validator,
                ),
              ),
              const SizedBox(width: 20),
              ShadButton.outline(
                onPressed: () {
                  logarte.log("Browse button pressed for: $title");
                  onPressed();
                },
                child: Text(AppLocalizations.of(context)!.browse),
              ),
              const SizedBox(width: 5),
              if (secondOnPress != null)
                ShadButton.outline(
                  onPressed: () {
                    logarte.log("Install button pressed for: $title");
                    secondOnPress();
                  },
                  child: Text(AppLocalizations.of(context)!.install),
                )
            ],
          ),
        ],
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
            logarte.log("Settings switch toggled: $valueToSave = $value");
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
        Text(!error ? AppLocalizations.of(context)!.installationSuccess(name) : AppLocalizations.of(context)!.installationError(name), style: const TextStyle(fontSize: 17, color: Colors.white)),
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
      logarte.log("Checking for Homebrew installation");
      final result = Process.runSync("which", [
        "brew"
      ]);

      if (result.exitCode == 0) {
        brewPath = result.stdout.trim();
        logarte.log("Homebrew found at: $brewPath");
      } else {
        logarte.log("Homebrew not found in PATH");
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
                      TextSpan(text: AppLocalizations.of(context)!.toInstall(name)),
                      TextSpan(
                        text: AppLocalizations.of(context)!.here,
                        style: const TextStyle(decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            String downloadUrl = "";
                            if (Platform.isMacOS) {
                              downloadUrl = name == "GhostScript" ? "https://files.bassinecorp.fr/fwl/bin/Ghostscript-10.04.0.pkg" : "https://files.bassinecorp.fr/fwl/bin/ImageMagick-x86_64-apple-darwin20.1.0.tar";
                            } else if (Platform.isWindows) {
                              downloadUrl = name == "GhostScript" ? "https://files.bassinecorp.fr/fwl/bin/gs10040w64.exe" : "https://files.bassinecorp.fr/fwl/bin/ImageMagick-7.1.1-47-Q16-HDRI-x64-dll.exe";
                            } else if (Platform.isLinux) {
                              downloadUrl = name == "GhostScript" ? "https://files.bassinecorp.fr/fwl/bin/gs_10.04.0_amd64_snap.tar" : "https://imagemagick.org/archive/binaries/magick";
                            }
                            logarte.log("Opening download URL for $name: $downloadUrl");
                            openInBrowser(downloadUrl);
                          },
                      ),
                      const TextSpan(text: " "),
                      if (name == "GhostScript" || (name == "ImageMagick" && Platform.isWindows)) TextSpan(text: AppLocalizations.of(context)!.installGs1MagickWindows) else if (name == "ImageMagick" && Platform.isLinux) TextSpan(text: AppLocalizations.of(context)!.installMagickLinux)
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
                  logarte.log("Closing installation dialog for $name");
                  Navigator.pop(context);
                  setStateDialog(() {
                    alreadyPressed = false;
                    showFinalMessage = 0;
                  });
                } else {
                  logarte.log("Checking installation status for $name");
                  setStateDialog(() {
                    alreadyPressed = true;
                    if (name == "GhostScript") {
                      _gsController.text = getGsPath(true);
                      logarte.log("Updated GhostScript path: '${_gsController.text}'");
                    } else {
                      _magickController.text = getMagickPath(true);
                      logarte.log("Updated ImageMagick path: '${_magickController.text}'");
                    }

                    if (name == "GhostScript" && _gsController.text.isEmpty) {
                      logarte.log("GhostScript installation failed - path is empty");
                      showFinalMessage = 2;
                    } else if (name == "ImageMagick" && _magickController.text.isEmpty) {
                      logarte.log("ImageMagick installation failed - path is empty");
                      // TODO voir pour macOS
                      // installer();
                      showFinalMessage = 2;
                    } else if ((name == "GhostScript" && _gsController.text.isNotEmpty) || (name == "ImageMagick" && _magickController.text.isNotEmpty)) {
                      logarte.log("$name installation successful");
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

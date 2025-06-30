import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:fileweightloss/pages/home.dart';
import 'package:fileweightloss/src/utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_storage/get_storage.dart';

final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
final ValueNotifier<String> outputPathNotifier = ValueNotifier<String>("");
int totalSecondsInt = 0;
bool isCompressionCancelled = false;
final box = GetStorage("MyStorage", getStoragePath());

Future<int> compressMedia(BuildContext context, String filePath, String name, String fileExt, int originalSize, int quality, int fps, bool delete, String outputDir, String? cover, {Function(double)? onProgress}) async {
  saveLogs("Starting media compression - File: $filePath, Quality: $quality, FPS: $fps, Delete original: $delete");
  final localizations = AppLocalizations.of(context);

  String? parameterCrf, parameterR, parameterB;
  String? soundQuality;
  double duration = 0;
  isCompressionCancelled = false;
  int fileSize = 0;

  if (quality == 0) {
    parameterCrf = "23";
    parameterR = "60";
    parameterB = "1000";
    soundQuality = "2";
  } else if (quality == 1) {
    parameterCrf = "28";
    parameterR = "60";
    parameterB = "750";
    soundQuality = "4";
  } else if (quality == 2) {
    parameterCrf = "32";
    parameterR = "30";
    parameterB = "500";
    soundQuality = "6";
  } else if (quality == 3) {
    parameterCrf = "36";
    parameterR = "24";
    parameterB = "250";
    soundQuality = "8";
  }

  saveLogs("Quality parameters - CRF: $parameterCrf, R: $parameterR, B: $parameterB, Sound: $soundQuality");

  List<String> cmdArgs = [
    ffmpegPath,
    "-i",
    filePath,
    if (fileExt == "mp3") ...[
      if (cover != null) ...[
        "-i",
        cover,
        "-map",
        "0:a",
        "-map",
        "1",
        "-c:a",
        "libmp3lame",
        "-q:a",
        soundQuality ?? "0",
      ] else ...[
        "-vn",
        "-acodec",
        "libmp3lame",
        "-q:a",
        soundQuality ?? "0",
      ],
    ] else if (fileExt == 'gif') ...[
      "-vf",
      "fps=$fps",
    ] else ...[
      "-c:a",
      "copy",
    ],
  ];

  String outputPath = "$outputDir/$name.$fileExt";
  outputPath = getUniqueFileName(outputPath);
  outputPathNotifier.value = outputPath;
  saveLogs("Output path determined: $outputPath");

  if (quality == -1) {
    cmdArgs.addAll([
      if (fileExt != 'mp3' && fileExt != 'gif') ...[
        "-c:v",
        "copy",
      ],
      "-y",
      outputPath,
    ]);
    saveLogs("Using copy mode (quality -1)");
  } else {
    cmdArgs.addAll([
      if (fileExt != 'gif') ...[
        "-vcodec",
        "libx264",
      ],
      if (fileExt != 'mp3') ...[
        "-preset",
        "slower",
        "-crf",
        parameterCrf!,
        "-r",
        parameterR!,
        "-b:v",
        "${parameterB}k",
      ],
      "-y",
      outputPath,
    ]);
    saveLogs("Using compression mode with parameters");
  }

  saveLogs("FFmpeg command: ${cmdArgs.join(' ')}");

  try {
    var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
    saveLogs("FFmpeg process started successfully");

    bool hasAudio = false;
    process.stderr.transform(utf8.decoder).listen((output) {
      if (isCompressionCancelled) return;

      if (fileExt == "mp3") {
        if (output.contains('Stream') && output.contains('Audio:')) {
          hasAudio = true;
          saveLogs("Audio stream detected for MP3 conversion");
        } else {
          return;
        }
      }
      var regexDuration = RegExp(r'Duration: ([\d:.]+)');
      var matchDuration = regexDuration.firstMatch(output);
      if (matchDuration != null) {
        final durationValue = matchDuration.group(1);
        var time = durationValue!.split(':');
        var hours = int.parse(time[0]);
        var minutes = int.parse(time[1]);
        var seconds = double.parse(time[2]);
        duration = (hours * 3600) + (minutes * 60) + seconds;
        saveLogs("Media duration detected: ${duration}s");
      }
      var regexTime = RegExp(r'time=([\d:.]+)');
      var matchTime = regexTime.firstMatch(output);
      if (matchTime != null) {
        final timeValue = matchTime.group(1);
        var time = timeValue!.split(':');
        var hours = int.parse(time[0]);
        var minutes = int.parse(time[1]);
        var seconds = double.parse(time[2]);
        var totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
        progressNotifier.value = (totalSeconds / duration);
        if (onProgress != null && !isCompressionCancelled) {
          onProgress(progressNotifier.value);
        }
      }
    });

    await process.exitCode;
    saveLogs("FFmpeg process completed");

    if (!hasAudio && fileExt == "mp3") {
      saveLogs("No audio track found in the file for MP3 conversion");
      errors.addAll({
        filePath: localizations!.noAudioTrackFound,
      });
      return -1;
    }

    File compressedFile = File(outputPath);
    if (await compressedFile.exists()) {
      try {
        fileSize = (quality == -1) ? 0 : compressedFile.lengthSync();
        saveLogs("Compressed file size: $fileSize bytes (original: $originalSize bytes)");
      } catch (e) {
        saveLogs('Error retrieving file size: $e');
        errors.addAll({
          filePath: localizations!.compressionError(e.toString()),
        });
        return -1;
      }
    } else if (!isCompressionCancelled) {
      saveLogs('Compressed file not found: ${compressedFile.path}');
      errors.addAll({
        filePath: localizations!.fileNotFoundAfterCompression,
      });
      return -1;
    }

    if (fileSize < originalSize * box.read("minCompression") / 100) {
      saveLogs("Compression successful (saved ${originalSize - fileSize} bytes)");
      if (delete) {
        File originalFile = File(filePath);
        await originalFile.delete();
        saveLogs("Original file deleted: $filePath");
      }
    } else {
      fileSize = originalSize;
      saveLogs("Compression not effective enough, keeping original file");
      errors.addAll({
        filePath: localizations!.compressionNotEffective,
      });
      await compressedFile.delete();
    }

    return fileSize;
  } catch (e) {
    saveLogs('Error during media compression: $e');
    errors.addAll({
      filePath: localizations!.compressionError(e.toString()),
    });
    return -1;
  }
}

Future<int> compressPdf(BuildContext context, String filePath, String name, int size, String outputDir, int quality, {Function(double)? onProgress}) async {
  saveLogs("Starting PDF compression - File: $filePath, Quality: $quality, Size: $size bytes");

  final localizations = AppLocalizations.of(context);
  int page = 0;
  String? parameterQuality;

  if (quality == 0) {
    parameterQuality = "prepress";
  } else if (quality == 1) {
    parameterQuality = "printer";
  } else if (quality == 2) {
    parameterQuality = "ebook";
  } else if (quality == 3) {
    parameterQuality = "screen";
  }

  saveLogs("PDF quality parameter: $parameterQuality");

  final filePathForCmd = filePath.replaceAll("\\", "/");

  List<String> cmdArgsPage = [
    gsPath,
    "-q",
    "-dNOSAFER",
    "-dNODISPLAY",
    "--permit-file-read=$filePathForCmd",
    "-c",
    "($filePathForCmd) (r) file runpdfbegin pdfpagecount = quit",
  ];

  saveLogs("Getting PDF page count with command: ${cmdArgsPage.join(' ')}");

  int totalPages = 0;
  try {
    var processPages = await Process.start(cmdArgsPage[0], cmdArgsPage.sublist(1));
    processPages.stdout.transform(utf8.decoder).listen((output) {
      String trimmedOutput = output.trim();
      if (RegExp(r'^\d+$').hasMatch(trimmedOutput)) {
        totalPages = int.parse(trimmedOutput);
        saveLogs("PDF has $totalPages pages");
      } else {
        saveLogs("Page count output is not a number: $trimmedOutput");
      }
    });

    await processPages.exitCode;
  } catch (e) {
    errors.addAll({
      filePath: localizations!.compressionError(e.toString()),
    });
    saveLogs('Error getting PDF page count: $e');
  }

  String outputPath = "$outputDir/$name.pdf";
  outputPath = getUniqueFileName(outputPath);
  outputPathNotifier.value = outputPath;
  saveLogs("PDF output path: $outputPath");

  List<String> cmdArgs = [
    gsPath,
    "-sDEVICE=pdfwrite",
    "-dCompatibilityLevel=1.4",
    "-dPDFSETTINGS=/$parameterQuality",
    "-dNOPAUSE",
    "-dBATCH",
    "-sOutputFile=$outputPath",
    filePath,
  ];

  saveLogs("PDF compression command: ${cmdArgs.join(' ')}");

  try {
    var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
    saveLogs("Ghostscript process started successfully");

    process.stdout.transform(utf8.decoder).listen((output) {
      if (output.contains("Page")) {
        page++;
        progressNotifier.value = totalPages > 0 ? (page / totalPages) : 0;
        if (onProgress != null) {
          onProgress(progressNotifier.value);
        }
        saveLogs("Processing page $page/$totalPages");
      }
    });

    await process.exitCode;
    saveLogs("Ghostscript process completed");

    File compressedFile = File(outputPath);
    if (await compressedFile.exists()) {
      try {
        final compressedSize = compressedFile.lengthSync();
        saveLogs("PDF compression completed - Original: $size bytes, Compressed: $compressedSize bytes");

        if (compressedSize < size * box.read("minCompression") / 100) {
          saveLogs("PDF compression successful (saved ${size - compressedSize} bytes)");
          return compressedSize;
        } else {
          saveLogs("PDF compression not effective enough, keeping original file");
          errors.addAll({
            filePath: localizations!.compressionNotEffective,
          });
          await compressedFile.delete();
          return size;
        }
      } catch (e) {
        saveLogs('Error retrieving compressed PDF file size: $e');
        saveLogs("Mincompression ${box.read("minCompression") / 100}");
        errors.addAll({
          filePath: localizations!.compressionError(e.toString()),
        });
        return -1;
      }
    } else {
      saveLogs('Compressed PDF file not found: ${compressedFile.path}');
      if (!isCompressionCancelled) {
        errors.addAll({
          filePath: localizations!.fileNotFoundAfterCompression,
        });
      }
      return !isCompressionCancelled ? -1 : 0;
    }
  } catch (e) {
    saveLogs('Error during PDF compression: $e');
    errors.addAll({
      filePath: localizations!.compressionError(e.toString()),
    });
    return -1;
  }
}

Future<int> compressImage(BuildContext context, String filePath, String name, int size, String outputDir, int quality, bool keepMetadata, {Function(double)? onProgress}) async {
  saveLogs("Starting image compression - File: $filePath, Quality: $quality%, Keep metadata: $keepMetadata, Size: $size bytes");
  final localizations = AppLocalizations.of(context);

  int progress = 0;
  String ext = filePath.split('.').last;
  String outputPath = "$outputDir/$name.$ext";
  outputPath = getUniqueFileName(outputPath);
  outputPathNotifier.value = outputPath;
  saveLogs("Image output path: $outputPath");

  List<String> cmdArgs = [
    magickPath,
    "convert",
    "-monitor",
    filePath,
    if (!keepMetadata) ...[
      "-strip",
    ],
    "-quality",
    "$quality%",
    outputPath,
  ];

  saveLogs("ImageMagick command: ${cmdArgs.join(' ')}");

  try {
    var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
    saveLogs("ImageMagick process started successfully");

    int oldNumber = -1;
    process.stderr.transform(utf8.decoder).listen(
      (output) {
        if (output.contains("%")) {
          var regex = RegExp(r'(\d+)%');
          var match = regex.firstMatch(output);
          if (match != null) {
            progress++;
            if (progress != oldNumber) {
              oldNumber = progress;
              progressNotifier.value = progress / 100;
              if (onProgress != null) {
                onProgress(progressNotifier.value);
              }
            }
          }
        }
      },
    );

    await process.exitCode;
    saveLogs("ImageMagick process completed");

    File compressedFile = File(outputPath);
    if (await compressedFile.exists()) {
      try {
        final compressedSize = compressedFile.lengthSync();
        saveLogs("Image compression completed - Original: $size bytes, Compressed: $compressedSize bytes");

        if (compressedSize < size * box.read("minCompression") / 100) {
          saveLogs("Image compression successful (saved ${size - compressedSize} bytes)");
          return compressedSize;
        } else {
          saveLogs("Image compression not effective enough, keeping original file");
          errors.addAll({
            filePath: localizations!.compressionNotEffective,
          });
          await compressedFile.delete();
          return size;
        }
      } catch (e) {
        saveLogs('Error retrieving compressed image file size: $e');
        errors.addAll({
          filePath: localizations!.compressionError(e.toString()),
        });
        return -1;
      }
    } else {
      saveLogs('Compressed image file not found: ${compressedFile.path}');
      if (!isCompressionCancelled) {
        errors.addAll({
          filePath: localizations!.fileNotFoundAfterCompression,
        });
      }
      return !isCompressionCancelled ? -1 : 0;
    }
  } catch (e) {
    saveLogs('Error during image compression: $e');
    errors.addAll({
      filePath: localizations!.compressionError(e.toString()),
    });
    return -1;
  }
}

Future<void> cancelCompression(path, file) async {
  isCompressionCancelled = true;

  if (Platform.isWindows) {
    await Process.run('powershell', [
      '-Command',
      'Get-Process | Where-Object {\$_.Path -eq "$path"} | Stop-Process -Force'
    ]);
  } else {
    await Process.run('pkill', [
      '-f',
      path
    ]);
  }

  String filePath = file is ValueNotifier<String> ? file.value : file;

  File compressedFile = File(filePath);
  if (await compressedFile.exists()) {
    compressedFile.delete();
  }
  progressNotifier.value = 0;
}

String getUniqueFileName(String filePath) {
  File file = File(filePath);
  String newFilePath = filePath;
  int counter = 1;

  String fileName = file.uri.pathSegments.last;
  fileName = fileName.split('.').first;
  String fileExtension = file.uri.pathSegments.last.split('.').last;

  while (file.existsSync()) {
    String newFileName = "$fileName ($counter).$fileExtension";
    newFilePath = "${file.parent.path}/$newFileName";
    file = File(newFilePath);
    counter++;
  }

  if (counter > 1) {
    saveLogs("File name conflict resolved: $filePath -> $newFilePath");
  }

  return newFilePath;
}

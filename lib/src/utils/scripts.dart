import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:flutter/material.dart';

final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
final ValueNotifier<String> outputPathNotifier = ValueNotifier<String>("");
int totalSecondsInt = 0;
bool isCompressionCancelled = false;

Future<int> compressMedia(String filePath, String name, String fileExt, int originalSize, int quality, int fps, bool delete, String outputDir, String? cover, {Function(double)? onProgress}) async {
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

  if (quality == -1) {
    cmdArgs.addAll([
      if (fileExt != 'mp3' && fileExt != 'gif') ...[
        "-c:v",
        "copy",
      ],
      "-y",
      outputPath,
    ]);
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
  }

  var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
  bool hasAudio = false;
  process.stderr.transform(utf8.decoder).listen((output) {
    if (isCompressionCancelled) return;

    if (fileExt == "mp3") {
      if (output.contains('Stream') && output.contains('Audio:')) {
        hasAudio = true;
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

  if (!hasAudio && fileExt == "mp3") {
    debugPrint("No audio track found in the file");
    return -1;
  }

  File compressedFile = File(outputPath);
  if (await compressedFile.exists()) {
    try {
      fileSize = (quality == -1) ? 0 : compressedFile.lengthSync();
    } catch (e) {
      debugPrint('Error retrieving file size: $e');
    }
  } else if (!isCompressionCancelled) {
    debugPrint('Compressed file not found: ${compressedFile.path}');
    return !isCompressionCancelled ? -1 : 0;
  }

  if (fileSize < originalSize * 0.9) {
    if (delete) {
      File originalFile = File(filePath);
      originalFile.delete();
    }
  }

  return fileSize;
}

Future<int> compressPdf(String filePath, String name, int size, String outputDir, int quality, {Function(double)? onProgress}) async {
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

  int totalPages = 0;
  var processPages = await Process.start(cmdArgsPage[0], cmdArgsPage.sublist(1));
  processPages.stdout.transform(utf8.decoder).listen((output) {
    String trimmedOutput = output.trim();
    if (RegExp(r'^\d+$').hasMatch(trimmedOutput)) {
      totalPages = int.parse(trimmedOutput);
    } else {
      debugPrint("L'output n'est pas un nombre: $trimmedOutput");
    }
  });

  String outputPath = "$outputDir/$name.pdf";
  outputPath = getUniqueFileName(outputPath);
  outputPathNotifier.value = outputPath;

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

  var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
  process.stdout.transform(utf8.decoder).listen((output) {
    // Détecter le mot page pour savoir si une page a été traitée
    if (output.contains("Page")) {
      page++;
      progressNotifier.value = (page / totalPages);
      if (onProgress != null) {
        onProgress(progressNotifier.value);
      }
    }
  });

  await process.exitCode;

  File compressedFile = File(outputPath);
  if (await compressedFile.exists()) {
    try {
      return compressedFile.lengthSync();
    } catch (e) {
      return -1;
    }
  } else {
    debugPrint('Compressed file not found: ${compressedFile.path}');
    return !isCompressionCancelled ? -1 : 0;
  }
}

Future<int> compressImage(String filePath, String name, int size, String outputDir, int quality, bool keepMetadata, {Function(double)? onProgress}) async {
  int progress = 0;
  String ext = filePath.split('.').last;
  String outputPath = "$outputDir/$name.$ext";
  outputPath = getUniqueFileName(outputPath);
  outputPathNotifier.value = outputPath;

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

  try {
    var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
    int oldNumber = -1;
    process.stderr.transform(utf8.decoder).listen(
      (output) {
        if (output.contains("%")) {
          var regex = RegExp(r'(\d+)%');
          var match = regex.firstMatch(output);
          debugPrint("Match: ${match?.group(1)}");
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

    File compressedFile = File(outputPath);
    if (await compressedFile.exists()) {
      try {
        compressedFile.lengthSync();
      } catch (e) {
        debugPrint('Error retrieving file size: $e');
      }
    } else {
      debugPrint('Compressed file not found: ${compressedFile.path}');
      return !isCompressionCancelled ? -1 : 0;
    }

    return compressedFile.lengthSync();
  } catch (e) {
    debugPrint('Error starting process: $e');
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

  return newFilePath;
}

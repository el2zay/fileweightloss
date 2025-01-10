import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:flutter/material.dart';

final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
int totalSecondsInt = 0;

Future<int> compressFile(String filePath, String name, String fileExt, int originalSize, int quality, int fps, bool delete, String outputDir, {Function(double)? onProgress}) async {
  String? parameterCrf, parameterR, parameterB;
  double duration = 0;
  if (quality == 0) {
    parameterCrf = "23";
    parameterR = "60";
    parameterB = "1000";
  } else if (quality == 1) {
    parameterCrf = "28";
    parameterR = "60";
    parameterB = "750";
  } else if (quality == 2) {
    parameterCrf = "32";
    parameterR = "30";
    parameterB = "500";
  } else if (quality == 3) {
    parameterCrf = "36";
    parameterR = "24";
    parameterB = "250";
  }

  List<String> cmdArgs = [
    ffmpegPath,
    "-i",
    filePath,
    if (fileExt == 'gif') ...[
      "-vf",
      "fps=$fps",
      "-y",
      "$outputDir/$name.$fileExt",
    ] else ...[
      "-c:a",
      "copy",
    ],
  ];

  if (quality == -1) {
    cmdArgs.addAll([
      "-c",
      "copy",
    ]);
  } else {
    cmdArgs.addAll([
      "-vcodec",
      "libx264",
      "-preset",
      "slower",
      "-crf",
      parameterCrf!,
      "-r",
      parameterR!,
      "-b:v",
      "${parameterB}k",
      "-y",
      "$outputDir/$name.compressed.$fileExt",
    ]);
  }

  var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
  process.stderr.transform(utf8.decoder).listen((output) {
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
      if (onProgress != null) {
        onProgress(progressNotifier.value);
      }
    }
  });

  await process.exitCode;

  File compressedFile = File("$outputDir/$name.${(quality != -1) ? "compressed." : ""}$fileExt");
  if (await compressedFile.exists()) {
    try {
      compressedFile.lengthSync();
    } catch (e) {
      debugPrint('Error retrieving file size: $e');
    }
  } else {
    debugPrint('Compressed file not found: ${compressedFile.path}');
  }

  var fileSize = (quality == -1) ? 0 : compressedFile.lengthSync();

  if (fileSize < originalSize * 0.9) {
    if (delete) {
      File originalFile = File(filePath);
      originalFile.delete();
    }

    debugPrint("Compression success");
  } else {
    debugPrint("Compression failed");
  }

  return fileSize;
}

Future<void> cancelCompression() async {
  await Process.run('pkill', [
    'ffmpeg'
  ]);
  progressNotifier.value = 0;
}

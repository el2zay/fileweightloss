import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:flutter/material.dart';

final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
int totalSecondsInt = 0;

Future<int> compressFile(String filePath, String name, String fileExt, int originalSize, int duration, int quality, bool delete, String outputDir, {Function(double)? onProgress}) async {
  String? parameterCrf, parameterR, parameterB;

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
    "-vcodec",
    "libx264",
    "-preset",
    "slower",
    "-crf",
    parameterCrf!,
    "-r",
    parameterR!,
    "-b",
    "${parameterB!}k",
    "-y",
    "$outputDir/$name.compressed.$fileExt"
  ];

  var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
  process.stderr.transform(utf8.decoder).listen((output) {
    var regex = RegExp(r'time=([\d:.]+)');
    var match = regex.firstMatch(output);
    if (match != null) {
      final timeValue = match.group(1);
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

  File compressedFile = File("$outputDir/$name.compressed.$fileExt");
  if (await compressedFile.exists()) {
    try {
      compressedFile.lengthSync();
    } catch (e) {
      debugPrint('Error retrieving file size: $e');
    }
  } else {
    debugPrint('Compressed file not found: ${compressedFile.path}');
  }

  var fileSize = compressedFile.lengthSync();

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

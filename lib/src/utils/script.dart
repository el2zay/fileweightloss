import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:flutter/material.dart';

final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
int totalSecondsInt = 0;

Future<int> compressFile(String filePath, String name, String fileExt, int originalSize, int duration, int retryI, bool delete, String outputDir, {Function(double)? onProgress}) async {
  var parameterCrf = "28";
  var parameterR = "60";
  var parameterB = "500";

  if (retryI == 1) {
    parameterCrf = "34";
    parameterR = "50";
    parameterB = "400";
  } else if (retryI == 2) {
    parameterCrf = "38";
    parameterR = "40";
    parameterB = "300";
  } else if (retryI == 3) {
    parameterCrf = "42";
    parameterR = "30";
    parameterB = "150";
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
    parameterCrf,
    "-r",
    parameterR,
    "-b",
    "${parameterB}k",
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
    compressedFile.delete();
    if (retryI < 3) {
      return await compressFile(filePath, name, fileExt, originalSize, duration, retryI + 1, delete, outputDir, onProgress: onProgress);
    }
  }

  return fileSize;
}

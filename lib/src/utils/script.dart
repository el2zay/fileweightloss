import 'dart:io';
import 'package:fileweightloss_gui/main.dart';
import 'package:flutter/material.dart';

Future<int> compressFile(String filePath, String name, String fileExt, int originalSize, int retryI, bool delete, String outputDir) async {
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
    "-ss",
    "0:01",
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

  await Process.run(cmdArgs[0], cmdArgs.sublist(1));

  File compressedFile = File("$outputDir/$name.compressed.$fileExt");
  try {
    compressedFile.lengthSync();
  } catch (e) {
    debugPrint(e.toString());
  }

  var fileSize = compressedFile.lengthSync();
  if (fileSize < originalSize) {
    if (delete) {
      File originalFile = File(filePath);
      originalFile.delete();
    }
    // compressedFile.rename(filePath);
    debugPrint("Compression success");
  } else {
    compressedFile.delete();
    if (retryI < 3) {
      return await compressFile(filePath, name, fileExt, originalSize, retryI + 1, delete, outputDir);
    }
  }

  return fileSize;
}

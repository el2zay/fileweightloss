import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fileweightloss/main.dart';
import 'package:flutter/material.dart';

final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
int totalSecondsInt = 0;
Future<int> compressFile(String filePath, String name, String fileExt, int originalSize, int quality, int fps, bool delete, String outputDir, String? cover, {Function(double)? onProgress}) async {
  String? parameterCrf, parameterR, parameterB;
  String? soundQuality;
  double duration = 0;
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

  if (quality == -1) {
    cmdArgs.addAll([
      if (fileExt != 'mp3' && fileExt != 'gif') ...[
        "-c:v",
        "copy",
      ],
      "-y",
      "$outputDir/$name.$fileExt",
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
      "$outputDir/$name.compressed.$fileExt",
    ]);
  }

  var process = await Process.start(cmdArgs[0], cmdArgs.sublist(1));
  bool hasAudio = false;
  process.stderr.transform(utf8.decoder).listen((output) {
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
      if (onProgress != null) {
        onProgress(progressNotifier.value);
      }
    }
  });

  await process.exitCode;

  if (!hasAudio && fileExt == "mp3") {
    debugPrint("No audio track found in the file");
    return -1;
  }

  File compressedFile = File("$outputDir/$name.${(quality != -1) ? "compressed." : ""}$fileExt");
  if (await compressedFile.exists()) {
    try {
      compressedFile.lengthSync();
    } catch (e) {
      debugPrint('Error retrieving file size: $e');
    }
  } else {
    debugPrint('Compressed file not found: ${compressedFile.path}');
    return -1;
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

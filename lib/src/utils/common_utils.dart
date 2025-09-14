import 'dart:io';

import 'package:fileweightloss/main.dart';

void openInExplorer(String path) async {
  if (Platform.isWindows) {
    String escapedPath = path.replaceAll('/', '\\');
    await Process.run("explorer", ["/select,", escapedPath]);
  } else if (Platform.isMacOS) {
    await Process.run("open", ["-R", path]);
  } else if (Platform.isLinux) {
    try {
      await Process.run("nautilus", ["--select", path]);
    } catch (e) {
      await Process.run("dolphin", ["--select", path]);
    }
  }
}

void openInBrowser(String url) async {
  if (Platform.isMacOS) {
    await Process.run("open", [url]);
  } else if (Platform.isWindows) {
    await Process.run("rundll32", ["url.dll,FileProtocolHandler", url]);
  } else if (Platform.isLinux) {
    await Process.run("xdg-open", [url]);
  }
}

Future<String> saveLogs(String logs) async {
  logarte.log(logs);
  final directory = Directory.systemTemp;
  final file = File('${directory.path}/fwl_logs.txt');
  final now = DateTime.now();
  final formattedTime =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${now.day}/${now.month}/${now.year}";

  final cleanedLogs = logs.replaceAll(RegExp(r'[\n\r\t]'), ' ').trim();

  file.writeAsStringSync("$formattedTime - $cleanedLogs\n", mode: FileMode.append);
  return file.path;
}

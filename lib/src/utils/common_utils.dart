import 'dart:io';

void openInExplorer(String path) async {
  if (Platform.isWindows) {
    String escapedPath = path.replaceAll('/', '\\');
    await Process.run("explorer", [
      "/select,",
      escapedPath
    ]);
  } else if (Platform.isMacOS) {
    await Process.run("open", [
      "-R",
      path
    ]);
  } else if (Platform.isLinux) {
    // Essaie d'abord avec nautilus (GNOME)
    try {
      await Process.run("nautilus", [
        "--select",
        path
      ]);
    } catch (e) {
      await Process.run("dolphin", [
        "--select",
        path
      ]);
    }
  }
}

void openInBrowser(String url) async {
  if (Platform.isMacOS) {
    await Process.run("open", [
      url
    ]);
  } else if (Platform.isWindows) {
    await Process.run("rundll32", [
      "url.dll,FileProtocolHandler",
      url
    ]);
  } else if (Platform.isLinux) {
    await Process.run("xdg-open", [
      url
    ]);
  }
}

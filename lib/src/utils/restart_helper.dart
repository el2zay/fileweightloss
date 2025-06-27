import 'dart:io';

import 'package:flutter/services.dart';

class RestartHelper {
  static Future<void> restartApp() async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      final executable = Platform.resolvedExecutable;

      await Process.start(executable, [], mode: ProcessStartMode.detached);

      SystemNavigator.pop();
    }
  }
}

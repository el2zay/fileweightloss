import 'dart:io';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class RestartHelper {
  static Future<void> restartApp() async {
    final executable = Platform.resolvedExecutable;

    await Process.start(executable, [], mode: ProcessStartMode.detached);
    if (Platform.isMacOS) {
      SystemNavigator.pop();
    } else {
      await windowManager.close();
    }
  }
}

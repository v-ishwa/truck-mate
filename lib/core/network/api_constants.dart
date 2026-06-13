import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    try {
      if (Platform.isAndroid) {
        // 127.0.0.1 points to the loopback address on the device,
        // which adb reverse routes to localhost on the host machine.
        return 'http://127.0.0.1:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
}

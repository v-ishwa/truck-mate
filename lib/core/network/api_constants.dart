import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // ============================================================
  // CHANGE THIS to your PC's local IP address.
  // Find it by running 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux).
  // Both your phone and PC must be on the same WiFi network.
  // ============================================================
  static final String _serverHost = dotenv.env['SERVER_HOST'] ?? '192.168.29.136';
  static final int _serverPort = int.tryParse(dotenv.env['SERVER_PORT'] ?? '8080') ?? 8080;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$_serverPort';
    }
    // Physical Android/iOS devices use the PC's local network IP
    return 'http://$_serverHost:$_serverPort';
  }

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String posts = '/api/posts';
  static const String createPost = '/api/posts/create';
  static const String uploadPostImage = '/api/upload/post-image';
}

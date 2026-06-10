import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:truck_mate/features/profile/presentation/screens/profile_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Truck Mate',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.light,
              seedColor: const Color(0xFF0095F6),
              primary: const Color(0xFF0095F6),
            ),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF0095F6),
              primary: const Color(0xFF0095F6),
              surface: Colors.black,
            ),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/local_storage/datasources/theme_local_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final themeDatasource = ThemeLocalDatasource();  
  await themeDatasource.init();
  final savedThemeMode = await themeDatasource.getThemeMode();

  ThemeMode initialTheme;
  if (savedThemeMode == 'dark') {
    initialTheme = ThemeMode.dark;
  } else if (savedThemeMode == 'light') {
    initialTheme = ThemeMode.light;
  } else {
    initialTheme = ThemeMode.system;
  }

  MyApp.themeNotifier.value = initialTheme;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDark =
            currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final systemUiOverlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark ? Colors.black : Colors.white,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiOverlayStyle,
          child: MaterialApp(
            title: 'Truck Mate',
            debugShowCheckedModeBanner: false,
            themeMode: currentMode,
            theme: ThemeData(
              brightness: Brightness.light,
              appBarTheme: const AppBarTheme(
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
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
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              colorScheme: ColorScheme.fromSeed(
                brightness: Brightness.dark,
                seedColor: const Color(0xFF0095F6),
                primary: const Color(0xFF0095F6),
                surface: Colors.black,
              ),
              useMaterial3: true,
            ),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}

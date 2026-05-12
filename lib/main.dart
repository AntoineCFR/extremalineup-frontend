// lib/main.dart
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/app_data_manager.dart';
import 'pages/login_page.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ✅ Crée un GlobalKey pour ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ Initialise AppDataManager avec le GlobalKey
    AppDataManager().setScaffoldMessengerKey(scaffoldMessengerKey);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      AppDataManager().syncFavorites().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Extrema Outdoor 2026',
      theme: ThemeData.dark(),
      scaffoldMessengerKey: scaffoldMessengerKey, // ✅ Assigne le GlobalKey
      home: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getSavedLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            final loginData = snapshot.data!;
            return SplashScreen(
              userId: loginData['userId'],
              username: loginData['username'],
            );
          }
          return const LoginPage();
        },
      ),
    );
  }
}
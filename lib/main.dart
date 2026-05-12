import 'package:flutter/material.dart';
import 'services/auth_service.dart'; // ✅ Import du service
import 'pages/login_page.dart';
import 'pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Extremalineup',
      theme: ThemeData.dark(), // ✅ Thème sombre par défaut
      home: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getSavedLogin(), // ✅ Vérifie si un login est sauvegardé
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si un login est sauvegardé, affiche MainScreen avec les données
          if (snapshot.hasData && snapshot.data != null) {
            final loginData = snapshot.data!;
            return MainScreen(
              username: loginData['username'],
              userId: loginData['userId'],
            );
          }
          // Sinon, affiche la page de login
          return const LoginPage();
        },
      ),
    );
  }
}
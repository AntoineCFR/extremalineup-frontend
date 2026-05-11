import 'package:flutter/material.dart';
import 'timetable_page.dart';
import '../services/api_service.dart'; // Import pour fetchFavorites

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final username = _usernameController.text;
                if (username.isEmpty) return;

                final contextToUse = context;

                try {
                  // 1. Vérifie que l'utilisateur existe et récupère son user_id
                  final userId = await ApiService.checkUserExists(username);
                  if (userId == null) {
                    if (mounted && contextToUse.mounted) {
                      ScaffoldMessenger.of(contextToUse).showSnackBar(
                        const SnackBar(content: Text('Utilisateur non autorisé !')),
                      );
                    }
                    return;
                  }

                  // 2. Charge les favoris avec user_id
                  final favorites = await ApiService.fetchFavorites(userId);

                  if (mounted && contextToUse.mounted) {
                    Navigator.push(
                      contextToUse,
                      MaterialPageRoute(
                        builder: (context) => TimetablePage(
                          username: username, // On garde username pour l'affichage
                          userId: userId,     // On passe user_id pour les appels API
                          initialFavorites: favorites,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted && contextToUse.mounted) {
                    ScaffoldMessenger.of(contextToUse).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}
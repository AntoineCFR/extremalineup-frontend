import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/timetable_item.dart';

class ApiService {
  static const String _baseUrl = 'https://extremalineup.onrender.com';

  // 1. Récupère la timetable (inchangé)
  static Future<List<TimetableItem>> fetchTimetable() async {
    final response = await http.get(Uri.parse('$_baseUrl/timetable'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TimetableItem.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement de la timetable');
    }
  }

  // 2. Vérifie si l'utilisateur existe et récupère son user_id
  static Future<int?> checkUserExists(String username) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/check?username=$username'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['exists'] ? data['user_id'] as int : null;
    } else {
      throw Exception('Échec de la vérification de l\'utilisateur');
    }
  }

  // 3. Récupère les favoris avec user_id (INT64)
  static Future<Set<int>> fetchFavorites(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/favorites?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Set<int>.from(
        (data['favorites'] as List).map((fav) => fav['set_id'] as int),
      );
    } else {
      return <int>{};
    }
  }

  // 4. Sauvegarde les favoris avec user_id (INT64)
  static Future<void> saveFavorites(int userId, Set<int> favorites) async {
    await http.post(
      Uri.parse('$_baseUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'favorites': favorites.toList(),
      }),
    );
  }
}
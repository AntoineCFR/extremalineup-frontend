// lib/utils/utils.dart
class AppUtils {
  // Empêche l'instanciation (classe statique)
  AppUtils._();

  static String getDayName(String day) {
    switch (day.toLowerCase()) {
      case 'friday': return 'Vendredi';
      case 'saturday': return 'Samedi';
      case 'sunday': return 'Dimanche';
      default: return day;
    }
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String getDjImagePath(String djName) {
    final normalized = djName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'[^\w]'), '');
    return 'lib/assets/$normalized.jpg';
  }
}
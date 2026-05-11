import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/api_service.dart';
import '../widgets/favorite_star.dart';
import 'timeline_page.dart';

class TimetablePage extends StatefulWidget {
  final String username; // Pour l'affichage
  final int userId;      // Pour les appels API
  final Set<int> initialFavorites;

  const TimetablePage({
    super.key,
    required this.username,
    required this.userId,
    this.initialFavorites = const {},
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late Future<List<TimetableItem>> _timetableFuture;
  Set<int> _favoriteSetIds = {};

  @override
  void initState() {
    super.initState();
    _timetableFuture = ApiService.fetchTimetable();
    _favoriteSetIds = widget.initialFavorites; // Utilise les favoris passés
  }

  // Met à jour les favoris LOCALMENT
  void _toggleFavorite(TimetableItem item) {
    setState(() {
      if (_favoriteSetIds.contains(item.setId)) {
        _favoriteSetIds.remove(item.setId);
      } else {
        _favoriteSetIds.add(item.setId);
      }
      item.isFavorite = !item.isFavorite;
    });
  }

  // Sauvegarde les favoris avec userId
  Future<void> _saveFavorites() async {
    final contextToUse = context;
    try {
      await ApiService.saveFavorites(widget.userId, _favoriteSetIds);
      if (mounted && contextToUse.mounted) {
        ScaffoldMessenger.of(contextToUse).showSnackBar(
          const SnackBar(content: Text('Favoris sauvegardés !')),
        );
      }
    } catch (e) {
      if (mounted && contextToUse.mounted) {
        ScaffoldMessenger.of(contextToUse).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable - ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelinePage(
                    username: widget.username,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            tooltip: 'Voir la frise temporelle',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFavorites, // Bouton "Sauvegarder"
            tooltip: 'Sauvegarder les favoris',
          ),
        ],
      ),
      body: FutureBuilder<List<TimetableItem>>(
        future: _timetableFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final timetable = snapshot.data!;
            // Applique les favoris chargés au démarrage aux items
            for (var item in timetable) {
              item.isFavorite = _favoriteSetIds.contains(item.setId);
            }

            // Grouper par jour, puis par district
            final Map<String, Map<String, List<TimetableItem>>> groupedData = {};
            for (var item in timetable) {
              groupedData.putIfAbsent(item.day, () => {});
              groupedData[item.day]!.putIfAbsent(item.district, () => []);
              groupedData[item.day]![item.district]!.add(item);
            }

            return ListView(
              children: groupedData.entries.map((dayEntry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _getDayName(dayEntry.key),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...dayEntry.value.entries.map((districtEntry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              districtEntry.key,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                          ...districtEntry.value.map((item) {
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(item.dj),
                                subtitle: Text(
                                  '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                                ),
                                trailing: FavoriteStar(
                                  isFavorite: _favoriteSetIds.contains(item.setId), // Utilise _favoriteSetIds
                                  onPressed: () => _toggleFavorite(item),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }

  String _getDayName(String day) {
    switch (day.toLowerCase()) {
      case 'friday': return 'Vendredi';
      case 'saturday': return 'Samedi';
      case 'sunday': return 'Dimanche';
      default: return day;
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
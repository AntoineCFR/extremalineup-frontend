import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/api_service.dart';
import '../widgets/favorite_star.dart';

class LineupPage extends StatefulWidget {
  final String username;
  final int userId;

  const LineupPage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<LineupPage> createState() => _LineupPageState();
}

class _LineupPageState extends State<LineupPage> {
  late Future<List<TimetableItem>> _timetableFuture;
  Set<int> _favoriteSetIds = {};
  bool _isLoadingFavorites = true;
  String _selectedDay = 'friday';
  final List<String> _days = const ['friday', 'saturday', 'sunday'];
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _timetableFuture = ApiService.fetchTimetable();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.fetchFavorites(widget.userId);
      if (mounted) {
        setState(() {
          _favoriteSetIds = favorites;
          _isLoadingFavorites = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur au chargement des favoris: $e')),
        );
      }
    }
  }

  void _toggleFavorite(TimetableItem item) {
    setState(() {
      if (_favoriteSetIds.contains(item.setId)) {
        _favoriteSetIds.remove(item.setId);
      } else {
        _favoriteSetIds.add(item.setId);
      }
      item.isFavorite = _favoriteSetIds.contains(item.setId);
    });
  }

  Future<void> _saveFavorites() async {
    try {
      await ApiService.saveFavorites(widget.userId, _favoriteSetIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favoris sauvegardés !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
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

  String _getDjImagePath(String djName) {
    final normalized = djName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('.', '')
        .replaceAll(RegExp(r'[^\w]'), '');
        
    return 'lib/assets/$normalized.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Line-up - ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFavorites,
            tooltip: 'Sauvegarder les favoris',
          ),
        ],
      ),
      body: FutureBuilder<List<TimetableItem>>(
        future: _timetableFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoadingFavorites) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final timetable = snapshot.data!;
            for (var item in timetable) {
              item.isFavorite = _favoriteSetIds.contains(item.setId);
            }

            final filteredTimetable = timetable.where((item) => item.day == _selectedDay).toList();
            final displayItems = _showFavoritesOnly
                ? filteredTimetable.where((item) => _favoriteSetIds.contains(item.setId)).toList()
                : filteredTimetable;

            if (_showFavoritesOnly) {
              displayItems.sort((a, b) {
                int startCompare = a.startTime.compareTo(b.startTime);
                if (startCompare != 0) return startCompare;
                int endCompare = a.endTime.compareTo(b.endTime);
                if (endCompare != 0) return endCompare;
                return a.district.compareTo(b.district);
              });
            } else {
              displayItems.sort((a, b) {
                int districtCompare = a.district.compareTo(b.district);
                if (districtCompare != 0) return districtCompare;
                return a.startTime.compareTo(b.startTime);
              });
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedDay,
                          items: _days.map((day) {
                            return DropdownMenuItem<String>(
                              value: day,
                              child: Text(_getDayName(day)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedDay = newValue;
                              });
                            }
                          },
                          hint: const Text('Choisir un jour'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Text(
                            'Favoris uniquement',
                            style: TextStyle(color: Colors.white),
                          ),
                          Switch(
                            value: _showFavoritesOnly,
                            onChanged: (bool value) {
                              setState(() {
                                _showFavoritesOnly = value;
                              });
                            },
                            activeThumbColor: const Color(0xFF7851A9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      if (displayItems.isEmpty)
                        const Center(child: Text('Aucun DJ à afficher.')),
                      _showFavoritesOnly
                          ? Column(
                              children: displayItems.map((item) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  color: _favoriteSetIds.contains(item.setId)
                                      ? const Color(0xFF7851A9)
                                      : null,
                                  child: ListTile(
                                    // ✅ PHOTO DU DJ (mode favoris)
                                    leading: AspectRatio(
                                      aspectRatio: 1, // ✅ Ratio carré (largeur = hauteur)
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4.0),
                                        child: Image.asset(
                                          _getDjImagePath(item.dj),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.person, color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.dj,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                        Text(
                                          item.district,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: FavoriteStar(
                                      isFavorite: _favoriteSetIds.contains(item.setId),
                                      onPressed: () => _toggleFavorite(item),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          : Column(
                              children: [
                                for (var districtEntry in {
                                  for (var item in displayItems)
                                    item.district: displayItems.where((i) => i.district == item.district).toList()
                                }.entries)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Text(
                                          districtEntry.key,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      ...districtEntry.value.map((item) {
                                        return Card(
                                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          color: _favoriteSetIds.contains(item.setId)
                                              ? const Color(0xFF7851A9)
                                              : null,
                                          child: ListTile(
                                            // ✅ PHOTO DU DJ (mode normal)
                                            leading: AspectRatio(
                                              aspectRatio: 1,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4.0),
                                                child: Image.asset(
                                                  _getDjImagePath(item.dj),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.person, color: Colors.white54),
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              item.dj,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                                              style: const TextStyle(color: Colors.white70),
                                            ),
                                            trailing: FavoriteStar(
                                              isFavorite: _favoriteSetIds.contains(item.setId),
                                              onPressed: () => _toggleFavorite(item),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
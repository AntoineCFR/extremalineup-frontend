import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/api_service.dart';
import '../widgets/favorite_star.dart';

class TimetablePage extends StatefulWidget {
  final String username;
  final int userId;

  const TimetablePage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  // CONSTANTES CENTRALISÉES
  static const double pixelsPerMinute = 3.0;
  static const pixelsPerHour = pixelsPerMinute * 60;
  static const double normalTileHeight = 63.0;
  static const double favoriteTileHeight = 80.0;
  static const double timeScaleHeight = 40.0;
  static const double districtSpacing = 2.0;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 5, horizontal: 2);
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);
  // Styles de texte mis à jour
  static const TextStyle timeScaleTextStyle = TextStyle(fontSize: 14, color: Colors.white);
  static const TextStyle djTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle timeTextStyle = TextStyle(fontSize: 12, color: Colors.white70);
  static const TextStyle districtTextStyle = TextStyle(fontSize: 12, color: Colors.white);
  static const TextStyle districtSubtitleStyle = TextStyle(fontSize: 12, color: Colors.white54);

  late Future<List<TimetableItem>> _timetableFuture;
  Set<int> _favoriteSetIds = {};
  String _selectedDay = 'friday';
  final List<String> _days = const ['friday', 'saturday', 'sunday'];
  bool _showFavoritesOnly = false; // Toggle pour afficher uniquement les favoris

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
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des favoris: $e');
    }
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

  // ✅ Fonction pour vérifier si deux créneaux se chevauchent
  bool _hasOverlap(TimetableItem a, TimetableItem b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }

  // ✅ Fonction pour assigner les créneaux à des lignes sans chevauchement
  List<List<TimetableItem>> _assignToLines(List<TimetableItem> items) {
    List<List<TimetableItem>> lines = [];
    for (var item in items) {
      bool placed = false;
      for (var line in lines) {
        bool overlap = false;
        for (var existingItem in line) {
          if (_hasOverlap(item, existingItem)) {
            overlap = true;
            break;
          }
        }
        if (!overlap) {
          line.add(item);
          placed = true;
          break;
        }
      }
      if (!placed) {
        lines.add([item]);
      }
    }
    return lines;
  }

  Widget _buildTimeScale(DateTime minStartTime, DateTime maxEndTime) {
    return Container(
      height: timeScaleHeight,
      color: Colors.grey[900],
      child: Row(
        children: _buildTimeLabels(minStartTime, maxEndTime),
      ),
    );
  }

  List<Widget> _buildTimeLabels(DateTime start, DateTime end) {
    final List<Widget> labels = [];

    DateTime current = DateTime(start.year, start.month, start.day, start.hour);
    final endTime = DateTime(end.year, end.month, end.day, end.hour, end.minute);

    while (current.isBefore(endTime) || current == endTime) {
      labels.add(
        SizedBox(
          width: pixelsPerHour,
          child: Center(
            child: Text(
              '${current.hour}:00',
              style: timeScaleTextStyle, // ✅ Taille 14
            ),
          ),
        ),
      );
      current = current.add(const Duration(hours: 1));
    }
    return labels;
  }

  Widget _buildRegularVerticalLines(double totalWidth) {
    const interval = pixelsPerHour; // ✅ Intervalle en pixels (ex: 20)
    const lineWidth = 0.5; // ✅ Épaisseur de la ligne
    final lineCount = (totalWidth / interval).ceil() + 1; // ✅ Nombre de lignes

    return Row(
      children: List.generate(
        lineCount,
        (index) => Container(
          width: interval, // ✅ Largeur de chaque "case"
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.white24, // ✅ Couleur discrète
                width: lineWidth, // ✅ Épaisseur
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictRow(
    String district,
    List<TimetableItem> items,
    DateTime minStartTime,
    DateTime maxEndTime,
  ) {
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    final totalMinutes = maxEndTime.difference(minStartTime).inMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: districtSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            district,
            style: districtTextStyle, // ✅ Taille 12
          ),
        ),
        const SizedBox(height: districtSpacing),
        SizedBox(
          height: normalTileHeight, // ✅ Hauteur 63
          width: totalMinutes * pixelsPerMinute,
          child: Stack(
            children: items.map((item) {
              final startMinutes = item.startTime.difference(minStartTime).inMinutes;
              final endMinutes = item.endTime.difference(minStartTime).inMinutes;
              final left = startMinutes * pixelsPerMinute;
              final width = (endMinutes - startMinutes) * pixelsPerMinute;

              return Positioned(
                left: left,
                child: SizedBox(
                  width: width,
                  height: normalTileHeight, // ✅ Hauteur 63
                  child: Card(
                    margin: cardMargin,
                    color: _favoriteSetIds.contains(item.setId)
                        ? const Color(0xFF7851A9)
                        : null,
                    child: Padding(
                      padding: cardPadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ DJ : taille 14, tronqué si trop long
                                Text(
                                  item.dj,
                                  style: djTextStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // ✅ Heure : taille 12
                                Text(
                                  '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                                  style: timeTextStyle,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: FavoriteStar(
                              isFavorite: _favoriteSetIds.contains(item.setId),
                              onPressed: () => _toggleFavorite(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Timetable - ${widget.username}'),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final timetable = snapshot.data!;
            for (var item in timetable) {
              item.isFavorite = _favoriteSetIds.contains(item.setId);
            }

            // Filtre par jour sélectionné
            final filteredTimetable = timetable.where((item) => item.day == _selectedDay).toList();

            // Filtre par favoris si le toggle est activé
            final displayItems = _showFavoritesOnly
                ? filteredTimetable.where((item) => _favoriteSetIds.contains(item.setId)).toList()
                : filteredTimetable;

            if (displayItems.isEmpty) {
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
                  const Expanded(child: Center(child: Text('Aucun DJ à afficher.'))),
                ],
              );
            }

            // Calcule minStartTime et maxEndTime pour l'échelle temporelle
            final allStartTimes = displayItems.map((item) => item.startTime).toList();
            final allEndTimes = displayItems.map((item) => item.endTime).toList();
            final minStartTime = allStartTimes.reduce((a, b) => a.isBefore(b) ? a : b);
            final maxEndTime = allEndTimes.reduce((a, b) => a.isAfter(b) ? a : b);

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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Stack( // ✅ Stack pour superposer les lignes et le contenu
                        children: [
                          // ✅ Lignes verticales régulières (tous les 20px)
                          Positioned.fill(
                            top: timeScaleHeight, // ✅ Commence sous le bandeau
                              left: pixelsPerHour / 2, // ✅ Décalage de pixelsPerHour / 2 pour aligner avec le centre des étiquettes
                            child: _buildRegularVerticalLines(
                              maxEndTime.difference(minStartTime).inMinutes * pixelsPerMinute,
                            ),
                          ),
                          // Contenu principal (bandeau + tuiles)
                          Column(
                            children: [
                              _buildTimeScale(minStartTime, maxEndTime),
                              const SizedBox(height: 10),
                              _showFavoritesOnly
                                  ? Column(
                                      children: _assignToLines(displayItems).map((line) {
                                        return SizedBox(
                                          height: favoriteTileHeight,
                                          width: maxEndTime.difference(minStartTime).inMinutes * pixelsPerMinute,
                                          child: Stack(
                                            children: line.map((item) {
                                              final startMinutes = item.startTime.difference(minStartTime).inMinutes;
                                              final endMinutes = item.endTime.difference(minStartTime).inMinutes;
                                              final left = startMinutes * pixelsPerMinute;
                                              final width = (endMinutes - startMinutes) * pixelsPerMinute;

                                              return Positioned(
                                                left: left,
                                                child: SizedBox(
                                                  width: width,
                                                  height: favoriteTileHeight,
                                                  child: Card(
                                                    margin: cardMargin,
                                                    color: _favoriteSetIds.contains(item.setId)
                                                        ? const Color(0xFF7851A9)
                                                        : null,
                                                    child: Padding(
                                                      padding: cardPadding,
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  item.dj,
                                                                  style: djTextStyle,
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                Text(
                                                                  '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                                                                  style: timeTextStyle,
                                                                  maxLines: 1,
                                                                ),
                                                                Text(
                                                                  item.district,
                                                                  style: districtSubtitleStyle,
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Center(
                                                            child: FavoriteStar(
                                                              isFavorite: _favoriteSetIds.contains(item.setId),
                                                              onPressed: () => _toggleFavorite(item),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
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
                                          _buildDistrictRow(
                                            districtEntry.key,
                                            districtEntry.value,
                                            minStartTime,
                                            maxEndTime,
                                          ),
                                      ],
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
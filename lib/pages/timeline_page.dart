import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/api_service.dart';
import '../widgets/favorite_star.dart';

class TimelinePage extends StatefulWidget {
  final String username;
  final int userId;

  const TimelinePage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  // ✅ CONSTANTES CENTRALISÉES
  static const double pixelsPerMinute = 3.0;
  static const double tileHeight = 80.0;
  static const double timeScaleHeight = 40.0;
  static const double districtSpacing = 10.0;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 5, horizontal: 2);
  static const EdgeInsets cardPadding = EdgeInsets.all(8.0);
  static const TextStyle districtTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  static const TextStyle djTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle timeTextStyle = TextStyle(fontSize: 14);
  static const TextStyle timeScaleTextStyle = TextStyle(fontSize: 12);

  late Future<List<TimetableItem>> _timetableFuture;
  Set<int> _favoriteSetIds = {};
  String _selectedDay = 'friday';
  final List<String> _days = const ['friday', 'saturday', 'sunday'];

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
    return day;
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
      item.isFavorite = !item.isFavorite;
    });
  }

  Widget _buildTimeScale(DateTime minStartTime, DateTime maxEndTime) {
    return Container(
      height: timeScaleHeight,
      color: Colors.grey[200],
      child: Row(
        children: _buildTimeLabels(minStartTime, maxEndTime),
      ),
    );
  }

  List<Widget> _buildTimeLabels(DateTime start, DateTime end) {
    final List<Widget> labels = [];
    const pixelsPerHour = pixelsPerMinute * 60;

    // ✅ 0px d'espace à gauche
    // labels.add(const SizedBox(width: 0));

    DateTime current = DateTime(start.year, start.month, start.day, start.hour);
    final endTime = DateTime(end.year, end.month, end.day, end.hour, end.minute);

    while (current.isBefore(endTime) || current == endTime) {
      labels.add(
        SizedBox(
          width: pixelsPerHour,
          child: Center(
            child: Text(
              '${current.hour}:00',
              style: timeScaleTextStyle,
            ),
          ),
        ),
      );
      current = current.add(const Duration(hours: 1));
    }
    return labels;
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
            style: districtTextStyle,
          ),
        ),
        const SizedBox(height: districtSpacing),
        SizedBox(
          height: tileHeight,
          width: totalMinutes * pixelsPerMinute, // ✅ 0px de marge totale
          child: Stack(
            children: items.map((item) {
              final startMinutes = item.startTime.difference(minStartTime).inMinutes;
              final endMinutes = item.endTime.difference(minStartTime).inMinutes;
              final left = startMinutes * pixelsPerMinute; // ✅ 0px à gauche
              final width = (endMinutes - startMinutes) * pixelsPerMinute;

              return Positioned(
                left: left,
                child: SizedBox(
                  width: width,
                  height: tileHeight,
                  child: Card(
                    margin: cardMargin,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                              isFavorite: item.isFavorite,
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
      appBar: AppBar(
        title: Text('Frise Temporelle - ${widget.username}'),
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

            final filteredTimetable = timetable
                .where((item) => item.day == _selectedDay)
                .toList();

            if (filteredTimetable.isEmpty) {
              return Center(child: Text('Aucun créneau pour $_selectedDay.'));
            }

            final allStartTimes = filteredTimetable.map((item) => item.startTime).toList();
            final allEndTimes = filteredTimetable.map((item) => item.endTime).toList();
            final minStartTime = allStartTimes.reduce((a, b) => a.isBefore(b) ? a : b);
            final maxEndTime = allEndTimes.reduce((a, b) => a.isAfter(b) ? a : b);

            final Map<String, List<TimetableItem>> groupedByDistrict = {};
            for (var item in filteredTimetable) {
              groupedByDistrict.putIfAbsent(item.district, () => []);
              groupedByDistrict[item.district]!.add(item);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
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
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            _buildTimeScale(minStartTime, maxEndTime),
                            const SizedBox(height: 10),
                            ...groupedByDistrict.entries.map((districtEntry) {
                              return _buildDistrictRow(
                                districtEntry.key,
                                districtEntry.value,
                                minStartTime,
                                maxEndTime,
                              );
                            }),
                          ],
                        ),
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
import 'package:flutter/material.dart';
import '../models/timetable_item.dart';
import '../services/api_service.dart';
import '../widgets/favorite_star.dart';

// --- Constants ---
class _TimetableConstants {
  static const double pixelsPerMinute = 3.0;
  static const double pixelsPerHour = pixelsPerMinute * 60;
  static const double normalTileHeight = 63.0;
  static const double favoriteTileHeight = 80.0;
  static const double timeScaleHeight = 40.0;
  static const double districtSpacing = 2.0;
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 5, horizontal: 2);
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0);

  static const TextStyle timeScaleTextStyle = TextStyle(fontSize: 14, color: Colors.white);
  static const TextStyle djTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle timeTextStyle = TextStyle(fontSize: 12, color: Colors.white70);
  static const TextStyle districtTextStyle = TextStyle(fontSize: 12, color: Colors.white);
  static const TextStyle districtSubtitleStyle = TextStyle(fontSize: 12, color: Colors.white54);
}

// --- Main Widget ---
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

// --- State ---
class _TimetablePageState extends State<TimetablePage> {
  late Future<List<TimetableItem>> _timetableFuture;
  Set<int> _favoriteSetIds = {};
  String _selectedDay = 'friday';
  final List<String> _days = const ['friday', 'saturday', 'sunday'];
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _timetableFuture = ApiService.fetchTimetable();
    _loadFavorites();
  }

  // --- Data Loading ---
  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.fetchFavorites(widget.userId);
      if (mounted) {
        setState(() => _favoriteSetIds = favorites);
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

  // --- Business Logic ---
  List<TimetableItem> _getFilteredItems(List<TimetableItem> timetable) {
    final filteredByDay = timetable.where((item) => item.day == _selectedDay).toList();
    return _showFavoritesOnly
        ? filteredByDay.where((item) => _favoriteSetIds.contains(item.setId)).toList()
        : filteredByDay;
  }

  DateTime _getMinStartTime(List<TimetableItem> items) {
    return items.map((item) => item.startTime).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime _getMaxEndTime(List<TimetableItem> items) {
    return items.map((item) => item.endTime).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  DateTime _nextFullHour(DateTime date) {
    return date.minute == 0 ? date : DateTime(date.year, date.month, date.day, date.hour + 1);
  }

  double _calculateOffset(DateTime minStartTime) {
    final nextFullHour = _nextFullHour(minStartTime);
    return nextFullHour.difference(minStartTime).inMinutes * _TimetableConstants.pixelsPerMinute;
  }

  void _updateFavoriteStatus(List<TimetableItem> timetable) {
    for (var item in timetable) {
      item.isFavorite = _favoriteSetIds.contains(item.setId);
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

  String _getDayName(String day) {
    switch (day.toLowerCase()) {
      case 'friday': return 'Vendredi';
      case 'saturday': return 'Samedi';
      case 'sunday': return 'Dimanche';
      default: return day;
    }
  }

  // --- Widgets ---
  Widget _buildControls() {
    return Padding(
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
                  setState(() => _selectedDay = newValue);
                }
              },
              hint: const Text('Choisir un jour'),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              const Text('Favoris uniquement', style: TextStyle(color: Colors.white)),
              Switch(
                value: _showFavoritesOnly,
                onChanged: (bool value) => setState(() => _showFavoritesOnly = value),
                activeThumbColor: const Color(0xFF7851A9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildControls(),
        const Expanded(child: Center(child: Text('Aucun DJ à afficher.'))),
      ],
    );
  }

  Widget _buildTimeScale(DateTime minStartTime, DateTime maxEndTime, double offset) {
    return Container(
      height: _TimetableConstants.timeScaleHeight,
      color: Colors.grey[900],
      child: Row(children: _buildTimeLabels(minStartTime, maxEndTime, offset)),
    );
  }

  List<Widget> _buildTimeLabels(DateTime start, DateTime end, double offset) {
    final List<Widget> labels = [];
    final firstFullHour = _nextFullHour(start);
    final minutesToFirstFullHour = firstFullHour.difference(start).inMinutes;

    if (minutesToFirstFullHour > 0) {
      labels.add(SizedBox(width: minutesToFirstFullHour * _TimetableConstants.pixelsPerMinute));
    }

    DateTime current = firstFullHour;
    while (current.isBefore(end)) {
      labels.add(
        SizedBox(
          width: _TimetableConstants.pixelsPerHour,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text('${current.hour}:00', style: _TimetableConstants.timeScaleTextStyle),
            ),
          ),
        ),
      );
      current = current.add(const Duration(hours: 1));
    }
    return labels;
  }

  Widget _buildRegularVerticalLines(double totalWidth, double offset) {
    const interval = _TimetableConstants.pixelsPerHour;
    const lineWidth = 0.5;
    final lineCount = (totalWidth / interval).floor();
    final availableWidth = totalWidth - offset;
    final lastLineWidth = availableWidth - (lineCount - 1) * interval;

    return SizedBox(
      width: totalWidth,
      child: Row(
        children: [
          SizedBox(width: offset),
          ...List.generate(
            lineCount,
            (index) => Container(
              width: index == lineCount - 1 ? lastLineWidth : interval,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white24, width: lineWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Build ---
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
          }

          final timetable = snapshot.data!;
          _updateFavoriteStatus(timetable);

          final displayItems = _getFilteredItems(timetable);
          if (displayItems.isEmpty) {
            return _buildEmptyState();
          }

          final minStartTime = _getMinStartTime(displayItems);
          final maxEndTime = _getMaxEndTime(displayItems);
          final totalWidth = maxEndTime.difference(minStartTime).inMinutes * _TimetableConstants.pixelsPerMinute;
          final offsetInPixels = _calculateOffset(minStartTime);

          return Column(
            children: [
              _buildControls(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalWidth,
                      child: Stack(
                        children: [
                          Positioned(
                            top: _TimetableConstants.timeScaleHeight,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildRegularVerticalLines(totalWidth, offsetInPixels),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimeScale(minStartTime, maxEndTime, offsetInPixels),
                              const SizedBox(height: 10),
                              _showFavoritesOnly
                                  ? _TimetableFavoritesView(
                                      items: displayItems,
                                      totalWidth: totalWidth,
                                      minStartTime: minStartTime,
                                      favoriteSetIds: _favoriteSetIds,
                                      onToggleFavorite: _toggleFavorite,
                                    )
                                  : _TimetableDistrictView(
                                      items: displayItems,
                                      totalWidth: totalWidth,
                                      minStartTime: minStartTime,
                                      favoriteSetIds: _favoriteSetIds,
                                      onToggleFavorite: _toggleFavorite,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Dedicated Widgets ---
class _DjCard extends StatelessWidget {
  final TimetableItem item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final double width;
  final double height;

  const _DjCard({
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        margin: _TimetableConstants.cardMargin,
        color: isFavorite ? const Color(0xFF7851A9) : null,
        child: Padding(
          padding: _TimetableConstants.cardPadding,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dj,
                      style: _TimetableConstants.djTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                      style: _TimetableConstants.timeTextStyle,
                      maxLines: 1,
                    ),
                    if (height == _TimetableConstants.favoriteTileHeight)
                      Text(
                        item.district,
                        style: _TimetableConstants.districtSubtitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Center(
                child: FavoriteStar(
                  isFavorite: isFavorite,
                  onPressed: onToggleFavorite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TimetableDistrictRow extends StatelessWidget {
  final String district;
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final Set<int> favoriteSetIds;
  final void Function(TimetableItem) onToggleFavorite;

  const _TimetableDistrictRow({
    required this.district,
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.favoriteSetIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: _TimetableConstants.districtSpacing),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(district, style: _TimetableConstants.districtTextStyle),
        ),
        const SizedBox(height: _TimetableConstants.districtSpacing),
        SizedBox(
          height: _TimetableConstants.normalTileHeight,
          width: totalWidth,
          child: Stack(
            children: items.map((item) {
              final startMinutes = item.startTime.difference(minStartTime).inMinutes;
              final left = startMinutes * _TimetableConstants.pixelsPerMinute;
              final endMinutes = item.endTime.difference(minStartTime).inMinutes;
              final width = (endMinutes - startMinutes) * _TimetableConstants.pixelsPerMinute;

              return Positioned(
                left: left,
                child: _DjCard(
                  item: item,
                  isFavorite: favoriteSetIds.contains(item.setId),
                  onToggleFavorite: () => onToggleFavorite(item),
                  width: width,
                  height: _TimetableConstants.normalTileHeight,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TimetableDistrictView extends StatelessWidget {
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final Set<int> favoriteSetIds;
  final void Function(TimetableItem) onToggleFavorite;

  const _TimetableDistrictView({
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.favoriteSetIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByDistrict(items);
    return Column(
      children: groupedItems.entries.map((entry) {
        return _TimetableDistrictRow(
          district: entry.key,
          items: entry.value,
          totalWidth: totalWidth,
          minStartTime: minStartTime,
          favoriteSetIds: favoriteSetIds,
          onToggleFavorite: onToggleFavorite,
        );
      }).toList(),
    );
  }

  Map<String, List<TimetableItem>> _groupItemsByDistrict(List<TimetableItem> items) {
    final Map<String, List<TimetableItem>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.district, () => []).add(item);
    }
    return grouped;
  }
}

class _TimetableFavoritesView extends StatelessWidget {
  final List<TimetableItem> items;
  final double totalWidth;
  final DateTime minStartTime;
  final Set<int> favoriteSetIds;
  final void Function(TimetableItem) onToggleFavorite;

  const _TimetableFavoritesView({
    required this.items,
    required this.totalWidth,
    required this.minStartTime,
    required this.favoriteSetIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final lines = _assignToLines(items);
    return Column(
      children: lines.map((line) {
        return SizedBox(
          height: _TimetableConstants.favoriteTileHeight,
          width: totalWidth,
          child: Stack(
            children: line.map((item) {
              final startMinutes = item.startTime.difference(minStartTime).inMinutes;
              final left = startMinutes * _TimetableConstants.pixelsPerMinute;
              final endMinutes = item.endTime.difference(minStartTime).inMinutes;
              final width = (endMinutes - startMinutes) * _TimetableConstants.pixelsPerMinute;

              return Positioned(
                left: left,
                child: _DjCard(
                  item: item,
                  isFavorite: favoriteSetIds.contains(item.setId),
                  onToggleFavorite: () => onToggleFavorite(item),
                  width: width,
                  height: _TimetableConstants.favoriteTileHeight,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  List<List<TimetableItem>> _assignToLines(List<TimetableItem> items) {
    List<List<TimetableItem>> lines = [];
    for (var item in items) {
      bool placed = false;
      for (var line in lines) {
        bool overlap = line.any((existingItem) => _hasOverlap(item, existingItem));
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

  bool _hasOverlap(TimetableItem a, TimetableItem b) {
    return a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
  }
}
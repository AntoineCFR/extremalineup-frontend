import 'package:flutter/material.dart';
import 'dart:async';
import '../models/timetable_item.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;

  const HomePage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimetableItem? _firstSetItem;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateFirstSetItem();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateFirstSetItem() {
    final timetable = AppDataManager().timetable;
    if (timetable.isNotEmpty) {
      _firstSetItem = timetable.reduce((a, b) =>
        a.startTime.isBefore(b.startTime) ? a : b);
    } else {
      _firstSetItem = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    if (_firstSetItem == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: const Text('Accueil'),
        ),
        body: const Center(
          child: Text(
            'Aucun set trouvé',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final firstSetTimeLocal = _firstSetItem!.startTime;
    final difference = firstSetTimeLocal.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Extrema Outdoor 2026',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeUnit('Jours', days),
                const Text(
                  ' : ',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                _buildTimeUnit('Heures', hours),
                const Text(
                  ' : ',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                _buildTimeUnit('Minutes', minutes),
                const Text(
                  ' : ',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                _buildTimeUnit('Secondes', seconds),
              ],
            ),
            const SizedBox(height: 50),
            const Text(
              'Premier set',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${AppUtils.formatFullDate(firstSetTimeLocal)} - ${AppUtils.formatTime(firstSetTimeLocal)}',
              style: const TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
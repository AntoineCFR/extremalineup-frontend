import 'package:intl/intl.dart';

class TimetableItem {
  final int setId;
  final String dj;
  final String district;
  final String stage;
  final String day;
  final int dayInt;
  final DateTime startTime;
  final DateTime endTime;
  bool isFavorite;

  TimetableItem({
    required this.setId,
    required this.dj,
    required this.district,
    required this.stage,
    required this.day,
    required this.dayInt,
    required this.startTime,
    required this.endTime,
    this.isFavorite = false,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    final dateFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
    return TimetableItem(
      setId: json['set_id'] ?? 0,
      dj: json['dj'] ?? '',
      district: json['district'] ?? '',
      stage: json['stage'] ?? '',
      day: json['day'] ?? '',
      dayInt: json['day_int'] ?? 0,
      startTime: dateFormat.parse(json['start_time'] ?? ''),
      endTime: dateFormat.parse(json['end_time'] ?? ''),
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}
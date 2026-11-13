import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'area_calculator.dart';

class MeasurementRecord {
  const MeasurementRecord({
    required this.name,
    required this.createdAt,
    required this.points,
  });

  final String name;
  final DateTime createdAt;
  final List<GeoPoint> points;

  Map<String, Object> toJson() => {
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'points': points.map((p) => [p.latitude, p.longitude]).toList(),
  };

  factory MeasurementRecord.fromJson(Map<String, dynamic> json) =>
      MeasurementRecord(
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        points: (json['points'] as List).map((entry) {
          final pair = entry as List;
          return GeoPoint(
            (pair[0] as num).toDouble(),
            (pair[1] as num).toDouble(),
          );
        }).toList(),
      );
}

class MeasurementStore {
  static const _historyKey = 'measurement_history_v1';
  static const _accuracyKey = 'measurement_accuracy_v1';
  static const _distanceKey = 'measurement_distance_v1';
  static const _consentKey = 'map_privacy_consent_v1';

  Future<bool> hasConsent() async =>
      (await SharedPreferences.getInstance()).getBool(_consentKey) ?? false;

  Future<void> saveConsent() async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      _consentKey,
      true,
    )) {
      throw StateError('保存隐私选择失败');
    }
  }

  Future<({double accuracy, double distance})> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      accuracy: prefs.getDouble(_accuracyKey) ?? 20,
      distance: prefs.getDouble(_distanceKey) ?? 5,
    );
  }

  Future<void> saveSettings(double accuracy, double distance) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setDouble(_accuracyKey, accuracy)) {
      throw StateError('保存精度失败');
    }
    if (!await prefs.setDouble(_distanceKey, distance)) {
      throw StateError('保存间距失败');
    }
  }

  Future<List<MeasurementRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => MeasurementRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecord(MeasurementRecord record) async {
    final records = await loadRecords();
    records.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _historyKey,
      jsonEncode(records.map((e) => e.toJson()).toList()),
    )) {
      throw StateError('保存记录失败');
    }
  }

  /// Remove one matching entry, including legacy records that have no ID.
  Future<bool> deleteRecord(MeasurementRecord record) async {
    final records = await loadRecords();
    final target = jsonEncode(record.toJson());
    final index = records.indexWhere(
      (item) => jsonEncode(item.toJson()) == target,
    );
    if (index < 0) return false;
    records.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _historyKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    )) {
      throw StateError('删除记录失败');
    }
    return true;
  }
}

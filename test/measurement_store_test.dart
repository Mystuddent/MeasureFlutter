import 'package:flutter_test/flutter_test.dart';
import 'package:measure_flutter/features/measure/area_calculator.dart';
import 'package:measure_flutter/features/measure/measurement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('settings and records survive a new store instance', () async {
    final store = MeasurementStore();
    expect(await store.hasConsent(), isFalse);
    await store.saveConsent();
    await store.saveSettings(30, 10);
    final createdAt = DateTime.utc(2026, 1, 2);
    await store.addRecord(
      MeasurementRecord(
        name: '测试田块',
        createdAt: createdAt,
        points: const [
          GeoPoint(30, 103),
          GeoPoint(30, 103.001),
          GeoPoint(30.001, 103),
        ],
      ),
    );
    final anotherStore = MeasurementStore();
    expect(await anotherStore.hasConsent(), isTrue);
    final settings = await anotherStore.loadSettings();
    final records = await anotherStore.loadRecords();
    expect(settings.accuracy, 30);
    expect(settings.distance, 10);
    expect(records.single.name, '测试田块');
    expect(records.single.createdAt, createdAt);
    expect(records.single.points.length, 3);
    expect(records.single.points[1].longitude, 103.001);
  });

  test(
    'deleting a record preserves other records and removes only one duplicate',
    () async {
      final store = MeasurementStore();
      final first = MeasurementRecord(
        name: '甲',
        createdAt: DateTime.utc(2026),
        points: const [GeoPoint(30, 103)],
      );
      final second = MeasurementRecord(
        name: '乙',
        createdAt: DateTime.utc(2026),
        points: const [GeoPoint(31, 104)],
      );
      await store.addRecord(first);
      await store.addRecord(first);
      await store.addRecord(second);
      expect(await store.deleteRecord(first), isTrue);
      var records = await MeasurementStore().loadRecords();
      expect(records.map((r) => r.name), ['乙', '甲']);
      expect(await store.deleteRecord(first), isTrue);
      expect(await store.deleteRecord(first), isFalse);
      records = await store.loadRecords();
      expect(records.single.name, '乙');
    },
  );
}

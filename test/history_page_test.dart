import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:measure_flutter/features/measure/area_calculator.dart';
import 'package:measure_flutter/features/measure/history_page.dart';
import 'package:measure_flutter/features/measure/measurement_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('deletion requires confirmation and updates the list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = MeasurementStore();
    await store.addRecord(
      MeasurementRecord(
        name: '待删除',
        createdAt: DateTime.utc(2026),
        points: const [GeoPoint(30, 103), GeoPoint(30, 104), GeoPoint(31, 103)],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HistoryPage(store: store, mapAllowed: false)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('待删除'), findsOneWidget);
    await tester.tap(find.byTooltip('删除记录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('待删除'), findsNothing);
    expect(await store.loadRecords(), isEmpty);
  });

  testWidgets('selecting a saved record returns its original boundary', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = MeasurementStore();
    await store.addRecord(
      MeasurementRecord(
        name: '东边田块',
        createdAt: DateTime.utc(2026, 1, 2),
        points: const [
          GeoPoint(30, 103),
          GeoPoint(30, 103.001),
          GeoPoint(30.001, 103),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HistoryPage(store: store, mapAllowed: false),
                  ),
                );
              },
              child: const Text('打开历史'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开历史'));
    await tester.pumpAndSettle();
    expect(find.text('东边田块'), findsOneWidget);
    await tester.tap(find.text('东边田块'));
    await tester.pumpAndSettle();
    expect(find.text('请先返回首页同意隐私提示、授予定位权限并配置地图 Key。'), findsOneWidget);
    expect(find.textContaining('平方米'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('测量记录'), findsOneWidget);
  });
}

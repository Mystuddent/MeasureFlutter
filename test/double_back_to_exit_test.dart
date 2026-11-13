import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:measure_flutter/features/measure/double_back_to_exit.dart';

void main() {
  testWidgets(
    'first Android back shows hint; second exits within two seconds',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var exits = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DoubleBackToExit(
            hasUnsavedChanges: true,
            onExit: () => exits++,
            child: const Scaffold(body: Text('首页')),
          ),
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.textContaining('再按一次退出应用'), findsOneWidget);
      expect(find.textContaining('未保存的测量将丢失'), findsOneWidget);
      expect(exits, 0);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(exits, 1);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('back on a child page returns to root without exiting', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DoubleBackToExit(
          onExit: () => exits++,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('记录')),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('打开'), findsOneWidget);
    expect(exits, 0);
    debugDefaultTargetPlatformOverride = null;
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:measure_flutter/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('unsupported platforms show an explanatory message', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(const MeasureApp());
    expect(find.text('田亩通 · 地块测量'), findsOneWidget);
    expect(find.text('请在 Android 或 iOS 设备上使用定位测量。'), findsOneWidget);
    expect(find.byTooltip('测量记录'), findsOneWidget);
    expect(find.byTooltip('测量设置'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('declining privacy prevents map and location initialization', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const MeasureApp());
    await tester.pumpAndSettle();
    expect(find.text('隐私与定位授权提示'), findsOneWidget);
    await tester.tap(find.text('不同意'));
    await tester.pumpAndSettle();
    expect(find.text('阅读隐私提示并授权'), findsOneWidget);
    expect(find.text('开始测量'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('previous consent avoids asking the privacy question again', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'map_privacy_consent_v1': true});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const MeasureApp());
    await tester.pumpAndSettle();
    expect(find.text('隐私与定位授权提示'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}

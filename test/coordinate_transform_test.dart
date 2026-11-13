import 'package:flutter_test/flutter_test.dart';
import 'package:measure_flutter/features/measure/area_calculator.dart';
import 'package:measure_flutter/features/measure/coordinate_transform.dart';

void main() {
  test('converts a WGS84 point in China to an approximate GCJ-02 point', () {
    final result = CoordinateTransform.wgs84ToGcj02(
      const GeoPoint(39.908823, 116.397470),
    );
    expect(result.latitude, closeTo(39.9102, 0.0002));
    expect(result.longitude, closeTo(116.4037, 0.0002));
  });

  test('does not transform points outside the conversion region', () {
    const point = GeoPoint(51.5074, -0.1278);
    final result = CoordinateTransform.wgs84ToGcj02(point);
    expect(result.latitude, point.latitude);
    expect(result.longitude, point.longitude);
  });
}

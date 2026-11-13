import 'package:flutter_test/flutter_test.dart';
import 'package:measure_flutter/features/measure/area_calculator.dart';

void main() {
  group('AreaCalculator', () {
    test('calculates a rectangle and converts square meters to mu', () {
      const points = [
        GeoPoint(30, 103),
        GeoPoint(30, 103.001),
        GeoPoint(30.0009, 103.001),
        GeoPoint(30.0009, 103),
      ];

      final area = AreaCalculator.squareMeters(points);
      final mu = area / AreaCalculator.squareMetersPerMu;

      expect(area, greaterThan(8_000));
      expect(area, lessThan(11_000));
      expect(mu, greaterThan(12));
      expect(AreaCalculator.perimeterMeters(points), greaterThan(350));
    });

    test('returns zero area when fewer than three points are available', () {
      const points = [GeoPoint(30, 103), GeoPoint(30, 103.001)];

      expect(AreaCalculator.squareMeters(points), 0);
    });
  });
}

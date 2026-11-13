import 'dart:math' as math;

/// A geographic coordinate in WGS84 decimal degrees.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Calculates small-field area and perimeter on a local tangent plane.
///
/// This is suitable for ordinary agricultural plots. It is not a substitute
/// for survey-grade GNSS or an ellipsoidal cadastral-area calculation.
abstract final class AreaCalculator {
  static const double _earthRadiusMeters = 6371008.8;
  static const double squareMetersPerMu = 666.6666667;

  static double squareMeters(List<GeoPoint> points) {
    if (points.length < 3) return 0;

    final meanLatitude =
        points.fold<double>(0, (sum, point) => sum + point.latitude) /
        points.length;
    final latitudeOrigin = _radians(meanLatitude);
    final projected = points
        .map((point) {
          final latitude = _radians(point.latitude);
          final longitude = _radians(point.longitude);
          return (
            x: _earthRadiusMeters * longitude * math.cos(latitudeOrigin),
            y: _earthRadiusMeters * latitude,
          );
        })
        .toList(growable: false);

    var twiceArea = 0.0;
    for (var index = 0; index < projected.length; index++) {
      final current = projected[index];
      final next = projected[(index + 1) % projected.length];
      twiceArea += current.x * next.y - next.x * current.y;
    }
    return twiceArea.abs() / 2;
  }

  static double perimeterMeters(List<GeoPoint> points) {
    if (points.length < 2) return 0;

    var perimeter = 0.0;
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      perimeter += _distanceMeters(current, next);
    }
    return perimeter;
  }

  static double _distanceMeters(GeoPoint first, GeoPoint second) {
    final lat1 = _radians(first.latitude);
    final lat2 = _radians(second.latitude);
    final deltaLat = lat2 - lat1;
    final deltaLon = _radians(second.longitude - first.longitude);
    final a =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

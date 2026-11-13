import 'dart:math' as math;

import 'area_calculator.dart';

/// Approximate WGS84-to-GCJ-02 conversion for displaying GPS on AMap.
/// The original WGS84 points are retained for all measurements.
abstract final class CoordinateTransform {
  static GeoPoint wgs84ToGcj02(GeoPoint point) {
    final lat = point.latitude;
    final lon = point.longitude;
    if (lon < 72.004 || lon > 137.8347 || lat < 0.8293 || lat > 55.8271) {
      return point;
    }
    final x = lon - 105.0;
    final y = lat - 35.0;
    var dLat =
        -100.0 +
        2 * x +
        3 * y +
        .2 * y * y +
        .1 * x * y +
        .2 * math.sqrt(x.abs());
    dLat +=
        (20 * math.sin(6 * x * math.pi) + 20 * math.sin(2 * x * math.pi)) *
        2 /
        3;
    dLat +=
        (20 * math.sin(y * math.pi) + 40 * math.sin(y / 3 * math.pi)) * 2 / 3;
    dLat +=
        (160 * math.sin(y / 12 * math.pi) + 320 * math.sin(y * math.pi / 30)) *
        2 /
        3;
    var dLon =
        300.0 + x + 2 * y + .1 * x * x + .1 * x * y + .1 * math.sqrt(x.abs());
    dLon +=
        (20 * math.sin(6 * x * math.pi) + 20 * math.sin(2 * x * math.pi)) *
        2 /
        3;
    dLon +=
        (20 * math.sin(x * math.pi) + 40 * math.sin(x / 3 * math.pi)) * 2 / 3;
    dLon +=
        (150 * math.sin(x / 12 * math.pi) + 300 * math.sin(x / 30 * math.pi)) *
        2 /
        3;
    final radLat = lat / 180 * math.pi;
    const a = 6378245.0;
    const ee = 0.006693421622965943;
    final magic = 1 - ee * math.pow(math.sin(radLat), 2);
    final sqrtMagic = math.sqrt(magic);
    dLat = dLat * 180 / ((a * (1 - ee)) / (magic * sqrtMagic) * math.pi);
    dLon = dLon * 180 / (a / sqrtMagic * math.cos(radLat) * math.pi);
    return GeoPoint(lat + dLat, lon + dLon);
  }
}

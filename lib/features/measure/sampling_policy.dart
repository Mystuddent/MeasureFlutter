import 'package:geolocator/geolocator.dart';

import 'area_calculator.dart';

enum SampleResult { accepted, invalid, stale, inaccurate, duplicate }

abstract final class SamplingPolicy {
  static SampleResult evaluate(
    Position position, {
    required double maxAccuracy,
    required DateTime now,
    GeoPoint? previous,
    double minimumDistance = 0,
  }) {
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude.abs() > 90 ||
        position.longitude.abs() > 180 ||
        !position.accuracy.isFinite ||
        position.accuracy <= 0) {
      return SampleResult.invalid;
    }
    if (now.difference(position.timestamp).abs() >=
        const Duration(seconds: 20)) {
      return SampleResult.stale;
    }
    if (position.accuracy > maxAccuracy) return SampleResult.inaccurate;
    if (previous != null &&
        Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            ) <
            minimumDistance) {
      return SampleResult.duplicate;
    }
    return SampleResult.accepted;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:measure_flutter/features/measure/area_calculator.dart';
import 'package:measure_flutter/features/measure/sampling_policy.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);
  Position position({
    double latitude = 30,
    double longitude = 103,
    double accuracy = 5,
    DateTime? time,
  }) => Position(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    timestamp: time ?? now,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  test(
    'manual point can be closer than automatic spacing but rejects duplicates',
    () {
      const previous = GeoPoint(30, 103);
      expect(
        SamplingPolicy.evaluate(
          position(latitude: 30.00002),
          maxAccuracy: 20,
          now: now,
          previous: previous,
          minimumDistance: .5,
        ),
        SampleResult.accepted,
      );
      expect(
        SamplingPolicy.evaluate(
          position(),
          maxAccuracy: 20,
          now: now,
          previous: previous,
          minimumDistance: .5,
        ),
        SampleResult.duplicate,
      );
    },
  );

  test('rejects inaccurate, stale and invalid fixes', () {
    expect(
      SamplingPolicy.evaluate(
        position(accuracy: 25),
        maxAccuracy: 20,
        now: now,
      ),
      SampleResult.inaccurate,
    );
    expect(
      SamplingPolicy.evaluate(
        position(time: now.subtract(const Duration(seconds: 20))),
        maxAccuracy: 20,
        now: now,
      ),
      SampleResult.stale,
    );
    expect(
      SamplingPolicy.evaluate(
        position(latitude: double.nan),
        maxAccuracy: 20,
        now: now,
      ),
      SampleResult.invalid,
    );
  });
}

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'area_calculator.dart';
import 'coordinate_transform.dart';
import 'measurement_store.dart';

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({
    super.key,
    required this.record,
    required this.mapAllowed,
  });
  final MeasurementRecord record;
  final bool mapAllowed;

  Future<void> _fit(AMapController controller, List<LatLng> points) async {
    if (points.isEmpty) return;
    var minLat = points.first.latitude, maxLat = minLat;
    var minLon = points.first.longitude, maxLon = minLon;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    try {
      if (maxLat - minLat < 0.000001 ||
          maxLon - minLon < 0.000001 ||
          maxLon - minLon > 180) {
        await controller.moveCamera(
          CameraUpdate.newLatLngZoom(
            LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2),
            17,
          ),
        );
      } else {
        await controller.moveCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLon),
              northeast: LatLng(maxLat, maxLon),
            ),
            48,
          ),
        );
      }
    } catch (_) {
      // The user can still manually move and zoom the map.
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = record.points.map((p) {
      final converted = CoordinateTransform.wgs84ToGcj02(p);
      return LatLng(converted.latitude, converted.longitude);
    }).toList();
    final area = AreaCalculator.squareMeters(record.points);
    return Scaffold(
      appBar: AppBar(title: Text(record.name)),
      body: Column(
        children: [
          Expanded(
            child: !mapAllowed
                ? const Center(child: Text('请先返回首页同意隐私提示、授予定位权限并配置地图 Key。'))
                : points.length < 3
                ? const Center(child: Text('边界点不足，无法显示田块。'))
                : AMapWidget(
                    initialCameraPosition: CameraPosition(
                      target: points.first,
                      zoom: 16,
                    ),
                    polygons: {
                      Polygon(
                        points: points,
                        strokeWidth: 3,
                        strokeColor: const Color(0xFF20744B),
                        fillColor: const Color(0x442F9A63),
                      ),
                    },
                    onMapCreated: (controller) => WidgetsBinding.instance
                        .addPostFrameCallback((_) => _fit(controller, points)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${(area / AreaCalculator.squareMetersPerMu).toStringAsFixed(2)} 亩 · ${area.toStringAsFixed(0)} 平方米',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '周长 ${AreaCalculator.perimeterMeters(record.points).toStringAsFixed(0)} 米 · ${points.length} 个边界点',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

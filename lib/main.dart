import 'package:flutter/material.dart';

import 'features/measure/area_calculator.dart';
import 'features/measure/amap_preview_page.dart';

void main() {
  runApp(const MeasureApp());
}

class MeasureApp extends StatelessWidget {
  const MeasureApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF1F6B4A);
    return MaterialApp(
      title: '田亩通',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: forest,
          primary: forest,
          surface: const Color(0xFFF6F7F3),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const AmapPreviewPage(),
    );
  }
}

class MeasureHomePage extends StatefulWidget {
  const MeasureHomePage({super.key});

  @override
  State<MeasureHomePage> createState() => _MeasureHomePageState();
}

class _MeasureHomePageState extends State<MeasureHomePage> {
  static const _samplePoints = <GeoPoint>[
    GeoPoint(30.6000, 103.9000),
    GeoPoint(30.6000, 103.9010),
    GeoPoint(30.6008, 103.9011),
    GeoPoint(30.6010, 103.9004),
    GeoPoint(30.6006, 103.8998),
  ];

  bool _isMeasuring = false;
  int _pointCount = _samplePoints.length;
  List<GeoPoint> _points = _samplePoints;

  double get _areaSquareMeters => AreaCalculator.squareMeters(_points);
  double get _perimeterMeters => AreaCalculator.perimeterMeters(_points);

  void _toggleMeasure() {
    setState(() {
      if (_isMeasuring) {
        _isMeasuring = false;
      } else {
        _isMeasuring = true;
        _pointCount = 1;
        _points = [_samplePoints.first];
      }
    });
  }

  void _addSamplePoint() {
    if (!_isMeasuring || _points.length >= _samplePoints.length) return;
    setState(() {
      _pointCount = _points.length + 1;
      _points = _samplePoints.take(_pointCount).toList();
    });
  }

  void _undoPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points = _points.sublist(0, _points.length - 1);
      _pointCount = _points.length;
    });
  }

  void _finishMeasure() {
    setState(() => _isMeasuring = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('示例测量已完成；接入GPS后这里会保存真实地块。')));
  }

  @override
  Widget build(BuildContext context) {
    final mu = _areaSquareMeters / 666.6666667;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                children: [
                  _buildLocationStatus(),
                  const SizedBox(height: 12),
                  _buildMapCard(),
                  const SizedBox(height: 14),
                  _buildAreaCard(mu),
                  const SizedBox(height: 14),
                  _buildMeasureControls(),
                  const SizedBox(height: 12),
                  _buildBottomHint(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F0E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.grass_rounded, color: Color(0xFF1F6B4A)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '田亩通',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  '田块面积测量',
                  style: TextStyle(fontSize: 12, color: Color(0xFF77827B)),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AmapPreviewPage(),
                ),
              );
            },
            tooltip: '高德地图测试',
            icon: const Icon(Icons.map_outlined),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            onPressed: () {},
            tooltip: '测量记录',
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            onPressed: () {},
            tooltip: '设置',
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.my_location_rounded,
            size: 18,
            color: Color(0xFF28714F),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              '定位准备就绪',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            _isMeasuring ? '采点中 · $_pointCount点' : '模拟定位 · 精度±5米',
            style: const TextStyle(fontSize: 12, color: Color(0xFF557160)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 340,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: _addSamplePoint,
              child: CustomPaint(
                painter: _FieldMapPainter(points: _points.length),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _mapLabel(Icons.layers_outlined, '示意地图'),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _mapIconButton(Icons.my_location_rounded, '回到当前位置'),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 15,
                      color: Color(0xFF557160),
                    ),
                    SizedBox(width: 6),
                    Text('沿田埂行走，自动记录边界', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              right: 14,
              child: _mapIconButton(Icons.add_rounded, '放大地图'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapLabel(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF52695B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _mapIconButton(IconData icon, String tooltip) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(13),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: const Color(0xFF344B3D)),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaCard(double mu) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173A29),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '当前测量面积',
                  style: TextStyle(fontSize: 13, color: Color(0xFF738078)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '演示轨迹',
                  style: TextStyle(fontSize: 10, color: Color(0xFF557160)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mu.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 36,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: Color(0xFF1F6B4A),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '亩',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${_areaSquareMeters.toStringAsFixed(0)} m²',
                style: const TextStyle(fontSize: 13, color: Color(0xFF738078)),
              ),
            ],
          ),
          const Divider(height: 17),
          Row(
            children: [
              _statItem(
                Icons.route_rounded,
                '周长',
                '${_perimeterMeters.toStringAsFixed(0)} 米',
              ),
              const SizedBox(width: 22),
              _statItem(Icons.place_outlined, '边界点', '$_pointCount 个'),
              const Spacer(),
              TextButton.icon(
                onPressed: _undoPoint,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF53665A),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                icon: const Icon(Icons.undo_rounded, size: 17),
                label: const Text('撤销'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF819087)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF819087)),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildMeasureControls() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _toggleMeasure,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _isMeasuring
                  ? const Color(0xFFB85C38)
                  : const Color(0xFF1F6B4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: Icon(
              _isMeasuring ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              _isMeasuring ? '暂停测量' : '开始测量',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _points.length >= 3 ? _finishMeasure : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: const Color(0xFF1F6B4A),
              side: const BorderSide(color: Color(0xFFB8CBBE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(Icons.check_rounded),
            label: const Text(
              '完成测量',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: Color(0xFF87938A),
        ),
        const SizedBox(width: 5),
        Text(
          _isMeasuring ? '演示模式：点击地图模拟添加边界点' : '面积按 1 亩 = 666.67 平方米换算',
          style: const TextStyle(fontSize: 11, color: Color(0xFF87938A)),
        ),
        if (_isMeasuring) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addSamplePoint,
            child: const Text(
              '添加点',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF1F6B4A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldMapPainter extends CustomPainter {
  const _FieldMapPainter({required this.points});

  final int points;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFE8EFE2));

    final fields = <(Rect, Color)>[
      (Rect.fromLTWH(-24, 58, size.width * .43, 118), const Color(0xFFD7E5C9)),
      (
        Rect.fromLTWH(size.width * .48, -16, size.width * .58, 132),
        const Color(0xFFDDE9D1),
      ),
      (
        Rect.fromLTWH(size.width * .63, 126, size.width * .47, 96),
        const Color(0xFFD2E2C4),
      ),
      (Rect.fromLTWH(-18, 207, size.width * .45, 155), const Color(0xFFDDE8D2)),
      (
        Rect.fromLTWH(size.width * .53, 234, size.width * .55, 145),
        const Color(0xFFD7E5C9),
      ),
    ];
    for (final (rect, color) in fields) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(30)),
        Paint()..color = color,
      );
    }

    final roadPaint = Paint()
      ..color = const Color(0xFFF8F7EF)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-10, size.height * .59),
      Offset(size.width + 10, size.height * .43),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * .39, -10),
      Offset(size.width * .56, size.height + 10),
      roadPaint,
    );

    final trackPaint = Paint()
      ..color = const Color(0xFFC5D4B9)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final y = 76.0 + i * 14;
      canvas.drawLine(
        Offset(16, y),
        Offset(size.width * .37, y - 8),
        trackPaint,
      );
      canvas.drawLine(
        Offset(size.width * .68, 24 + i * 12),
        Offset(size.width - 12, 34 + i * 12),
        trackPaint,
      );
    }

    final polygon = <Offset>[
      Offset(size.width * .34, size.height * .31),
      Offset(size.width * .68, size.height * .28),
      Offset(size.width * .76, size.height * .54),
      Offset(size.width * .60, size.height * .72),
      Offset(size.width * .30, size.height * .62),
    ];
    final path = Path()..moveTo(polygon.first.dx, polygon.first.dy);
    for (final point in polygon.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (points >= 3) path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x332F9A63)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF20744B)
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    for (
      var i = 0;
      i < (points == 0 ? 0 : points.clamp(1, polygon.length));
      i++
    ) {
      final point = polygon[i];
      canvas.drawCircle(point, 8, Paint()..color = Colors.white);
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF20744B));
    }

    final center = Offset(size.width * .52, size.height * .49);
    canvas.drawCircle(center, 17, Paint()..color = const Color(0x222D78C4));
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
    canvas.drawCircle(center, 5.5, Paint()..color = const Color(0xFF3286D1));
  }

  @override
  bool shouldRepaint(covariant _FieldMapPainter oldDelegate) =>
      points != oldDelegate.points;
}

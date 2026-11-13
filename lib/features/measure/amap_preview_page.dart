import 'dart:async';
import 'dart:ui' as ui;

import 'package:amap_map/amap_map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'area_calculator.dart';
import 'coordinate_transform.dart';
import 'double_back_to_exit.dart';
import 'history_page.dart';
import 'measurement_store.dart';
import 'sampling_policy.dart';

class AmapPreviewPage extends StatefulWidget {
  const AmapPreviewPage({super.key});

  @override
  State<AmapPreviewPage> createState() => _AmapPreviewPageState();
}

class _AmapPreviewPageState extends State<AmapPreviewPage>
    with WidgetsBindingObserver {
  static const _androidKey = String.fromEnvironment('AMAP_ANDROID_KEY');
  static const _iosKey = String.fromEnvironment('AMAP_IOS_KEY');
  double _maxAccuracy = 20.0;
  double _minDistance = 5.0;
  final _store = MeasurementStore();
  bool _saving = false;

  bool _consented = false;
  bool _authorized = false;
  bool _permissionDeniedForever = false;
  bool _measuring = false;
  bool _finished = false;
  bool _busy = false;
  bool _foreground = true;
  String _status = '请先阅读隐私提示并授权';
  Position? _location;
  StreamSubscription<Position>? _subscription;
  AMapController? _mapController;
  bool _centerOnNextFix = true;
  bool _locating = false;
  bool _manualPointPending = false;
  int _measurementGeneration = 0;
  Marker? _locationMarker;
  BitmapDescriptor? _locationIcon;
  final List<GeoPoint> _points = [];

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  String get _platformKey =>
      defaultTargetPlatform == TargetPlatform.android ? _androidKey : _iosKey;
  bool get _hasUsableLocation =>
      _location != null &&
      SamplingPolicy.evaluate(
            _location!,
            maxAccuracy: _maxAccuracy,
            now: DateTime.now(),
          ) ==
          SampleResult.accepted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _createLocationIcon();
    if (_supported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreConsent();
      });
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _store.loadSettings();
      if (mounted) {
        setState(() {
          _maxAccuracy = settings.accuracy;
          _minDistance = settings.distance;
        });
      }
    } catch (_) {
      if (mounted) _message('读取设置失败，暂时使用默认设置。');
    }
  }

  Future<void> _openSettings() async {
    var accuracy = _maxAccuracy;
    var distance = _minDistance;
    final result = await showDialog<({double accuracy, double distance})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('测量设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('允许的最大定位误差'),
              DropdownButton<double>(
                value: accuracy,
                isExpanded: true,
                items: [5.0, 10.0, 20.0, 30.0, 50.0]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('${v.toStringAsFixed(0)} 米'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) update(() => accuracy = v);
                },
              ),
              const SizedBox(height: 12),
              const Text('采点最小间距'),
              DropdownButton<double>(
                value: distance,
                isExpanded: true,
                items: [2.0, 5.0, 10.0]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('${v.toStringAsFixed(0)} 米'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) update(() => distance = v);
                },
              ),
              const Text(
                '阈值越小只会过滤掉更多低精度点，不能提高手机自身定位精度，可能需要等待更久。',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                accuracy: accuracy,
                distance: distance,
              )),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await _store.saveSettings(result.accuracy, result.distance);
      if (!mounted) return;
      setState(() {
        _maxAccuracy = result.accuracy;
        _minDistance = result.distance;
      });
      await _message('设置已保存并立即生效。');
    } catch (_) {
      if (mounted) await _message('设置保存失败，请重试。');
    }
  }

  Future<void> _openHistory() async {
    if (_measuring) {
      setState(() {
        _measurementGeneration++;
        _measuring = false;
        _status = '已暂停测量；返回首页后可继续';
      });
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HistoryPage(
          store: _store,
          mapAllowed:
              _supported &&
              _consented &&
              _authorized &&
              _platformKey.isNotEmpty,
        ),
      ),
    );
  }

  Future<void> _createLocationIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(48, 48);
    canvas.drawCircle(center, 43, Paint()..color = const Color(0x553388FF));
    canvas.drawCircle(center, 29, Paint()..color = Colors.white);
    canvas.drawCircle(center, 23, Paint()..color = const Color(0xFF0878E8));
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
    final image = await recorder.endRecording().toImage(96, 96);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes != null && mounted) {
      setState(
        () => _locationIcon = BitmapDescriptor.fromBytes(
          bytes.buffer.asUint8List(),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_consented) _checkPermissionAndStart(request: false);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _foreground = false;
      _subscription?.cancel();
      _subscription = null;
      _location = null;
      if (_measuring && mounted) {
        setState(() {
          _measurementGeneration++;
          _measuring = false;
          _status = '已暂停：应用进入后台，返回后可继续测量';
        });
      }
    }
  }

  Future<void> _restoreConsent() async {
    try {
      if (await _store.hasConsent()) {
        if (!mounted) return;
        _activateConsent();
        await _checkPermissionAndStart(request: true);
        return;
      }
    } catch (_) {
      // Ask again if the saved preference cannot be read.
    }
    if (mounted) await _requestConsent();
  }

  void _activateConsent() {
    AMapInitializer.updatePrivacyAgree(
      const AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );
    setState(() {
      _consented = true;
      _status = '请允许位置权限，用于测量田块面积';
    });
  }

  Future<void> _requestConsent() async {
    if (_busy || !_supported) return;
    _busy = true;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('隐私与定位授权提示'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本应用使用高德地图 SDK 显示地图，并在您授权后读取设备位置，记录田块边界并计算面积。地图 SDK 可能处理设备、网络及位置相关信息，加载地图需要联网。',
              ),
              SizedBox(height: 12),
              Text('请先阅读高德隐私权政策：'),
              SelectableText('https://lbs.amap.com/pages/privacy/'),
              SizedBox(height: 12),
              Text('同意后将请求定位权限；不同意或拒绝权限时不会加载地图和开始定位。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('不同意'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
    _busy = false;
    if (!mounted) return;
    if (accepted != true) {
      setState(() => _status = '未同意隐私提示，无法加载地图和定位');
      return;
    }
    try {
      await _store.saveConsent();
    } catch (_) {
      if (mounted) await _message('无法保存同意状态，下次启动可能需要重新确认。');
    }
    if (!mounted) return;
    _activateConsent();
    await _checkPermissionAndStart(request: true);
  }

  Future<void> _checkPermissionAndStart({required bool request}) async {
    if (!_foreground || !_consented || _busy) return;
    _busy = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _subscription?.cancel();
        _subscription = null;
        if (mounted) {
          setState(() {
            _authorized = false;
            _measuring = false;
            _location = null;
            _status = '手机定位服务未开启，请在系统设置中开启';
          });
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        await _subscription?.cancel();
        _subscription = null;
        if (mounted) {
          setState(() {
            _authorized = false;
            _measuring = false;
            _location = null;
            _permissionDeniedForever =
                permission == LocationPermission.deniedForever;
            _status = _permissionDeniedForever
                ? '定位权限已被禁用，请打开应用设置授权'
                : '未获得定位权限，地图和测量不可用';
          });
        }
        return;
      }
      if (!_foreground || !mounted) return;
      setState(() {
        _authorized = true;
        _permissionDeniedForever = false;
        _status = '正在获取当前位置，请在室外等待定位';
      });
      await _subscription?.cancel();
      if (!_foreground || !mounted) return;
      _subscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
            ),
          ).listen(
            _onPosition,
            onError: (Object error) {
              if (mounted) {
                setState(() {
                  _authorized = false;
                  _measuring = false;
                  _location = null;
                  _status = '定位失败，请检查手机定位服务和应用权限';
                });
              }
            },
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _authorized = false;
          _status = '无法获取定位，请检查手机定位服务和应用权限';
        });
      }
    } finally {
      _busy = false;
    }
  }

  void _onPosition(Position position) {
    if (!mounted || !_foreground) return;
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude.abs() > 90 ||
        position.longitude.abs() > 180) {
      return;
    }
    final fresh =
        DateTime.now().difference(position.timestamp).abs() <
        const Duration(seconds: 20);
    final acceptable =
        fresh && position.accuracy > 0 && position.accuracy <= _maxAccuracy;
    final point = GeoPoint(position.latitude, position.longitude);
    setState(() {
      _location = position;
      final converted = CoordinateTransform.wgs84ToGcj02(point);
      final latLng = LatLng(converted.latitude, converted.longitude);
      _locationMarker =
          _locationMarker?.copyWith(positionParam: latLng) ??
          Marker(position: latLng, anchor: const Offset(.5, .5));
      _status = !fresh
          ? '收到过期定位，正在等待新的定位'
          : acceptable
          ? (_measuring ? '测量中，沿田块边界行走' : '定位成功，可开始测量')
          : '定位精度不足，等待精度达到 ${_maxAccuracy.toStringAsFixed(0)} 米以内';
      if (_measuring &&
          !_manualPointPending &&
          acceptable &&
          (_points.isEmpty ||
              Geolocator.distanceBetween(
                    _points.last.latitude,
                    _points.last.longitude,
                    point.latitude,
                    point.longitude,
                  ) >=
                  _minDistance)) {
        _points.add(point);
      }
    });
    if (_centerOnNextFix && fresh && _mapController != null) _centerMap();
  }

  void _centerMap() {
    final position = _location;
    final controller = _mapController;
    if (position == null || controller == null) return;
    final converted = CoordinateTransform.wgs84ToGcj02(
      GeoPoint(position.latitude, position.longitude),
    );
    _centerOnNextFix = false;
    controller.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(converted.latitude, converted.longitude),
        18,
      ),
    );
  }

  Future<void> _message(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshLocation({bool center = false}) async {
    if (_locating || !_authorized) return;
    _locating = true;
    if (center) _centerOnNextFix = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted || !_foreground) return;
      _onPosition(position);
      if (center && _mapController != null) _centerMap();
    } on TimeoutException {
      if (mounted && center) await _message('定位超时，请到室外空旷处并确认手机已开启精确定位，然后重试。');
    } catch (_) {
      if (mounted && center) await _message('无法获取当前位置，请检查手机定位服务和应用定位权限。');
    } finally {
      _locating = false;
    }
  }

  Future<void> _startOrPause() async {
    if (!_authorized) {
      _message('请先同意隐私提示并授予定位权限');
      return;
    }
    if (_measuring) {
      setState(() {
        _measurementGeneration++;
        _measuring = false;
        _status = '测量已暂停，可继续或完成';
      });
      _message('测量已暂停');
      return;
    }
    if (!_hasUsableLocation) {
      await _refreshLocation();
      if (!mounted || !_foreground) return;
      if (!_hasUsableLocation) {
        final location = _location;
        final detail = location == null
            ? '尚未获取到位置'
            : DateTime.now().difference(location.timestamp).abs() >=
                  const Duration(seconds: 20)
            ? '当前位置已超过20秒'
            : '当前精度约 ±${location.accuracy.toStringAsFixed(0)} 米';
        await _message(
          '$detail，测量需要${_maxAccuracy.toStringAsFixed(0)}米以内的有效定位。请到室外空旷处，确认已授予精确位置，然后重试。',
        );
        return;
      }
    }
    setState(() {
      if (_finished) {
        _points.clear();
        _finished = false;
      }
      _measuring = true;
      _measurementGeneration++;
      if (_points.isEmpty) {
        _points.add(GeoPoint(_location!.latitude, _location!.longitude));
      }
      _status = '测量中，沿田块边界行走';
    });
    _message('开始采点，请沿田块边界行走');
  }

  Future<void> _addCurrentPoint() async {
    if (!_measuring || !_foreground || !_authorized) {
      await _message('请先开始测量并保持应用在前台，再手动添加边界点。');
      return;
    }
    if (_locating || _manualPointPending) {
      await _message('正在获取位置，请稍候。');
      return;
    }
    final generation = _measurementGeneration;
    setState(() {
      _locating = true;
      _manualPointPending = true;
    });
    String? message;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted ||
          !_foreground ||
          !_authorized ||
          !_measuring ||
          generation != _measurementGeneration) {
        return;
      }
      final result = SamplingPolicy.evaluate(
        position,
        maxAccuracy: _maxAccuracy,
        now: DateTime.now(),
        previous: _points.isEmpty ? null : _points.last,
        minimumDistance: 0.5,
      );
      switch (result) {
        case SampleResult.accepted:
          _onPosition(position);
          setState(
            () => _points.add(GeoPoint(position.latitude, position.longitude)),
          );
          message = '已添加当前位置，当前共有 ${_points.length} 个边界点。';
        case SampleResult.inaccurate:
          message =
              '当前定位精度约 ±${position.accuracy.toStringAsFixed(0)} 米，未达到设置的 ${_maxAccuracy.toStringAsFixed(0)} 米要求，未添加点。请到室外等待定位改善后重试。';
        case SampleResult.stale:
          message = '获取的位置已过期，未添加点。请等待新的定位后重试。';
        case SampleResult.duplicate:
          message = '当前位置与上一个边界点距离不足 0.5 米，未重复添加。';
        case SampleResult.invalid:
          message = '获取的位置或精度无效，未添加点。请检查定位服务后重试。';
      }
    } on TimeoutException {
      message = '获取当前位置超时，未添加点。请到室外空旷处重试。';
    } catch (_) {
      message = '无法获取当前位置，未添加点。请检查定位服务和权限。';
    } finally {
      _locating = false;
      if (mounted) setState(() => _manualPointPending = false);
    }
    if (mounted && _foreground && generation == _measurementGeneration) {
      await _message(message);
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (_points.length < 3) {
      _message('至少需要 3 个有效边界点才能计算面积');
      return;
    }
    setState(() {
      _measurementGeneration++;
      _measuring = false;
      _status = '测量已暂停，请确认是否保存';
    });
    final controller = TextEditingController(
      text: '田块 ${DateTime.now().month}月${DateTime.now().day}日',
    );
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('保存测量记录'),
        content: TextField(
          controller: controller,
          maxLength: 50,
          decoration: const InputDecoration(labelText: '田块名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('暂不保存'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.pop(context, name);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (name == null) {
      setState(() => _status = '尚未保存，可继续测量或点击完成保存');
      return;
    }
    setState(() => _saving = true);
    try {
      await _store.addRecord(
        MeasurementRecord(
          name: name,
          createdAt: DateTime.now(),
          points: List.of(_points),
        ),
      );
      if (!mounted) return;
      setState(() {
        _finished = true;
        _status = '测量记录已保存到本机';
      });
      await _message('测量记录已保存，可在右上角历史记录查看。');
    } catch (_) {
      if (mounted) {
        setState(() => _status = '保存失败，可再次点击完成重试');
        await _message('保存失败，测量点仍保留在当前页面，请重试。');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!_supported) {
      content = const Center(child: Text('请在 Android 或 iOS 设备上使用定位测量。'));
    } else if (!_consented) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status, textAlign: TextAlign.center),
            ),
            FilledButton(
              onPressed: _requestConsent,
              child: const Text('阅读隐私提示并授权'),
            ),
          ],
        ),
      );
    } else if (!_authorized) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (_permissionDeniedForever) {
                    await Geolocator.openAppSettings();
                  } else {
                    await _checkPermissionAndStart(request: true);
                  }
                },
                child: Text(_permissionDeniedForever ? '打开应用设置' : '检查并授权定位'),
              ),
              TextButton(
                onPressed: Geolocator.openLocationSettings,
                child: const Text('打开手机定位设置'),
              ),
            ],
          ),
        ),
      );
    } else if (_platformKey.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            '尚未配置当前平台的高德 Key。请填写 amap.local.json 并在运行参数中添加 --dart-define-from-file=amap.local.json。',
          ),
        ),
      );
    } else {
      AMapInitializer.init(
        context,
        apiKey: const AMapApiKey(androidKey: _androidKey, iosKey: _iosKey),
      );
      final mapPoints = _points.map((point) {
        final p = CoordinateTransform.wgs84ToGcj02(point);
        return LatLng(p.latitude, p.longitude);
      }).toList();
      final location = _location;
      final area = AreaCalculator.squareMeters(_points);
      content = Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_status, style: const TextStyle(fontSize: 13)),
                ),
                if (location != null)
                  Text('±${location.accuracy.toStringAsFixed(0)}米'),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                AMapWidget(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(30.657, 104.065),
                    zoom: 13,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _centerOnNextFix = true;
                    _centerMap();
                  },
                  markers: _locationMarker == null
                      ? {}
                      : {
                          _locationMarker!.copyWith(
                            iconParam:
                                _locationIcon ??
                                BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueAzure,
                                ),
                            infoWindowParam: const InfoWindow(title: '当前位置'),
                          ),
                        },
                  polylines: mapPoints.length < 2
                      ? {}
                      : {
                          Polyline(
                            points: mapPoints,
                            width: 4,
                            color: const Color(0xFF20744B),
                          ),
                        },
                  polygons: mapPoints.length < 3
                      ? {}
                      : {
                          Polygon(
                            points: mapPoints,
                            strokeWidth: 3,
                            strokeColor: const Color(0xFF20744B),
                            fillColor: const Color(0x442F9A63),
                          ),
                        },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'locate',
                    onPressed: () => _refreshLocation(center: true),
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(area / AreaCalculator.squareMetersPerMu).toStringAsFixed(2)} 亩',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${area.toStringAsFixed(0)} 平方米 · ${_points.length} 点',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '周长 ${AreaCalculator.perimeterMeters(_points).toStringAsFixed(0)} 米 · 点间距≥${_minDistance.toStringAsFixed(0)}米 · 前台测量',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _measuring && !_manualPointPending
                        ? _addCurrentPoint
                        : null,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(_manualPointPending ? '正在获取当前位置…' : '当前位置加点'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _startOrPause,
                        icon: Icon(_measuring ? Icons.pause : Icons.play_arrow),
                        label: Text(
                          _measuring
                              ? '暂停测量'
                              : _points.isEmpty || _finished
                              ? '开始测量'
                              : '继续测量',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving || _finished ? null : _finish,
                        icon: const Icon(Icons.check),
                        label: const Text('完成测量'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    return DoubleBackToExit(
      hasUnsavedChanges: _points.isNotEmpty && !_finished,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('田亩通 · 地块测量'),
          actions: [
            IconButton(
              onPressed: _openHistory,
              tooltip: '测量记录',
              icon: const Icon(Icons.history_rounded),
            ),
            IconButton(
              onPressed: _openSettings,
              tooltip: '测量设置',
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: content,
      ),
    );
  }
}

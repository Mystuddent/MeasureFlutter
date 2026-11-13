import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intercepts Android back only on the root route, leaving child routes alone.
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    this.hasUnsavedChanges = false,
    this.onExit,
  });

  final Widget child;
  final bool hasUnsavedChanges;
  final VoidCallback? onExit;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  Timer? _timer;
  OverlayEntry? _hint;

  void _clearHint() {
    _timer?.cancel();
    _timer = null;
    _hint?.remove();
    _hint = null;
  }

  void _onBack() {
    if (_timer?.isActive ?? false) {
      _clearHint();
      if (widget.onExit != null) {
        widget.onExit!();
      } else {
        SystemNavigator.pop();
      }
      return;
    }
    _hint = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: Center(
          child: Material(
            color: Colors.black.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Text(
                widget.hasUnsavedChanges ? '再按一次退出应用\n未保存的测量将丢失' : '再按一次退出应用',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_hint!);
    _timer = Timer(const Duration(seconds: 2), _clearHint);
  }

  @override
  void dispose() {
    _clearHint();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: kIsWeb || defaultTargetPlatform != TargetPlatform.android,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _onBack();
      }
    },
    child: widget.child,
  );
}

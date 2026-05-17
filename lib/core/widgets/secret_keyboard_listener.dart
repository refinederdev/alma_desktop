import 'dart:async' show Timer, unawaited;

import 'package:alma_desktop/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// يفتح إعدادات الخادم عند الضغط المستمر على Shift+R لمدة 10 ثوانٍ.
class SecretKeyboardListener extends StatefulWidget {
  const SecretKeyboardListener({super.key, required this.child});

  final Widget child;

  static const Duration holdDuration = Duration(seconds: 10);

  @override
  State<SecretKeyboardListener> createState() => _SecretKeyboardListenerState();
}

class _SecretKeyboardListenerState extends State<SecretKeyboardListener> {
  Timer? _holdTimer;
  bool _activatedThisHold = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    _cancelHoldTimer();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    _syncHoldState();
    return false;
  }

  void _syncHoldState() {
    if (_isSecretComboActive()) {
      if (_holdTimer == null) {
        _activatedThisHold = false;
        _holdTimer = Timer(SecretKeyboardListener.holdDuration, _openServerConfig);
      }
    } else {
      _cancelHoldTimer();
      _activatedThisHold = false;
    }
  }

  bool _isSecretComboActive() {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isShiftPressed &&
        keyboard.logicalKeysPressed.contains(LogicalKeyboardKey.keyR);
  }

  void _openServerConfig() {
    if (_activatedThisHold) return;
    _activatedThisHold = true;
    _cancelHoldTimer();

    if (Get.currentRoute == AppRoutes.serverConfig) return;
    unawaited(Get.toNamed(AppRoutes.serverConfig));
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

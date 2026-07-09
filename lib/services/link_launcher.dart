import 'package:flutter/services.dart';

class LinkLauncher {
  LinkLauncher._();

  static const _channel = MethodChannel('math_challenge/link_launcher');

  static Future<bool> open(String url) async {
    try {
      return await _channel.invokeMethod<bool>('open', {'url': url}) ?? false;
    } catch (_) {
      return false;
    }
  }
}

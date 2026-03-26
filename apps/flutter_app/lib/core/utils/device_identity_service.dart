import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceIdentityService {
  DeviceIdentityService({DeviceInfoPlugin? deviceInfoPlugin})
      : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<String> fingerprint() async {
    final package = await PackageInfo.fromPlatform();
    final payload = <String, String>{
      'platform': defaultTargetPlatform.name,
      'package': package.packageName,
      'version': package.version,
    };

    if (kIsWeb) {
      final info = await _deviceInfoPlugin.webBrowserInfo;
      payload['browser'] = info.browserName.name;
      payload['userAgent'] = info.userAgent ?? 'unknown';
    } else {
      try {
        final info = await _deviceInfoPlugin.deviceInfo;
        payload['device'] = info.data.toString();
      } catch (_) {
        payload['device'] = 'unknown';
      }
    }

    return sha256.convert(utf8.encode(jsonEncode(payload))).toString();
  }
}

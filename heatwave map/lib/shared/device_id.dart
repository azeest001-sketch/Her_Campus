import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceId {
  static const _key = 'anon_device_id';

  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }

  /// Hash a radio identifier so raw MAC/SSID is never stored or uploaded.
  static String hashSignalId(String raw) {
    return sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
  }
}

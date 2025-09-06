import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Call this after each scan to record its details:
Future<void> saveScanResult(String type, String result, bool isSafe) async {
  final prefs = await SharedPreferences.getInstance();
  final history = prefs.getStringList('scan_history') ?? [];

  final newEntry = {
    'type': type,
    'time': DateTime.now().toIso8601String(),
    'result': result,
    'status': isSafe ? 'Safe' : 'Threat Detected',
  };
  history.add(jsonEncode(newEntry));
  await prefs.setStringList('scan_history', history);
}

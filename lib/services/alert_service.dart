// alert_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';
import '../config.dart';

class AlertService {
  static const String apiUrl = '${AppConfig.baseUrl}/api/alerts/';

  static Future<List<Alert>> fetchAlerts() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => Alert.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load alerts');
    }
  }
}

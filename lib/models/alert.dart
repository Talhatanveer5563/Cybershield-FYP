// alert.dart
class Alert {
  final String ip;
  final String mac;
  final DateTime timestamp;

  Alert({required this.ip, required this.mac, required this.timestamp});

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      ip: json['ip'],
      mac: json['mac'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

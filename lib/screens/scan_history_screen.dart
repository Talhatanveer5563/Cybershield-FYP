import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
 
class ScanHistoryScreen extends StatefulWidget {
  @override
  _ScanHistoryScreenState createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, dynamic>> scanHistory = [];

  @override
  void initState() {
    super.initState();
    loadScanHistory();
  }

  Future<void> loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('scan_history') ?? [];

    setState(() {
      scanHistory = history
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList(); // newest first
    });
  }

  String formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: scanHistory.isEmpty
          ? const Center(
        child: Text(
          'No scan history found.',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: scanHistory.length,
        itemBuilder: (context, index) {
          final scan = scanHistory[index];
          final time = scan['time'] ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                scan['status'] == 'Dangerous'
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: scan['status'] == 'Dangerous' ? Colors.red : Colors.green,
              ),
              title: Text(
                scan['type'] ?? 'Scan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scan['result'] ?? ''),
                  if (scan['url'] != null)
                    Text('URL: ${scan['url']}', style: TextStyle(fontSize: 12)),
                  Text(
                    formatDate(time),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

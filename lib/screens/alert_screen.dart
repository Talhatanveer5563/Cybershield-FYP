import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import '../models/alert.dart';
import 'package:intl/intl.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({Key? key}) : super(key: key);

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  List<Alert> alerts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  @override
  void dispose() {
    // Cleanup if needed in the future
    super.dispose();
  }

  Future<void> fetchAlerts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedAlerts = await AlertService.fetchAlerts();
      setState(() {
        alerts = fetchedAlerts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch alerts. Pull down to retry.';
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch alerts: $e')),
      );
    }
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown time';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Intrusion Alerts")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchAlerts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchAlerts,
        child: alerts.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 300),
            Center(child: Text("No intrusion alerts found.")),
          ],
        )
            : ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text("IP: ${alert.ip ?? 'Unknown'}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MAC: ${alert.mac ?? 'Unknown'}"),
                    Text("Time: ${formatDate(alert.timestamp)}"),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

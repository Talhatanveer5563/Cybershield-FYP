import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class WifiMonitorScreen extends StatefulWidget {
  @override
  _WifiMonitorScreenState createState() => _WifiMonitorScreenState();
}

class _WifiMonitorScreenState extends State<WifiMonitorScreen> {
  List devices = [];
  String error = "";
  bool isLoading = false;

  Future<void> fetchDevices() async {
    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      final response = await http.get(Uri.parse("${AppConfig.baseUrl}/api/wifi_scan/"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['devices'] is List) {
          setState(() {
            devices = data['devices'];
            error = "";
          });
        } else {
          setState(() {
            error = "Invalid data format received.";
            devices = [];
          });
        }
      } else {
        setState(() {
          error = "Error fetching devices: ${response.statusCode}";
          devices = [];
        });
      }
    } catch (e) {
      setState(() {
        error = "Could not connect to backend.";
        devices = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : fetchDevices,
        backgroundColor: isLoading ? Colors.grey : Colors.black,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh),
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black.withOpacity(0.3),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("WiFi Monitor"),
        backgroundColor: Colors.white.withOpacity(0.3),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: fetchDevices,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: isLoading && devices.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : error.isNotEmpty && devices.isEmpty
                          ? Center(
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                          : devices.isEmpty
                          ? const Center(
                        child: Text(
                          "No devices found.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Device Info"),
                                  content: Text(
                                    "IP: ${device['ip'] ?? 'N/A'}\n"
                                        "MAC: ${device['mac'] ?? 'N/A'}\n"
                                        "Known: ${device['known'] == true ? 'Yes' : 'No'}",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    )
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        device['known'] == true
                                            ? Icons.verified
                                            : Icons.warning,
                                        color: device['known'] == true
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "IP: ${device['ip'] ?? 'N/A'}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16),
                                          ),
                                          Text(
                                            "MAC: ${device['mac'] ?? 'N/A'}",
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    device['known'] == true ? "Known" : "Unknown",
                                    style: TextStyle(
                                      color: device['known'] == true
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

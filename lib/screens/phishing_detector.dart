import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import '../utils/scan_history_helper.dart';

class PhishingDetectorScreen extends StatefulWidget {
  @override
  _PhishingDetectorScreenState createState() => _PhishingDetectorScreenState();
}

class _PhishingDetectorScreenState extends State<PhishingDetectorScreen> {
  final TextEditingController urlController = TextEditingController();
  String result = "";
  Map<String, dynamic> domainInfo = {};
  Map<String, dynamic> apkReport = {};
  String screenshotUrl = "";
  int total = 0, dangerous = 0, safe = 0;
  bool isLoading = false;


  void scanURL() async {
    final url = urlController.text.trim();

    if (url.isEmpty || !(url.startsWith("http://") || url.startsWith("https://"))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid URL.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
      domainInfo = {};
      apkReport = {};
      screenshotUrl = "";
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/scan_url/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scanResult = data['result'] ?? "Unknown";
        final isSafe = (scanResult.toString().toLowerCase() != "dangerous");

        await saveScanResult("Phishing Link Scan", scanResult, isSafe);

        setState(() {
          result = scanResult;
          domainInfo = data['domain_info'] ?? {};
          screenshotUrl = data['screenshot'] ?? "";
          apkReport = data['apk_report'] ?? {};
        });

        await fetchStats();
      } else {
        setState(() {
          result = "Error scanning URL.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error. Please try again.")),
        );
      }
    } catch (e) {
      setState(() {
        result = "Failed to connect to server.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse("${AppConfig.baseUrl}/api/stats/"));

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final summary = data['summary'];
        setState(() {
          total = summary['total'] ?? 0;
          dangerous = summary['dangerous'] ?? 0;
          safe = summary['safe'] ?? 0;
        });

        final recent = data['recent_scans'] as List;
        for (var scan in recent) {
          print("Recent Scan → URL: ${scan['url']}, Result: ${scan['result']}, Date: ${scan['scanned_at']}");
        }

      } else {
        print("Failed to fetch stats, status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in fetchStats(): $e");
    }
  }


  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white.withOpacity(0.2),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Phishing URL Scanner"),
        backgroundColor: Colors.white.withOpacity(0),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width > 600 ? 600 : double.infinity,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter URL to Scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: urlController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                hintText: 'https://example.com',
                                hintStyle: const TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            isLoading
                                ? const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                                : ElevatedButton(
                              onPressed: scanURL,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.4),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Scan"),
                            ),
                            const SizedBox(height: 20),
                            if (result.isNotEmpty) ...[
                              Text(
                                "Result: $result",
                                style: TextStyle(
                                  color: result.toLowerCase() == 'dangerous'
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (domainInfo.isNotEmpty) ...[
                              const Text("Domain Info:",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              ...domainInfo.entries.map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "${entry.key}:",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 12),
                            ],

                            if (apkReport.isNotEmpty) ...[
                              const Text("APK Report:",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                jsonEncode(apkReport),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (screenshotUrl.isNotEmpty) ...[
                              const Text("Screenshot:",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    screenshotUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Text(
                                        "Failed to load screenshot",
                                        style: TextStyle(color: Colors.redAccent),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  const Text(
                                    "Scan Statistics",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text("Total Scans: $total",
                                      style: const TextStyle(color: Colors.white)),
                                  Text("Dangerous: $dangerous",
                                      style: const TextStyle(color: Colors.redAccent)),
                                  Text("Safe: $safe",
                                      style: const TextStyle(color: Colors.greenAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

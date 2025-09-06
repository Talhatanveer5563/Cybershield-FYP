import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class EmailAnalyzerScreen extends StatefulWidget {
  @override
  _EmailAnalyzerScreenState createState() => _EmailAnalyzerScreenState();
}

class _EmailAnalyzerScreenState extends State<EmailAnalyzerScreen> {
  final TextEditingController emailController = TextEditingController();
  Map<String, dynamic>? report;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void analyzeEmail() async {
    final emailContent = emailController.text.trim();
    if (emailContent.isEmpty) {
      setState(() {
        errorMessage = "Please enter the email content before analyzing.";
        report = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      report = null;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/analyze_email/"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': emailContent}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          report = data;
          errorMessage = null;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'] ?? "Error analyzing email.";
          report = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to connect to the server. Please try again.";
        report = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
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

  void clearInput() {
    setState(() {
      emailController.clear();
      report = null;
      errorMessage = null;
    });
  }

  Widget buildReport() {
    if (report == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        _reportText("Phishing Detected", report!['is_phishing'] ? "Yes" : "No",
            report!['is_phishing'] ? Colors.red : Colors.green),
        _reportText("Phishing Score", (report!['phishing_score'] ?? 0).toString()),
        _reportText("Sender Reputation", report!['sender_reputation'] ?? "Unknown"),
        _reportList("Suspicious Keywords", report!['suspicious_keywords']),
        _reportList("Links Found", report!['links']),
        _reportList("Suspicious Domains", report!['suspicious_domains']),
        _reportList("HTML Elements", report!['html_elements']),
        _reportText("Summary", report!['analysis_summary'] ?? "No summary."),
      ],
    );
  }

  Widget _reportText(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: valueColor ?? Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportList(String label, List<dynamic>? items) {
    if (items == null || items.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                "- $item",
                style: const TextStyle(color: Colors.white70),
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Email Analyzer"),
        backgroundColor: Colors.white.withOpacity(0.4),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Paste Email Content',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: emailController,
                                maxLines: 10,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.3),
                                  hintText: 'Enter email content here...',
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: emailController.text.isNotEmpty
                                      ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white70),
                                    onPressed: clearInput,
                                  )
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (errorMessage != null && value.trim().isNotEmpty) {
                                      errorMessage = null;
                                    }
                                  });
                                },
                              ),
                              if (errorMessage != null && errorMessage!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 4),
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: isLoading ? null : analyzeEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                                    : const Text("Analyze"),
                              ),
                              const SizedBox(height: 20),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: report != null ? buildReport() : const SizedBox.shrink(),
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
          ),
        ],
      ),
    );
  }
}

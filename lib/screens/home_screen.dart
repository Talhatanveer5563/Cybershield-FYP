import 'dart:ui';
import 'package:Cybershield/screens/scan_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'phishing_detector.dart';
import 'email_analyzer.dart';
import 'wifi_scanner.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black.withOpacity(0.3),
      appBar: AppBar(
        title: const Text("Cybershield"),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.3),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: ListView(
                children: [
                  // Greeting + Logo
                  Row(
                    children: [

                        Image.asset(
                          'assets/icon.png',
                          height: isSmallScreen ? 80 : 120,
                        ),


                      const SizedBox(width: 10),
                      Text(
                        "Hello👋",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      height: 180,
                      child: Lottie.asset('assets/scan.json'),
                    ),
                  ),
                  const SizedBox(height: 20),


                  // Protection Status
                  frostedCard(
                    context,
                    title: "Protection Status",
                    child: Row(
                      children: const [
                        Icon(Icons.shield, color: Colors.greenAccent),
                        SizedBox(width: 8),
                        Text(
                          "You are protected",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),


                  frostedCard(
                    context,
                    title: "View Recent Scans",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ScanHistoryScreen()),
                      );
                    },
                    centerText: true,
                  ),

                  // Quick Cards
                  Row(
                    children: [
                      Expanded(
                        child: frostedCard(
                          context,
                          title: "Start New Scan",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PhishingDetectorScreen()),
                            );
                          },
                          centerText: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: frostedCard(
                          context,
                          title: "Permissions",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => WifiMonitorScreen()),
                            );
                          },
                          centerText: true,
                        ),
                      ),
                    ],
                  ),

                  // Features List

                  // Lottie Scan Animation

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget frostedCard(BuildContext context,
      {required String title,
        Widget? child,
        VoidCallback? onTap,
        bool centerText = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment:
          centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: centerText ? TextAlign.center : TextAlign.start,
            ),
            const SizedBox(height: 6),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Widget frostedListTile(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: ListTile(
            title: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

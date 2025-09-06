import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool realTimeScanning = true;
  bool autoDeletePhishing = false;
  bool notifyThreats = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      realTimeScanning = prefs.getBool('realTimeScanning') ?? true;
      autoDeletePhishing = prefs.getBool('autoDeletePhishing') ?? false;
      notifyThreats = prefs.getBool('notifyThreats') ?? true;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: const Text("Enable Real-time Scanning"),
            value: realTimeScanning,
            onChanged: (val) {
              setState(() => realTimeScanning = val);
              _updateSetting('realTimeScanning', val);
            },
          ),
          SwitchListTile(
            title: const Text("Auto Delete Detected Phishing Emails"),
            value: autoDeletePhishing,
            onChanged: (val) {
              setState(() => autoDeletePhishing = val);
              _updateSetting('autoDeletePhishing', val);
            },
          ),
          SwitchListTile(
            title: const Text("Notification Alerts for Threats"),
            value: notifyThreats,
            onChanged: (val) {
              setState(() => notifyThreats = val);
              _updateSetting('notifyThreats', val);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About App"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Cybershield",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 Cybershield Inc.",
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'This is the privacy policy of Cybershield.\n\n'
                'We respect your privacy and are committed to protecting your personal data. '
                'This policy explains how we collect, use, and safeguard your information.\n\n'
                '1. Data Collection\n'
                '- We collect data only necessary for app functionality.\n\n'
                '2. Data Usage\n'
                '- Your data is used solely to provide app features and improve the user experience.\n\n'
                '3. Data Protection\n'
                '- We implement industry-standard measures to secure your data.\n\n'
                'For any questions or concerns, contact support@cybershield.com.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

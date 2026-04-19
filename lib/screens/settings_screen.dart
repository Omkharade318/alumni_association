import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showEmail = true;
  bool _showPhone = true;
  bool _showCompany = true;
  bool _showLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'Settings', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Email'),
              value: _showEmail,
              onChanged: (v) => setState(() => _showEmail = v),
              activeColor: AppTheme.primaryRed,
            ),
            SwitchListTile(
              title: const Text('Show Phone'),
              value: _showPhone,
              onChanged: (v) => setState(() => _showPhone = v),
              activeColor: AppTheme.primaryRed,
            ),
            SwitchListTile(
              title: const Text('Show Current Company'),
              value: _showCompany,
              onChanged: (v) => setState(() => _showCompany = v),
              activeColor: AppTheme.primaryRed,
            ),
            SwitchListTile(
              title: const Text('Show Current Location'),
              value: _showLocation,
              onChanged: (v) => setState(() => _showLocation = v),
              activeColor: AppTheme.primaryRed,
            ),
            const SizedBox(height: 24),
            const Text('Other', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications, color: AppTheme.primaryRed),
              title: const Text('Notification Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: AppTheme.primaryRed),
              title: const Text('Request Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help, color: AppTheme.primaryRed),
              title: const Text('Help'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info, color: AppTheme.primaryRed),
              title: const Text('About Us'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'))),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

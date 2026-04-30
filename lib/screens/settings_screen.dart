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
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: const AppAppBar(title: 'Settings', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Privacy & Profile Visibility'),
            _buildSettingsGroup(
              children: [
                _buildSwitchTile(
                  title: 'Show Email',
                  subtitle: 'Allow others to see your email address',
                  icon: Icons.email_outlined,
                  iconColor: Colors.blue.shade600,
                  value: _showEmail,
                  onChanged: (v) => setState(() => _showEmail = v),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Show Phone',
                  subtitle: 'Display your phone number on your profile',
                  icon: Icons.phone_outlined,
                  iconColor: Colors.green.shade600,
                  value: _showPhone,
                  onChanged: (v) => setState(() => _showPhone = v),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Show Current Company',
                  subtitle: 'Make your professional details public',
                  icon: Icons.business_center_outlined,
                  iconColor: Colors.purple.shade600,
                  value: _showCompany,
                  onChanged: (v) => setState(() => _showCompany = v),
                ),
                _buildDivider(),
                _buildSwitchTile(
                  title: 'Show Current Location',
                  subtitle: 'Let others see what city you are in',
                  icon: Icons.location_on_outlined,
                  iconColor: Colors.orange.shade600,
                  value: _showLocation,
                  onChanged: (v) => setState(() => _showLocation = v),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildSectionHeader('Preferences & Support'),
            _buildSettingsGroup(
              children: [
                _buildNavigationTile(
                  title: 'Notification Settings',
                  icon: Icons.notifications_none_rounded,
                  iconColor: AppTheme.primaryRed,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildNavigationTile(
                  title: 'Request Settings',
                  icon: Icons.person_add_outlined,
                  iconColor: Colors.teal.shade600,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildNavigationTile(
                  title: 'Help & Support',
                  icon: Icons.help_outline_rounded,
                  iconColor: Colors.indigo.shade500,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildNavigationTile(
                  title: 'About Us',
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.grey.shade700,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Settings saved successfully'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 64), // Aligns divider with text, skipping the icon
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryRed,
              activeTrackColor: AppTheme.primaryRed.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
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
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _showEmail = user.showEmail;
        _showPhone = user.showPhone;
        _showCompany = user.showCompany;
        _showLocation = user.showLocation;
      }
      _isInitialized = true;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateProfile({
        'showEmail': _showEmail,
        'showPhone': _showPhone,
        'showCompany': _showCompany,
        'showLocation': _showLocation,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAboutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        // Handles safe area at the bottom for devices with no home button (iOS indicator)
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(ctx).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hugs the content
          children: [
            // Modern Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Premium Logo Treatment
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_rounded, color: AppTheme.primaryRed, size: 48),
            ),
            const SizedBox(height: 16),

            // App Name
            const Text(
              'Alumni Connect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Modern Version Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'A dedicated platform bridging the gap between alumni and students, fostering a community of mentorship, networking, and growth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5, // Increased line height for readability
              ),
            ),

            const SizedBox(height: 32),

            // Copyright / Footer (Automatically uses current year context)
            Text(
              '© 2026 Alumni Connect Community',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings coming soon!')));
                  },
                ),
                _buildDivider(),
                _buildNavigationTile(
                  title: 'Request Settings',
                  icon: Icons.person_add_outlined,
                  iconColor: Colors.teal.shade600,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request settings coming soon!')));
                  },
                ),
                _buildDivider(),
                _buildNavigationTile(
                  title: 'Help & Support',
                  icon: Icons.help_outline_rounded,
                  iconColor: Colors.indigo.shade500,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support email: noobdiAishwarya@alumni.com')));
                  },
                ),
                _buildDivider(),
                _buildNavigationTile(
                  title: 'About Us',
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.grey.shade700,
                  onTap: () => _showAboutBottomSheet(context),
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
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
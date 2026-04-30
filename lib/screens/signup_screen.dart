import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/profile_avatar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _branchController = TextEditingController();
  final _batchController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _cityController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _profileImage;
  String? _selectedBranch;
  String? _selectedDegree;
  String? _profileImageUrl;
  final StorageService _storage = StorageService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _branchController.dispose();
    _batchController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // Dismiss keyboard

    final success = await context.read<AuthProvider>().signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      branch: _selectedBranch ?? _branchController.text.trim(),
      batch: _batchController.text.trim(),
      company: _companyController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      city: _cityController.text.trim(),
      degree: _selectedDegree,
      profileImage: null,
    );

    if (success && mounted) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (_profileImage != null && uid != null) {
        _profileImageUrl = (await _storage.uploadProfileImage(uid, _profileImage!)) as String?;
        await context.read<AuthProvider>().updateProfileImage(_profileImageUrl!);
      }
      if (mounted) {
        context.read<AuthProvider>().clearError();
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modern Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: AppTheme.primaryRed, size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the ${AppConstants.appName} community',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: _profileImage != null
                              ? ClipOval(child: Image.file(_profileImage!, width: 110, height: 110, fit: BoxFit.cover))
                              : ProfileAvatar(name: _nameController.text.isNotEmpty ? _nameController.text : 'A', size: 110),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryRed, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Section 1: Personal Information
                _buildSectionTitle('Personal Information'),
                _buildFormCard([
                  AppTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    validator: (v) => Validators.validateRequired(v, 'Full name'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade500),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade500),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Section 2: Academic Details
                _buildSectionTitle('Academic Background'),
                _buildFormCard([
                  _buildModernDropdown(
                    value: _selectedDegree,
                    label: 'Degree',
                    items: AppConstants.degrees.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _selectedDegree = v),
                    validator: (v) => Validators.validateRequired(v ?? _selectedDegree, 'Degree'),
                  ),
                  const SizedBox(height: 16),
                  _buildModernDropdown(
                    value: _selectedBranch,
                    label: 'Branch',
                    items: AppConstants.branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) => setState(() => _selectedBranch = v),
                    validator: (v) => Validators.validateRequired(v ?? _selectedBranch, 'Branch'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Batch (Year of passing)',
                    controller: _batchController,
                    keyboardType: TextInputType.number,
                    validator: Validators.validateBatch,
                  ),
                ]),
                const SizedBox(height: 24),

                // Section 3: Professional Details
                _buildSectionTitle('Professional Profile'),
                _buildFormCard([
                  AppTextField(
                    label: 'Current Company',
                    controller: _companyController,
                    validator: (v) => Validators.validateRequired(v, 'Company'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Job Title',
                    controller: _jobTitleController,
                    validator: (v) => Validators.validateRequired(v, 'Job title'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Current City',
                    controller: _cityController,
                    validator: (v) => Validators.validateRequired(v, 'City'),
                  ),
                ]),
                const SizedBox(height: 24),

                // Premium Error State
                if (authProvider.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Sign Up Button
                SizedBox(
                  height: 56,
                  child: AppButton(
                    text: 'Create Account',
                    onPressed: _signUp,
                    isLoading: authProvider.isLoading,
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or Sign Up With', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 32),

                // Premium Google Button
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                      final success = await context.read<AuthProvider>().signInWithGoogle();
                      if (success && mounted) {
                        context.read<AuthProvider>().clearError();
                        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                      }
                    },
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, size: 28),
                    ),
                    label: const Text(
                      'Sign Up with Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        children: const [
                          TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to keep section titles consistent
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // Helper widget to group fields into modern cards
  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // Helper widget to modernize dropdowns
  Widget _buildModernDropdown({
    required String? value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50, // Subtle fill to match inputs
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
        ),
      ),
    );
  }
}
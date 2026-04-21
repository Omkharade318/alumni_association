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
        // Clear any stale error before changing routes.
        context.read<AuthProvider>().clearError();
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, color: AppTheme.white, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Welcome', style: TextStyle(fontSize: 18, color: AppTheme.textGray)),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        _profileImage != null
                            ? ClipOval(
                                child: Image.file(_profileImage!, width: 100, height: 100, fit: BoxFit.cover),
                              )
                            : ProfileAvatar(name: _nameController.text, size: 100),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: AppTheme.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  validator: (v) => Validators.validateRequired(v, 'Full name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email or phone number',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBranch,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: AppConstants.branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() => _selectedBranch = v),
                  validator: (v) => Validators.validateRequired(v ?? _selectedBranch, 'Branch'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDegree,
                  decoration: const InputDecoration(labelText: 'Degree'),
                  items: AppConstants.degrees.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _selectedDegree = v),
                  validator: (v) => Validators.validateRequired(v ?? _selectedDegree, 'Degree'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Batch (Year of passing)',
                  controller: _batchController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateBatch,
                ),
                const SizedBox(height: 16),
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
                if (context.watch<AuthProvider>().error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.watch<AuthProvider>().error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  text: 'Sign Up',
                  onPressed: _signUp,
                  isLoading: context.watch<AuthProvider>().isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.dividerGray)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Or Sign Up With', style: TextStyle(color: AppTheme.textGray)),
                    ),
                    Expanded(child: Divider(color: AppTheme.dividerGray)),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: context.watch<AuthProvider>().isLoading
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
                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text('Sign Up with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textDark,
                    side: BorderSide(color: AppTheme.dividerGray),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: AppTheme.textGray),
                      children: [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

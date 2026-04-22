import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _batchController;
  
  String? _selectedBranch;
  String? _selectedDegree;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _cityController = TextEditingController(text: widget.user.city);
    _jobTitleController = TextEditingController(text: widget.user.jobTitle);
    _companyController = TextEditingController(text: widget.user.company);
    _batchController = TextEditingController(text: widget.user.batch);
    _selectedBranch = widget.user.branch;
    _selectedDegree = widget.user.degree;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'jobTitle': _jobTitleController.text.trim(),
        'company': _companyController.text.trim(),
        'batch': _batchController.text.trim(),
        'branch': _selectedBranch,
        'degree': _selectedDegree,
      };

      await FirestoreService().updateUser(widget.user.uid, updatedData);
      
      // If editing own profile, update local state
      final currentUserId = context.read<AuthProvider>().currentUser?.uid;
      if (currentUserId == widget.user.uid) {
        await context.read<AuthProvider>().refreshUser();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField('Full Name', _nameController, Icons.person),
                  _buildTextField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                  _buildTextField('City', _cityController, Icons.location_city),
                  
                  const SizedBox(height: 24),
                  const Text('Academic Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDropdown('Branch', AppConstants.branches, _selectedBranch, (v) => setState(() => _selectedBranch = v)),
                  _buildDropdown('Degree', AppConstants.degrees, _selectedDegree, (v) => setState(() => _selectedDegree = v)),
                  _buildTextField('Batch (Year)', _batchController, Icons.calendar_today, keyboardType: TextInputType.number),
                  
                  const SizedBox(height: 24),
                  const Text('Professional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField('Job Title', _jobTitleController, Icons.work),
                  _buildTextField('Company', _companyController, Icons.business),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _save,
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryRed),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.dividerGray),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? current, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: current,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.dividerGray),
          ),
        ),
      ),
    );
  }
}

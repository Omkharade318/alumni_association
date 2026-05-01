import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AdminJobFormScreen extends StatefulWidget {
  final JobModel? job;

  const AdminJobFormScreen({super.key, this.job});

  @override
  State<AdminJobFormScreen> createState() => _AdminJobFormScreenState();
}

class _AdminJobFormScreenState extends State<AdminJobFormScreen> {
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _applyLinkController = TextEditingController();

  File? _logoFile;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    if (job != null) {
      _titleController.text = job.title;
      _companyController.text = job.company;
      _locationController.text = job.location;
      _descriptionController.text = job.description ?? '';
      _logoUrlController.text = job.companyLogo ?? '';
      _applyLinkController.text = job.applyLink ?? '';
    }
    _logoUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _applyLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
        _logoUrlController.clear();
      });
    }
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final company = _companyController.text.trim();
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    final applyLink = _applyLinkController.text.trim();
    String? logoUrl = _logoUrlController.text.trim();

    if (title.isEmpty || company.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = 'Initializing...';
    });

    try {
      final oldLogo = widget.job?.companyLogo;

      if (_logoFile != null) {
        setState(() => _statusMessage = 'Uploading Logo...');
        // Delete old logo from Supabase if it exists
        if (oldLogo != null && oldLogo.contains('supabase')) {
          await StorageService().deleteImageFromUrl(oldLogo);
        }
        logoUrl = await StorageService().uploadImage(
          'job_logos',
          _logoFile!,
          onProgress: (percent) {
            if (mounted) {
              setState(() {
                _uploadProgress = percent;
              });
            }
          },
        ).timeout(const Duration(minutes: 5));
      } else if (oldLogo != null && logoUrl != oldLogo) {
        // Logo was changed manually or cleared - delete the old Supabase logo if applicable
        if (oldLogo.contains('supabase')) {
          await StorageService().deleteImageFromUrl(oldLogo);
        }
      }

      setState(() => _statusMessage = 'Saving Details...');
      final firestore = FirestoreService();

      if (widget.job == null) {
        final id = const Uuid().v4();
        final job = JobModel(
          id: id,
          title: title,
          company: company,
          companyLogo: logoUrl.isEmpty ? null : logoUrl,
          location: location,
          description: description,
          postedBy: user.uid,
          createdAt: DateTime.now(),
          applyLink: applyLink.isEmpty ? null : applyLink,
        );
        final adminName = context.read<AuthProvider>().currentUser?.name;
        await firestore.createJob(job, senderName: adminName);
      } else {
        final jobId = widget.job!.id;
        await firestore.updateJob(jobId, {
          'title': title,
          'company': company,
          'companyLogo': logoUrl.isEmpty ? null : logoUrl,
          'location': location,
          'description': description,
          'applyLink': applyLink.isEmpty ? null : applyLink,
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _statusMessage = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.job != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Job' : 'Create Job',
          style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Picker
              _buildInputLabel('Company Logo'),
              Center(
                child: GestureDetector(
                  onTap: _isSaving ? null : _pickLogo,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        if (_logoFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_logoFile!, fit: BoxFit.contain),
                          )
                        else if (_logoUrlController.text.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CachedNetworkImage(
                              imageUrl: _logoUrlController.text,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => Icon(Icons.business_rounded, size: 32, color: Colors.grey.shade400),
                            ),
                          )
                        else if (widget.job?.companyLogo != null && widget.job!.companyLogo!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CachedNetworkImage(
                              imageUrl: widget.job!.companyLogo!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => Icon(Icons.business_rounded, size: 32, color: Colors.grey.shade400),
                            ),
                          )
                        else
                          Icon(Icons.add_business_outlined, size: 32, color: AppTheme.primaryRed.withOpacity(0.8)),

                        if (_isSaving && _uploadProgress > 0 && _uploadProgress < 1)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildInputLabel('Job Title*'),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Senior Software Engineer',
                enabled: !_isSaving,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('Company Name*'),
              _buildTextField(
                controller: _companyController,
                hint: 'e.g. Tech Solutions Inc.',
                enabled: !_isSaving,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('Location*'),
              _buildTextField(
                controller: _locationController,
                hint: 'e.g. Mumbai, Maharashtra (Remote)',
                enabled: !_isSaving,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('Description'),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Requirements, responsibilities, and how to apply...',
                enabled: !_isSaving,
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('Application / LinkedIn Link (Optional)'),
              _buildTextField(
                controller: _applyLinkController,
                hint: 'e.g. https://linkedin.com/jobs/...',
                enabled: !_isSaving,
                icon: Icons.launch_rounded,
              ),
              const SizedBox(height: 20),

              _buildInputLabel('Company Logo URL (Optional)'),
              _buildTextField(
                controller: _logoUrlController,
                hint: 'Paste an external image link',
                enabled: !_isSaving && _logoFile == null,
                icon: Icons.link_rounded,
              ),
              const SizedBox(height: 40),

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
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                      const SizedBox(width: 12),
                      Text(_statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                      : Text(
                    isEditing ? 'Save Changes' : 'Create Job Posting',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool enabled,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 20) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
      ),
    );
  }
}

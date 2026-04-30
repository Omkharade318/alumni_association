import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../models/donation_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDonationFormScreen extends StatefulWidget {
  final DonationModel? donation;

  const AdminDonationFormScreen({super.key, this.donation});

  @override
  State<AdminDonationFormScreen> createState() => _AdminDonationFormScreenState();
}

class _AdminDonationFormScreenState extends State<AdminDonationFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetController = TextEditingController();

  String _category = AppConstants.donationCategories.first;
  File? _imageFile;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    final donation = widget.donation;
    if (donation != null) {
      _category = donation.category;
      _titleController.text = donation.title;
      _descriptionController.text = donation.description;
      _imageUrlController.text = donation.imageUrl ?? '';
      _targetController.text = donation.targetAmount.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    String? imageUrl = _imageUrlController.text.trim();
    final target = double.tryParse(_targetController.text.trim());

    if (title.isEmpty || description.isEmpty || target == null || target <= 0) {
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
      if (_imageFile != null) {
        setState(() => _statusMessage = 'Uploading Image...');
        imageUrl = await StorageService().uploadImage(
          'donations', 
          _imageFile!,
          onProgress: (percent) {
            if (mounted) {
              setState(() {
                _uploadProgress = percent;
              });
            }
          },
        ).timeout(const Duration(minutes: 5));
      }

      setState(() => _statusMessage = 'Saving Details...');
      final firestore = FirestoreService();

      if (widget.donation == null) {
        final id = const Uuid().v4();
        final donation = DonationModel(
          id: id,
          category: _category,
          title: title,
          description: description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          targetAmount: target,
          collectedAmount: 0,
          createdAt: DateTime.now(),
        );
        final adminName = context.read<AuthProvider>().currentUser?.name;
        await firestore.createDonation(donation, senderId: context.read<AuthProvider>().currentUser?.uid, senderName: adminName);
      } else {
        await firestore.updateDonationDetails(widget.donation!.id, {
          'category': _category,
          'title': title,
          'description': description,
          'imageUrl': imageUrl.isEmpty ? null : imageUrl,
          'targetAmount': target,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.donation == null ? 'Add Donation Campaign' : 'Edit Donation Campaign'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isSaving && _imageFile != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Image Picker with Progress
                GestureDetector(
                  onTap: _isSaving ? null : _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_imageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: 180),
                          )
                        else if (widget.donation?.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(widget.donation!.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 180),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to pick a campaign image', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        if (_isSaving && _uploadProgress > 0 && _uploadProgress < 1)
                          Container(
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(value: _uploadProgress, valueColor: const AlwaysStoppedAnimation(Colors.white)),
                                const SizedBox(height: 8),
                                Text('${(_uploadProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: AppConstants.donationCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: _isSaving ? null : (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUrlController,
                  enabled: !_isSaving && _imageFile == null,
                  decoration: const InputDecoration(labelText: 'Image URL (optional if photo picked)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _targetController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '₹',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(_statusMessage),
                        ],
                      )
                    : Text(widget.donation == null ? 'Create Campaign' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

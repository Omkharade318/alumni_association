import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AdminEventFormScreen extends StatefulWidget {
  final EventModel? event;

  const AdminEventFormScreen({super.key, this.event});

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  File? _imageFile;
  bool _isSaving = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _imageUrlController.text = event.imageUrl ?? '';
      _selectedDate = event.date;
      _locationController.text = event.location;
      // Try to parse time string (e.g., "10:00 AM") to TimeOfDay
      try {
        final timeParts = event.time.split(' ');
        if (timeParts.length == 2) {
          final hm = timeParts[0].split(':');
          var hour = int.parse(hm[0]);
          final minute = int.parse(hm[1]);
          if (timeParts[1].toUpperCase() == 'PM' && hour < 12) hour += 12;
          if (timeParts[1].toUpperCase() == 'AM' && hour == 12) hour = 0;
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        _selectedTime = TimeOfDay.now();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _locationController.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate.isBefore(now) ? now : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryRed),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryRed),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final time = _selectedTime.format(context);
    final location = _locationController.text.trim();
    String? imageUrl = _imageUrlController.text.trim();

    if (title.isEmpty || description.isEmpty || time.isEmpty || location.isEmpty) {
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
          'events',
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

      if (widget.event == null) {
        final id = const Uuid().v4();
        final event = EventModel(
          id: id,
          title: title,
          description: description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          date: _selectedDate,
          time: time,
          location: location,
          organizerId: user.uid,
          attendees: const [],
        );
        final adminName = context.read<AuthProvider>().currentUser?.name;
        await firestore.createEvent(event, senderName: adminName);
      } else {
        final eventId = widget.event!.id;
        await firestore.updateEventDetails(eventId, {
          'title': title,
          'description': description,
          'imageUrl': imageUrl.isEmpty ? null : imageUrl,
          'date': Timestamp.fromDate(_selectedDate),
          'time': time,
          'location': location,
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
    final isEditing = widget.event != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Soft modern background
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
          isEditing ? 'Edit Event' : 'Create Event',
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
              // Image Picker
              _buildInputLabel('Event Cover Image'),
              GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      // Base Image
                      if (_imageFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      else if (widget.event?.imageUrl != null && widget.event!.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(widget.event!.imageUrl!, fit: BoxFit.cover),
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppTheme.primaryRed.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 12),
                            Text('Tap to upload cover image', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          ],
                        ),

                      // Progress Overlay
                      if (_isSaving && _uploadProgress > 0 && _uploadProgress < 1)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Uploading...',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              _buildInputLabel('Event Title'),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Annual Alumni Meet 2026',
                enabled: !_isSaving,
              ),
              const SizedBox(height: 20),

              // Description
              _buildInputLabel('Description'),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Describe the event details, agenda, etc.',
                enabled: !_isSaving,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Location
              _buildInputLabel('Location'),
              _buildTextField(
                controller: _locationController,
                hint: 'e.g. Main Auditorium',
                enabled: !_isSaving,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Date'),
                        GestureDetector(
                          onTap: _isSaving ? null : _pickDate,
                          child: _buildSelectorCard(
                            icon: Icons.calendar_today_outlined,
                            text: _selectedDate.toLocal().toString().split(' ').first,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Time'),
                        GestureDetector(
                          onTap: _isSaving ? null : _pickTime,
                          child: _buildSelectorCard(
                            icon: Icons.access_time_rounded,
                            text: _selectedTime.format(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image URL Fallback
              _buildInputLabel('Image URL (Optional)'),
              _buildTextField(
                controller: _imageUrlController,
                hint: 'Paste an external image link',
                enabled: !_isSaving && _imageFile == null,
                icon: Icons.link_rounded,
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
                    isEditing ? 'Save Changes' : 'Create Event',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to consistently style input labels
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // Helper widget to consistently style text fields
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

  // Helper widget for Date/Time picker cards
  Widget _buildSelectorCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
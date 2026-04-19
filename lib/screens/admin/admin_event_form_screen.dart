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
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
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
      _timeController.text = event.time;
      _locationController.text = event.location;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _timeController.dispose();
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final time = _timeController.text.trim();
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
        await firestore.createEvent(event);
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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Add Event'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                      else if (widget.event?.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(widget.event!.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 180),
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to pick an event image', style: TextStyle(color: Colors.grey)),
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
                controller: _locationController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Time (e.g., 10:00 AM)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _pickDate,
                      child: Text('Date: ${_selectedDate.toLocal().toString().split(' ').first}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageUrlController,
                enabled: !_isSaving && _imageFile == null,
                decoration: const InputDecoration(labelText: 'Image URL (optional if photo picked)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                    : Text(isEditing ? 'Save Changes' : 'Create Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

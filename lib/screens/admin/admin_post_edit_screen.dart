import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';

class AdminPostEditScreen extends StatefulWidget {
  final PostModel post;

  const AdminPostEditScreen({super.key, required this.post});

  @override
  State<AdminPostEditScreen> createState() => _AdminPostEditScreenState();
}

class _AdminPostEditScreenState extends State<AdminPostEditScreen> {
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    await FirestoreService().updatePostContent(widget.post.id, content);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


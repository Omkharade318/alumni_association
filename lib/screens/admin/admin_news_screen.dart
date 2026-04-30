import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/news_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AdminNewsScreen extends StatelessWidget {
  const AdminNewsScreen({super.key});

  void _showNewsForm(BuildContext context, NewsModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsFormSheet(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, NewsModel news) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete News?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete “${news.title}”. This action cannot be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteNews(news.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('News deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'News & Updates',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showNewsForm(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publish News', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: firestore.getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final newsList = snapshot.data ?? [];

          if (newsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.campaign_rounded, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text('No news published', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Tap + to publish your first update.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), // Extra bottom padding for FAB
            itemCount: newsList.length,
            itemBuilder: (context, i) => _NewsAdminCard(
              news: newsList[i],
              onEdit: () => _showNewsForm(context, newsList[i]),
              onDelete: () => _confirmDelete(context, newsList[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Individual news card shown to the admin ─────────────────────────────────

class _NewsAdminCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NewsAdminCard({
    required this.news,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = news.imageUrl != null && news.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edge-to-Edge Header Image
          if (hasImage)
            Image.network(
              news.imageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metadata
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      news.createdBy,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(news.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Text(
                  news.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  news.body,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.black12),
                ),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text('Edit', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 16, color: Colors.red.shade600),
                            const SizedBox(width: 6),
                            Text('Delete', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom‑sheet form for adding / editing a news item ──────────────────────

class _NewsFormSheet extends StatefulWidget {
  final NewsModel? existing;
  const _NewsFormSheet({this.existing});

  @override
  State<_NewsFormSheet> createState() => _NewsFormSheetState();
}

class _NewsFormSheetState extends State<_NewsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _imageCtrl;
  File? _imageFile;
  bool _saving = false;
  String _statusMessage = '';
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title);
    _bodyCtrl = TextEditingController(text: widget.existing?.body);
    _imageCtrl = TextEditingController(text: widget.existing?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _imageCtrl.clear();
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _statusMessage = 'Initializing...';
      _uploadProgress = 0.0;
    });

    final user = context.read<AuthProvider>().currentUser;
    final firestore = FirestoreService();
    final storage = StorageService();

    String? imageUrl = _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim();

    try {
      if (_imageFile != null) {
        setState(() => _statusMessage = 'Uploading Image...');

        imageUrl = await storage.uploadImage(
          'news',
          _imageFile!,
          onProgress: (percent) {
            if (mounted) {
              setState(() {
                _uploadProgress = percent;
              });
            }
          },
        ).timeout(
          const Duration(minutes: 5),
          onTimeout: () => throw 'Upload timed out. Please check your connection.',
        );
      }

      setState(() {
        _statusMessage = 'Finalizing Update...';
        _uploadProgress = 1.0;
      });

      if (widget.existing == null) {
        final news = NewsModel(
          id: const Uuid().v4(),
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
          createdBy: user?.name ?? 'Admin',
        );
        await firestore.createNews(news).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw 'Database update timed out.',
        );
      } else {
        await firestore.updateNews(widget.existing!.id, {
          'title': _titleCtrl.text.trim(),
          'body': _bodyCtrl.text.trim(),
          'imageUrl': imageUrl,
        }).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw 'Database update timed out.',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing == null ? 'News published successfully!' : 'News updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _statusMessage = '';
        });

        String displayError = e.toString();
        if (displayError.contains('PERMISSION_DENIED')) {
          displayError = 'Permission denied. Please check Firebase Storage rules.';
        } else if (displayError.contains('network-request-failed')) {
          displayError = 'Network error. Please check your internet connection.';
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Publishing Failed'),
            content: Text(displayError),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit News' : 'Publish News',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade700),
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Image Picker Preview
                _buildInputLabel('Cover Image'),
                Center(
                  child: GestureDetector(
                    onTap: _saving ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        fit: StackFit.expand,
                        children: [
                          if (_imageFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          else if (widget.existing?.imageUrl != null && widget.existing!.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(widget.existing!.imageUrl!, fit: BoxFit.cover),
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
                                Text('Tap to upload image', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                              ],
                            ),

                          // Progress overlay on image
                          if (_saving && _imageFile != null && _uploadProgress > 0 && _uploadProgress < 1)
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
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
                ),
                const SizedBox(height: 20),

                // Form Fields
                _buildInputLabel('Headline'),
                _buildModernTextField(
                  controller: _titleCtrl,
                  hint: 'Enter a catchy title...',
                  icon: Icons.title_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Headline is required' : null,
                ),
                const SizedBox(height: 20),

                _buildInputLabel('Body Text'),
                _buildModernTextField(
                  controller: _bodyCtrl,
                  hint: 'Write the full details here...',
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Body is required' : null,
                ),
                const SizedBox(height: 20),

                _buildInputLabel('Image URL (Optional)'),
                _buildModernTextField(
                  controller: _imageCtrl,
                  hint: 'https://...',
                  icon: Icons.link_rounded,
                  enabled: _imageFile == null,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 32),

                // Submit Button
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
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        const SizedBox(width: 12),
                        Text(_statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    )
                        : Text(
                      isEdit ? 'Save Changes' : 'Publish News',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for input labels
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  // Helper widget for modern text fields
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 20) : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      ),
    );
  }
}
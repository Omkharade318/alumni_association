import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/news_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AdminNewsScreen extends StatelessWidget {
  const AdminNewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('News & Updates'),
        backgroundColor: const Color(0xFF8B2332),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B2332),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add News'),
        onPressed: () => _showNewsForm(context, null),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.newspaper, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No news yet.\nTap + to publish your first update.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        title: const Text('Delete News'),
        content: Text('Delete "${news.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteNews(news.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('News deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    news.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              news.body,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (news.imageUrl != null && news.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.image, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      news.imageUrl!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Published by ${news.createdBy}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
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
    // Optimization: Reduced dimensions and quality for faster uploads
    final image = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 800, 
      maxHeight: 800, 
      imageQuality: 70
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _imageCtrl.clear(); // Clear URL if a file is picked
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
      // 1. Upload image if a new file was picked
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
        // 2. Create new news item
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
        // 3. Update existing news item
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
            backgroundColor: const Color(0xFF8B2332),
          ),
        );
      }
    } catch (e) {
      print('NEWS_PUBLISH_ERROR: $e');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                Row(
                  children: [
                    const Icon(Icons.newspaper, color: Color(0xFF8B2332)),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Edit News' : 'Publish News',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                if (_saving && _imageFile != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2332)),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B2332)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                
                // Image Picker Preview
                Center(
                  child: GestureDetector(
                    onTap: _saving ? null : _pickImage,
                    child: Container(
                      width: double.infinity,
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
                          else if (widget.existing?.imageUrl != null && widget.existing!.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(widget.existing!.imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 180),
                            )
                          else
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to pick an image', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          
                          // Progress overlay on image
                          if (_saving && _imageFile != null)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _uploadProgress > 0 ? _uploadProgress : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    backgroundColor: Colors.white24,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${(_uploadProgress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  const Text(
                                    'UPLOADING IMAGE...',
                                    style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Headline *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Headline is required' : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Body / Details *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.article),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Body is required' : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional if photo picked)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.image_outlined),
                    hintText: 'https://...',
                  ),
                  keyboardType: TextInputType.url,
                  enabled: _imageFile == null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2332),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_uploadProgress > 0 && _uploadProgress < 1) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _uploadProgress,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_uploadProgress * 100).toInt()}% uploaded',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ] else ...[
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(_statusMessage, style: const TextStyle(fontSize: 12)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send),
                              const SizedBox(width: 8),
                              Text(isEdit ? 'Update' : 'Publish'),
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

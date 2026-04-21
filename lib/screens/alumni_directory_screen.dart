import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'messaging_screen.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';

class AlumniDirectoryScreen extends StatelessWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'Alumni Directory', showBack: true),
      body: StreamBuilder<List<UserModel>>(
        stream: FirestoreService().getAlumniStream(
          excludeUserId: context.read<AuthProvider>().currentUser?.uid,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final alumni = snapshot.data!;
          if (alumni.isEmpty) {
            return const Center(child: Text('No alumni found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alumni.length,
            itemBuilder: (_, i) => _AlumniCard(alumni: alumni[i]),
          );
        },
      ),
    );
  }
}

class _AlumniCard extends StatelessWidget {
  final UserModel alumni;

  const _AlumniCard({required this.alumni});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerGray),
      ),
      child: Row(
        children: [
          ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alumni.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (alumni.displayBranchBatch.isNotEmpty)
                  Text(
                    alumni.displayBranchBatch,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  ),
                if (alumni.displayLocation.isNotEmpty)
                  Text(
                    alumni.displayLocation,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: alumni)),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class AlumniDetailScreen extends StatelessWidget {
  final UserModel alumni;

  const AlumniDetailScreen({super.key, required this.alumni});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'Alumni Directory', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 120),
            ),
            const SizedBox(height: 16),
            Text(
              alumni.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () => FirestoreService().addConnection(context.read<AuthProvider>().currentUser!.uid, alumni.uid), child: const Text('Connect')),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final currentUser = context.read<AuthProvider>().currentUser;
                    if (currentUser == null) return;
                    final convId = await FirestoreService().getOrCreateConversation(currentUser.uid, alumni.uid);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: convId,
                            otherUser: alumni,
                            currentUserId: currentUser.uid,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.message),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
              ],
            ),
            const SizedBox(height: 24),
            _DetailSection(title: 'Currently Working in', content: '${alumni.company ?? '-'} | ${alumni.jobTitle ?? '-'}'),
            _DetailSection(title: 'Pursued', content: '${alumni.branch ?? '-'} | ${alumni.batch ?? '-'}'),
            _DetailSection(title: 'Based In', content: alumni.city ?? '-'),
            _DetailSection(title: 'Contact', content: '${alumni.email}\n${alumni.phone ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;

  const _DetailSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textGray, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

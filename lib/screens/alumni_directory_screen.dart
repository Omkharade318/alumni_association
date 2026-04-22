import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'alumini_details_screen.dart';
import 'messaging_screen.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';

class AlumniDirectoryScreen extends StatelessWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'Alumni Directory', showBack: true),
      body: FutureBuilder<List<String>>(
        future: FirestoreService().getAllConnectedUserIds(context.read<AuthProvider>().currentUser!.uid),
        builder: (context, idSnapshot) {
          final excludedIds = idSnapshot.data ?? [];
          excludedIds.add(context.read<AuthProvider>().currentUser!.uid);

          return StreamBuilder<List<UserModel>>(
            stream: FirestoreService().getAlumniStream(
              excludeUserIds: excludedIds,
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
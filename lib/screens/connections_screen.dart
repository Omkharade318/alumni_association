import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_avatar.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      // Wrap with SafeArea to automatically add padding for the status bar/notch
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.primaryRed.withOpacity(0.1),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryRed,
                indicatorColor: AppTheme.primaryRed,
                unselectedLabelColor: AppTheme.textGray,
                tabs: const [
                  Tab(text: 'My Connections'),
                  Tab(text: 'Pending Requests'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ConnectionsList(),
                  _PendingRequestsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getAcceptedConnectionsStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final connections = snapshot.data!;
        if (connections.isEmpty) return const Center(child: Text('No connections yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: connections.length,
          itemBuilder: (_, i) {
            final c = connections[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerGray),
              ),
              child: Row(
                children: [
                  ProfileAvatar(imageUrl: c.profileImage, name: c.name, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(c.displayLocation, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.message), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingRequestsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getPendingRequestsStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        if (requests.isEmpty) return const Center(child: Text('No pending requests'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            final sender = req['user'] as UserModel;
            final connId = req['connectionId'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerGray),
              ),
              child: Row(
                children: [
                  ProfileAvatar(imageUrl: sender.profileImage, name: sender.name, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sender.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(sender.displayLocation, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => FirestoreService().acceptConnection(connId),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => FirestoreService().rejectConnection(connId),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
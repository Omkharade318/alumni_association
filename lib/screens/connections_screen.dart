import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_avatar.dart';
import 'alumini_details_screen.dart';
import 'chat_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  final int initialTab;
  const ConnectionsScreen({super.key, this.initialTab = 0});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'My Network',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppTheme.primaryRed,
          indicatorWeight: 3,
          dividerColor: Colors.grey.shade200,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Connections'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ConnectionsList(),
          _PendingRequestsList(),
        ],
      ),
    );
  }
}

class _ConnectionsList extends StatefulWidget {
  @override
  State<_ConnectionsList> createState() => _ConnectionsListState();
}

class _ConnectionsListState extends State<_ConnectionsList> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return Column(
      children: [
        // Modern Floating Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search connections...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
        ),

        // Connections List
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: FirestoreService().getAcceptedConnectionsStream(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var connections = snapshot.data!;
              if (_searchQuery.isNotEmpty) {
                connections = connections.where((c) =>
                c.name.toLowerCase().contains(_searchQuery) ||
                    (c.branch?.toLowerCase().contains(_searchQuery) ?? false)
                ).toList();
              }

              if (connections.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.people_outline,
                  title: _searchQuery.isEmpty ? 'No connections yet' : 'No matches found',
                  subtitle: _searchQuery.isEmpty ? 'Start connecting with alumni to build your network.' : 'Try adjusting your search terms.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: connections.length,
                itemBuilder: (_, i) {
                  final c = connections[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: c)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              ProfileAvatar(imageUrl: c.profileImage, name: c.name, size: 52),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${c.branch ?? "Alumni"} • ${c.displayLocation}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Modern Circular Message Action
                              InkWell(
                                onTap: () async {
                                  final convId = await FirestoreService().getOrCreateConversation(user.uid, c.uid);
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          conversationId: convId,
                                          otherUser: c,
                                          currentUserId: user.uid,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryRed.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryRed, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
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

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.person_add_disabled_outlined, size: 64, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 24),
                const Text('No pending requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Text("You're all caught up!", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            final sender = req['user'] as UserModel;
            final connId = req['connectionId'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ProfileAvatar(imageUrl: sender.profileImage, name: sender.name, size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sender.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              '${sender.branch ?? "Alumni"} • ${sender.displayLocation}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => FirestoreService().rejectConnection(connId),
                          child: const Text('Ignore', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => FirestoreService().acceptConnection(connId),
                          child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
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
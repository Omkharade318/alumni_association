import 'package:alumni_connect/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/news_model.dart';
import '../services/notification_service.dart';
import '../widgets/profile_avatar.dart';
import 'alumini_details_screen.dart';
import 'connections_screen.dart';

// Color palette from your image
class AppColors {
  static const Color primaryMaroon = Color(0xFF8B2332);
  static const Color textDark = Colors.black87;
  static const Color textGray = Colors.grey;
  static const Color backgroundLight = Color(0xFFF9FAFB); // Softer, modern off-white
}

// Working placeholder image helpers
String _avatarUrl(int seed, {int size = 150}) => 'https://picsum.photos/seed/$seed/$size/$size';

// Reusable error widget for images
Widget _imageError(double width, double height, {bool circle = false}) {
  final child = Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported, color: Colors.grey),
  );
  return circle ? ClipOval(child: child) : child;
}

class HomeScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const HomeScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, user),
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        backgroundColor: Colors.white,
        onRefresh: () => context.read<AuthProvider>().refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryMaroon.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: user.profileImage!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (_, __, ___) => const Icon(Icons.person, size: 30, color: Colors.grey),
                          )
                              : CachedNetworkImage(
                            imageUrl: _avatarUrl(42),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? 'Alumni'}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stay connected with your alma mater',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 1. Alumni Spotlights — show only accepted connections
              const _SectionTitle(title: 'My Connections', icon: Icons.auto_awesome),
              const SizedBox(height: 16),
              if (user != null)
                StreamBuilder<List<String>>(
                  stream: firestore.getAcceptedConnectionIdsStream(user.uid),
                  builder: (context, snap) {
                    final acceptedIds = snap.data ?? [];
                    if (acceptedIds.isEmpty) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: Text('Connect with alumni to see them here', style: TextStyle(color: Colors.grey))),
                      );
                    }
                    return _AlumniSpotlightList(
                      stream: firestore.getAlumniStream(includeUserIds: acceptedIds),
                    );
                  },
                )
              else
                const SizedBox(height: 100, child: Center(child: Text('Log in', style: TextStyle(color: Colors.grey)))),

              const SizedBox(height: 32),

              // 2. Connect with Batchmates — hide accepted, show pending with "Request Sent"
              const _SectionTitle(title: 'Connect with Batchmates', icon: Icons.people_alt_outlined),
              const SizedBox(height: 16),
              if (user != null)
                StreamBuilder<List<List<String>>>(
                  stream: Rx.combineLatest2(
                    firestore.getAcceptedConnectionIdsStream(user.uid),
                    firestore.getPendingConnectionIdsStream(user.uid),
                    (List<String> accepted, List<String> pending) => [accepted, pending],
                  ),
                  builder: (context, idSnapshot) {
                    if (idSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    }
                    final acceptedIds = idSnapshot.data?[0] ?? [];
                    final pendingIds  = idSnapshot.data?[1] ?? [];

                    // Exclude self + accepted connections from the Firestore query
                    final queryExclusions = [user.uid, ...acceptedIds];

                    return _BatchmateList(
                      stream: firestore.getAlumniStream(
                        branch: user.branch,
                        batch: user.batch,
                        degree: user.degree,
                        excludeUserIds: queryExclusions,
                      ),
                      excludedIds: pendingIds, // only used for "Request Sent" button state
                    );
                  },
                )
              else
                const Center(child: Text('Log in to see your batchmates')),

              const SizedBox(height: 32),

              // 3. News and Updates
              const _SectionTitle(title: 'News & Updates', icon: Icons.newspaper_outlined),
              const SizedBox(height: 16),
              _NewsSection(stream: firestore.getNewsStream()),

              const SizedBox(height: 32),

              // 4. Upcoming Events
              const _SectionTitle(title: 'Upcoming Events', icon: Icons.calendar_month_outlined),
              const SizedBox(height: 16),
              _UpcomingEventsSection(stream: firestore.getEventsStream()),

              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel? user) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 28),
        onPressed: onMenuTap,
      ),
      title: GestureDetector(
        onLongPress: () => Navigator.pushNamed(context, '/admin'),
        child: const Text(
          'Alumni Connect',
          style: TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      centerTitle: true,
      actions: [
        StreamBuilder<int>(
          stream: NotificationService().getUnreadNotificationCountStream(user?.uid ?? ''),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87, size: 26),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.group_outlined, color: Colors.black87, size: 26),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionsScreen())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── Sub-Widgets ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryMaroon),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}

class _AlumniSpotlightList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  const _AlumniSpotlightList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        final alumniList = snapshot.data!;
        if (alumniList.isEmpty) return const SizedBox(height: 80, child: Center(child: Text('No spotlights', style: TextStyle(color: Colors.grey))));

        return SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: alumniList.length,
            itemBuilder: (context, i) {
              final user = alumniList[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: user))),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primaryMaroon, Colors.orange.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: ProfileAvatar(imageUrl: user.profileImage, name: user.name, size: 64),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name.split(' ').first,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BatchmateList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final List<String> excludedIds;
  const _BatchmateList({required this.stream, required this.excludedIds});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        final batchmates = snapshot.data!;
        if (batchmates.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('No batchmates found', style: TextStyle(color: Colors.grey))));

        return SizedBox(
          height: 230,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: batchmates.length,
            itemBuilder: (context, i) {
              final user = batchmates[i];
              final isPending = excludedIds.contains(user.uid);

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: user))),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primaryMaroon.withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Hero(
                                tag: 'batchmate_${user.uid}',
                                child: ProfileAvatar(imageUrl: user.profileImage, name: user.name, size: 65),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.branch ?? "Alumni"}\nBatch of ${user.batch ?? "-"}',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isPending ? Colors.grey : AppColors.primaryMaroon,
                              side: BorderSide(color: isPending ? Colors.grey : AppColors.primaryMaroon),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: isPending ? null : () {
                              final currentUserId = context.read<AuthProvider>().currentUser?.uid;
                              if (currentUserId != null) {
                                FirestoreService().addConnection(currentUserId, user.uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Request sent to ${user.name}')),
                                );
                              }
                            },
                            child: Text(
                              isPending ? 'Request Sent' : 'Connect', 
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Live News Section ───────────────────────────────────────────────────────

class _NewsSection extends StatelessWidget {
  final Stream<List<NewsModel>> stream;
  const _NewsSection({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NewsModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
        }

        final newsList = snapshot.data ?? [];
        if (newsList.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No news yet. Check back later!', style: TextStyle(color: Colors.grey)),
          );
        }

        return SizedBox(
          height: 240, // Increased slightly for modern proportions
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: newsList.length,
            itemBuilder: (context, i) => _buildNewsCard(context, newsList[i]),
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    final hasImage = news.imageUrl != null && news.imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => _showDetail(context, news),
      child: Container(
        width: 260, // Wider for better readability
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: hasImage
                  ? CachedNetworkImage(
                imageUrl: news.imageUrl!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 130,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => _imageError(double.infinity, 130),
              )
                  : Container(
                height: 130,
                width: double.infinity,
                color: AppColors.primaryMaroon.withOpacity(0.05),
                child: const Center(child: Icon(Icons.newspaper, size: 40, color: AppColors.primaryMaroon)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.body,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, NewsModel news) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, // Made taller by default
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (news.imageUrl != null && news.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: news.imageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                news.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: AppColors.primaryMaroon.withOpacity(0.1), child: const Icon(Icons.person, size: 14, color: AppColors.primaryMaroon)),
                  const SizedBox(width: 8),
                  Text('By ${news.createdBy}', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                news.body,
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming Events Section ──────────────────────────────────────────────────

class _UpcomingEventsSection extends StatelessWidget {
  final Stream<List<EventModel>> stream;
  const _UpcomingEventsSection({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('No upcoming events scheduled.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true, // Prevents Infinite Height error inside SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: events.length > 3 ? 3 : events.length, // Show max 3 on home screen
          itemBuilder: (context, i) {
            final event = events[i];

            // Assuming EventModel has a DateTime field called date. Adjust if it's a string.
            // If it's a String, you can replace this with hardcoded styling for now.
            String month = "TBD";
            String day = "-";
            if (event.date != null) {
              month = DateFormat('MMM').format(event.date!).toUpperCase();
              day = DateFormat('dd').format(event.date!);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Calendar Date Block
                    Container(
                      width: 55,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaroon.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                          Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryMaroon)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Event Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location ?? 'TBA',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
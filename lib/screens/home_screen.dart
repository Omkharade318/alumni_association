import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/news_model.dart';
import '../widgets/app_drawer.dart';

// Color palette from your image
class AppColors {
  static const Color primaryMaroon = Color(0xFF8B2332);
  static const Color textDark = Colors.black87;
  static const Color textGray = Colors.grey;
  static const Color backgroundLight = Color(0xFFF8F8F8);
}

// Working placeholder image helpers
String _avatarUrl(int seed, {int size = 150}) =>
    'https://picsum.photos/seed/$seed/$size/$size';

String _landscapeUrl(int seed, {int width = 200, int height = 120}) =>
    'https://picsum.photos/seed/$seed/$width/$height';

// Reusable error widget for images
Widget _imageError(double width, double height, {bool circle = false}) {
  final child = Container(
    width: width,
    height: height,
    color: const Color(0xFFEEEEEE),
    child: const Icon(Icons.image_not_supported, color: Colors.grey),
  );
  return circle
      ? ClipOval(child: child)
      : child;
}

class HomeScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const HomeScreen({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () => context.read<AuthProvider>().refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFEEEEEE),
                      child: ClipOval(
                        child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: user.profileImage!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.person, size: 30, color: Colors.grey),
                              )
                            : CachedNetworkImage(
                                imageUrl: _avatarUrl(42),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.person, size: 30, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello ${user?.name.split(' ').first ?? 'Raman'}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const Text('Stay connected with your alma mater!',
                            style: TextStyle(color: AppColors.textGray, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Alumni Spotlights
              const _SectionTitle(title: 'Alumni Spotlights'),
              const SizedBox(height: 12),
              _AlumniSpotlightList(stream: firestore.getAlumniStream()),

              const SizedBox(height: 24),

              // 2. Connect with Batchmates
              const _SectionTitle(title: 'Connect with your Batchmates'),
              const SizedBox(height: 12),
              _BatchmateList(stream: firestore.getAlumniStream()),

              const SizedBox(height: 24),

              // 3. News and Updates
              const _SectionTitle(title: 'News and Updates'),
              const SizedBox(height: 12),
              _NewsSection(stream: firestore.getNewsStream()),

              const SizedBox(height: 24),

              // 4. Upcoming Events
              const _SectionTitle(title: 'Upcoming Events'),
              const SizedBox(height: 12),
              _UpcomingEventsSection(stream: firestore.getEventsStream()),

              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black, size: 30),
        onPressed: onMenuTap,
      ),
      title: GestureDetector(
        onLongPress: () => Navigator.pushNamed(context, '/admin'),
        child: const Text(
          'Alumni Connect',
          style: TextStyle(
            color: AppColors.primaryMaroon,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black, size: 28),
              onPressed: () {},
            ),
            Positioned(
              right: 11,
              top: 11,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: AppColors.primaryMaroon, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              ),
            )
          ],
        ),
      ],
    );
  }
}

// --- Sub-Widgets ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryMaroon,
            ),
          ),
          const Divider(thickness: 1, color: Colors.black26),
        ],
      ),
    );
  }
}

// Spotlight names & batches (static demo data until Firestore is wired up)
const _spotlights = [
  ('Dr. Kate', 'Batch 2005 CSE', 10),
  ('Amit Shah', 'Batch 2008 ECE', 20),
  ('Priya R.', 'Batch 2010 IT', 30),
  ('Raj Kumar', 'Batch 2003 ME', 40),
  ('Sara Ali', 'Batch 2012 CS', 50),
];

class _AlumniSpotlightList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  const _AlumniSpotlightList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _spotlights.length,
        itemBuilder: (context, i) {
          final (name, batch, seed) = _spotlights[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryMaroon, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFEEEEEE),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _avatarUrl(seed, size: 100),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.person, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(batch, style: const TextStyle(fontSize: 8, color: AppColors.textGray)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Batchmate static demo data
const _batchmates = [
  ('Samara Patel', 'B.Tech(CSE)\n2002', 60),
  ('Raj Singh', 'B.Tech(ECE)\n2004', 70),
  ('Nisha Verma', 'MBA\n2006', 80),
  ('Kunal M.', 'B.Sc(CS)\n2008', 90),
];

class _BatchmateList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  const _BatchmateList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _batchmates.length,
        itemBuilder: (context, i) {
          final (name, info, seed) = _batchmates[i];
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, spreadRadius: 2)],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: _landscapeUrl(seed, width: 140, height: 100),
                        height: 100,
                        width: 140,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 100,
                          width: 140,
                          color: const Color(0xFFEEEEEE),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => _imageError(140, 100),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(info, style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.primaryMaroon,
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final newsList = snapshot.data ?? [];

        if (newsList.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No news yet. Check back later!',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }

        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: news.imageUrl!,
                      height: 115,
                      width: 220,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 115,
                        width: 220,
                        color: const Color(0xFFEEEEEE),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => _imageError(220, 115),
                    )
                  : Container(
                      height: 115,
                      width: 220,
                      color: const Color(0xFF8B2332).withOpacity(0.08),
                      child: const Center(
                        child: Icon(Icons.newspaper,
                            size: 40, color: Color(0xFF8B2332)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news.body,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textGray),
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
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
              if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: news.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
                const SizedBox(height: 16),
              Text(
                news.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'By ${news.createdBy}',
                style: const TextStyle(fontSize: 12, color: AppColors.textGray),
              ),
              const SizedBox(height: 16),
              Text(
                news.body,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  final Stream<List<EventModel>> stream;
  const _UpcomingEventsSection({required this.stream});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'Annual Convocation Ceremony to held on 12 August in presence of SDO',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

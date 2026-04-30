import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../config/theme.dart';
import '../services/firestore_service.dart';
import '../models/news_model.dart';
import '../widgets/full_screen_image_viewer.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<List<NewsModel>>(
        stream: FirestoreService().getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  const Text('No news yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Check back later for updates and announcements.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return _NewsCard(news: news);
            },
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;
  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = news.imageUrl != null && news.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24), // Increased spacing between news items
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edge-to-Edge Image Header
          if (hasImage)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrl: news.imageUrl!,
                      tag: 'news_${news.id}',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'news_${news.id}',
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl!,
                  height: 200, // Taller image for a premium editorial feel
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 40),
                  ),
                ),
              ),
            ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author & Date Metadata Row
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: AppTheme.primaryRed.withOpacity(0.8)),
                    const SizedBox(width: 4),
                    Text(
                      news.createdBy,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(news.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Headline
                Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Body Text
                Text(
                  news.body,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.6, // Increased line height for readability
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
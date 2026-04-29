import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/firestore_service.dart';
import '../models/news_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/full_screen_image_viewer.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        title: const Text('News and Updates', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: FirestoreService().getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) {
            return const Center(child: Text('No news available.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
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
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 180, color: Colors.grey[200]),
                  errorWidget: (_, __, ___) => Container(height: 180, color: Colors.grey[200], child: const Icon(Icons.error)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                ),
                const SizedBox(height: 8),
                Text(
                  news.body,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'By ${news.createdBy}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                    ),
                    Text(
                      _formatDate(news.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
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

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}

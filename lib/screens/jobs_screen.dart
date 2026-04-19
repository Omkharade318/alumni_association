import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/firestore_service.dart';
import '../models/job_model.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/profile_avatar.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'Jobs and Mentorship', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for Jobs & Mentorship',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: FirestoreService().getJobsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final jobs = snapshot.data!;
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('No job postings yet', style: TextStyle(color: AppTheme.textGray)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _JobCard(job: jobs[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryRed,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            imageUrl: job.companyLogo,
            name: job.company,
            size: 48,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(job.company, style: const TextStyle(color: AppTheme.textGray)),
                Text(job.location, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                Text(
                  DateFormat('MMM d').format(job.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

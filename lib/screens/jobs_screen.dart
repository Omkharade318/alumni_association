import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure this is in your pubspec.yaml

import '../config/theme.dart';
import '../models/job_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/company_logo.dart';
import 'admin/admin_job_form_screen.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: const AppAppBar(title: 'Jobs & Mentorship', showBack: true),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminJobFormScreen()),
          );
        },
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Job', style: TextStyle(fontWeight: FontWeight.bold)),
      )
          : null,
      body: StreamBuilder<List<JobModel>>(
        stream: FirestoreService().getJobsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red.shade400)),
            );
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ]),
                    child: Icon(Icons.work_outline_rounded, size: 64, color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 24),
                  const Text('No opportunities yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Check back later for new job postings.', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), // Extra bottom padding for FAB
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              return _JobCard(job: jobs[index]);
            },
          );
        },
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo, Company Name, and Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CompanyLogo(
                imageUrl: job.companyLogo,
                companyName: job.company,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.company,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(job.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Job Title
          Text(
            job.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: -0.3, height: 1.2),
          ),
          const SizedBox(height: 8),

          // Description (Truncated)
          Text(
            job.description ?? 'No description provided.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.black12),
          ),

          // Footer: Location & Apply Button
          Row(
            children: [
              // Location Badge
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Apply Button
              if (job.applyLink != null && job.applyLink!.isNotEmpty)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                    foregroundColor: AppTheme.primaryRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () async {
                    String urlString = job.applyLink!.trim().replaceAll(' ', '');
                    
                    if (urlString.isEmpty) return;

                    // Fallback to ensure the URL has a scheme if the admin forgot it
                    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                      urlString = 'https://$urlString';
                    }

                    try {
                      final Uri url = Uri.parse(urlString);
                      
                      // We try LaunchMode.externalApplication first for a better user experience (access to saved passwords/resumes)
                      // If it fails, we fall back to platform default.
                      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                      
                      if (!launched) {
                        launched = await launchUrl(url, mode: LaunchMode.platformDefault);
                      }

                      if (!launched && context.mounted) {
                        throw Exception('Could not launch URL');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open the link: $urlString'),
                            backgroundColor: Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            action: SnackBarAction(
                              label: 'Dismiss',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Apply Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
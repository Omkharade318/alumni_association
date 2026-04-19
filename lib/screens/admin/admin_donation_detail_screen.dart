import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/donation_model.dart';
import '../../models/donation_contribution_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'admin_donation_form_screen.dart';

class AdminDonationDetailScreen extends StatelessWidget {
  final DonationModel donation;

  const AdminDonationDetailScreen({super.key, required this.donation});

  Future<UserModel?> _loadUser(String uid) {
    return FirestoreService().getUser(uid);
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete campaign?'),
        content: Text('This will permanently delete “${donation.title}”.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await FirestoreService().deleteDonation(donation.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Details'),
        backgroundColor: AppTheme.primaryRed,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminDonationFormScreen(donation: donation)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmAndDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (donation.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    donation.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                donation.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(donation.description),
              const SizedBox(height: 16),
              Chip(label: Text(donation.category)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: donation.progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.dividerGray,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${NumberFormat('#,##0').format(donation.collectedAmount)} / ₹${NumberFormat('#,##0').format(donation.targetAmount)}',
                style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Text(
                'Contributions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<DonationContributionModel>>(
                stream: FirestoreService().getDonationContributionsStream(donation.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final contributions = snapshot.data!;
                  if (contributions.isEmpty) {
                    return const Text('No contributions yet');
                  }

                  return Column(
                    children: List.generate(contributions.length, (index) {
                      final c = contributions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FutureBuilder<UserModel?>(
                          future: _loadUser(c.userId),
                          builder: (context, userSnapshot) {
                            final name = userSnapshot.data?.name?.isNotEmpty == true ? userSnapshot.data!.name : c.userId;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.dividerGray),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.monetization_on_outlined, color: AppTheme.primaryRed),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${NumberFormat('#,##0').format(c.amount)}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}


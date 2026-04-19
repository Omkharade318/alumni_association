import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/donation_model.dart';
import '../../services/firestore_service.dart';
import 'admin_donation_detail_screen.dart';
import 'admin_donation_form_screen.dart';

class AdminDonationsScreen extends StatelessWidget {
  const AdminDonationsScreen({super.key});

  Future<void> _confirmAndDelete(BuildContext context, DonationModel donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete donation campaign?'),
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Donations'),
        backgroundColor: AppTheme.primaryRed,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryRed,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDonationFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DonationModel>>(
        stream: FirestoreService().getDonationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final donations = snapshot.data!;

          if (donations.isEmpty) return const Center(child: Text('No donation campaigns found'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (_, i) {
              final d = donations[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Chip(
                            label: Text(d.category),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textGray),
                      ),
                      if (d.imageUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(d.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: d.progress.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.dividerGray,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${NumberFormat('#,##0').format(d.collectedAmount)} / ₹${NumberFormat('#,##0').format(d.targetAmount)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AdminDonationDetailScreen(donation: d)),
                            ),
                            icon: const Icon(Icons.remove_red_eye_outlined),
                            color: AppTheme.primaryRed,
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AdminDonationFormScreen(donation: d)),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            color: AppTheme.primaryRed,
                          ),
                          IconButton(
                            onPressed: () => _confirmAndDelete(context, d),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


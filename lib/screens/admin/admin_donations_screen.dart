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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Campaign?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete “${donation.title}”. This action cannot be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirestoreService().deleteDonation(donation.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Campaign deleted successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Campaigns',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDonationFormScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<DonationModel>>(
        stream: FirestoreService().getDonationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final donations = snapshot.data!;

          if (donations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.volunteer_activism_rounded, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text('No campaigns found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text('Tap + to create your first donation campaign.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), // Extra bottom padding for FAB
            itemCount: donations.length,
            itemBuilder: (_, i) {
              final d = donations[i];
              return _AdminDonationCard(
                donation: d,
                onView: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDonationDetailScreen(donation: d))),
                onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDonationFormScreen(donation: d))),
                onDelete: () => _confirmAndDelete(context, d),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminDonationCard extends StatelessWidget {
  final DonationModel donation;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminDonationCard({
    required this.donation,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = donation.imageUrl != null && donation.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edge-to-Edge Image
          if (hasImage)
            Image.network(
              donation.imageUrl!,
              height: 140,
              fit: BoxFit.cover,
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    donation.category.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryRed, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 12),

                // Title & Description
                Text(
                  donation.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  donation.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Modern Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##0').format(donation.collectedAmount)} raised',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                    ),
                    Text(
                      '${(donation.progress.clamp(0.0, 1.0) * 100).toInt()}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: donation.progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal: ₹${NumberFormat('#,##0').format(donation.targetAmount)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.black12),
                ),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: onView,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.remove_red_eye_rounded, size: 16, color: AppTheme.primaryRed),
                            SizedBox(width: 6),
                            Text('View', style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.edit_rounded, size: 18, color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.delete_rounded, size: 18, color: Colors.red.shade600),
                      ),
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
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/donation_model.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/app_app_bar.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  @override
  void initState() {
    super.initState();
    _updateLastViewed();
  }

  void _updateLastViewed() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      FirestoreService().updateLastViewedDonations(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Softer background
      appBar: const AppAppBar(title: 'Campaigns', showBack: true),
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
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volunteer_activism_outlined, size: 64, color: AppTheme.primaryRed.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No active campaigns',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text('Check back later for opportunities to give.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: donations.length,
            itemBuilder: (_, i) => _DonationCard(donation: donations[i]),
          );
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DonationModel donation;

  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonationDetailScreen(donation: donation)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            if (donation.imageUrl != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: donation.imageUrl!,
                        tag: 'donation_card_${donation.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'donation_card_${donation.id}',
                  child: Image.network(donation.imageUrl!, height: 160, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 160,
                color: AppTheme.primaryRed.withOpacity(0.05),
                child: Center(
                  child: Icon(
                    donation.category == 'Computer Labs' ? Icons.computer : Icons.apartment,
                    size: 64,
                    color: AppTheme.primaryRed.withOpacity(0.5),
                  ),
                ),
              ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(
                    donation.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonationDetailScreen extends StatefulWidget {
  final DonationModel donation;

  const DonationDetailScreen({super.key, required this.donation});

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  double? _selectedAmount = 1000; // Default selection
  final _customAmountController = TextEditingController();
  bool _useCustomAmount = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _donate() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    double amount;
    if (_useCustomAmount) {
      amount = double.tryParse(_customAmountController.text.trim()) ?? 0;
      if (amount < 500) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum donation is ₹500')));
        return;
      }
    } else {
      amount = _selectedAmount ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an amount')));
        return;
      }
    }

    // Show loading indicator
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)));

    try {
      await FirestoreService().addDonation(widget.donation.id, amount, user.uid);
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your generous donation!')));
        Navigator.pop(context); // pop screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppAppBar(title: 'Fund Campaign', showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (donation.imageUrl != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: donation.imageUrl!,
                        tag: 'donation_detail_${donation.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'donation_detail_${donation.id}',
                  child: Image.network(donation.imageUrl!, height: 260, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 260,
                color: AppTheme.primaryRed.withOpacity(0.05),
                child: Center(
                  child: Icon(
                    donation.category == 'Computer Labs' ? Icons.computer : Icons.apartment,
                    size: 80,
                    color: AppTheme.primaryRed.withOpacity(0.5),
                  ),
                ),
              ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      donation.category.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryRed, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    donation.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    donation.description,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // Goal Tracking Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: donation.isGoalCompleted ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: donation.isGoalCompleted ? Colors.green.shade200 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              donation.isGoalCompleted ? Icons.check_circle : Icons.trending_up,
                              color: donation.isGoalCompleted ? Colors.green.shade600 : AppTheme.primaryRed,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              donation.isGoalCompleted ? 'Goal Reached!' : 'Campaign Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: donation.isGoalCompleted ? Colors.green.shade800 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${NumberFormat('#,##0').format(donation.collectedAmount)}',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'raised of ₹${NumberFormat('#,##0').format(donation.targetAmount)}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            Text(
                              '${(donation.progress.clamp(0.0, 1.0) * 100).toInt()}%',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: donation.progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(donation.isGoalCompleted ? Colors.green.shade500 : AppTheme.primaryRed),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Text('Select an amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Amount Selection Row
                  if (!_useCustomAmount)
                    Row(
                      children: [
                        Expanded(child: _AmountChip(amount: 1000, selected: _selectedAmount == 1000, onTap: () => setState(() => _selectedAmount = 1000))),
                        const SizedBox(width: 12),
                        Expanded(child: _AmountChip(amount: 5000, selected: _selectedAmount == 5000, onTap: () => setState(() => _selectedAmount = 5000))),
                        const SizedBox(width: 12),
                        Expanded(child: _AmountChip(amount: 10000, selected: _selectedAmount == 10000, onTap: () => setState(() => _selectedAmount = 10000))),
                      ],
                    ),

                  if (_useCustomAmount)
                    TextField(
                      controller: _customAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Custom Amount',
                        labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.normal),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        hintText: 'Min. 500',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Toggle Custom Amount
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                      onPressed: () => setState(() {
                        _useCustomAmount = !_useCustomAmount;
                        if (!_useCustomAmount) _selectedAmount = 1000;
                      }),
                      child: Text(_useCustomAmount ? 'Use suggested amounts' : 'Enter a custom amount instead'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _donate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Donate Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;
  final bool selected;
  final VoidCallback onTap;

  const _AmountChip({required this.amount, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primaryRed : Colors.grey.shade300, width: 2),
          boxShadow: selected ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Center(
          child: Text(
            '₹${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
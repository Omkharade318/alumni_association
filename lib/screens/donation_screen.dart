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

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: 'Donate', showBack: true),
      body: StreamBuilder<List<DonationModel>>(
        stream: FirestoreService().getDonationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final donations = snapshot.data!;
          if (donations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism, size: 64, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  Text('No donation campaigns yet', style: TextStyle(color: AppTheme.textGray)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonationDetailScreen(donation: donation)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  child: Image.network(donation.imageUrl!, height: 150, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 150,
                color: AppTheme.primaryRed.withOpacity(0.2),
                child: Center(
                  child: Icon(
                    donation.category == 'Computer Labs' ? Icons.computer : Icons.apartment,
                    size: 64,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donate for ${donation.category.toLowerCase()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(donation.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: donation.progress.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.dividerGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,##0').format(donation.collectedAmount)} / ₹${NumberFormat('#,##0').format(donation.targetAmount)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
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
  double? _selectedAmount;
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

    await FirestoreService().addDonation(widget.donation.id, amount, user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your donation!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    return Scaffold(
      appBar: AppAppBar(title: 'Donate', showBack: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  child: Image.network(donation.imageUrl!, height: 200, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 200,
                color: AppTheme.primaryRed.withOpacity(0.2),
                child: Center(
                  child: Icon(
                    donation.category == 'Computer Labs' ? Icons.computer : Icons.apartment,
                    size: 80,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(donation.description),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: donation.isGoalCompleted ? Colors.green.shade50 : AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      donation.isGoalCompleted
                          ? 'Goal Completed: ₹${NumberFormat('#,##0').format(donation.collectedAmount)}'
                          : '₹${NumberFormat('#,##0').format(donation.collectedAmount)} / ₹${NumberFormat('#,##0').format(donation.targetAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: donation.isGoalCompleted ? Colors.green.shade800 : AppTheme.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Choose Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (!_useCustomAmount)
                    Row(
                      children: [
                        _AmountChip(amount: 1000, selected: _selectedAmount == 1000, onTap: () => setState(() => _selectedAmount = 1000)),
                        const SizedBox(width: 8),
                        _AmountChip(amount: 5000, selected: _selectedAmount == 5000, onTap: () => setState(() => _selectedAmount = 5000)),
                        const SizedBox(width: 8),
                        _AmountChip(amount: 10000, selected: _selectedAmount == 10000, onTap: () => setState(() => _selectedAmount = 10000)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _useCustomAmount = !_useCustomAmount;
                      if (!_useCustomAmount) _selectedAmount = null;
                    }),
                    child: Text(_useCustomAmount ? 'Use predefined amounts' : 'Enter custom amount'),
                  ),
                  if (_useCustomAmount) ...[
                    TextField(
                      controller: _customAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Choose Amount',
                        prefixText: '₹ ',
                        hintText: 'Min. ₹500',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _donate,
                      child: const Text('Donate now'),
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

class _AmountChip extends StatelessWidget {
  final int amount;
  final bool selected;
  final VoidCallback onTap;

  const _AmountChip({required this.amount, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryRed : AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primaryRed : AppTheme.dividerGray),
        ),
        child: Text(
          '₹${NumberFormat('#,##0').format(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

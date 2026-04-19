import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'alumni_directory_screen.dart';

class SearchAlumniScreen extends StatefulWidget {
  const SearchAlumniScreen({super.key});

  @override
  State<SearchAlumniScreen> createState() => _SearchAlumniScreenState();
}

class _SearchAlumniScreenState extends State<SearchAlumniScreen> {
  final _nameController = TextEditingController();
  String? _selectedBranch;
  final _batchController = TextEditingController();
  final _cityController = TextEditingController();
  List<UserModel> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _isSearching = true);
    final results = await FirestoreService().searchAlumni(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      branch: _selectedBranch,
      batch: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
    );
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('All')),
      ...AppConstants.branches.map((b) => DropdownMenuItem<String?>(value: b, child: Text(b))),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Find your Batchmates/Mentors',
            style: TextStyle(fontSize: 18, color: AppTheme.textGray),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Name',
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _selectedBranch,
            decoration: const InputDecoration(labelText: 'Branch'),
            items: branchItems,
            onChanged: (v) => setState(() => _selectedBranch = v),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Batch',
            controller: _batchController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Location',
            controller: _cityController,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Search',
            onPressed: _search,
            isLoading: _isSearching,
          ),
          const SizedBox(height: 24),
          if (_results.isNotEmpty)
            ..._results.map((a) => _AlumniResultCard(alumni: a)),
          if (_results.isEmpty && !_isSearching && _nameController.text.isNotEmpty)
            const Center(child: Text('No results found')),
        ],
      ),
    );
  }
}

class _AlumniResultCard extends StatelessWidget {
  final UserModel alumni;

  const _AlumniResultCard({required this.alumni});

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
        children: [
          ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alumni.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (alumni.displayBranchBatch.isNotEmpty)
                  Text(alumni.displayBranchBatch, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                if (alumni.displayLocation.isNotEmpty)
                  Text(alumni.displayLocation, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlumniDetailScreen(alumni: alumni),
              ),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

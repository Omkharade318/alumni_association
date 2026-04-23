import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'alumini_details_screen.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/app_app_bar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_button.dart';

class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> {
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedBranch;
  List<UserModel>? _searchResults;
  bool _isSearching = false;
  bool _showFilters = false;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    final excludedIds = await FirestoreService().getAllConnectedUserIds(currentUser.uid);
    excludedIds.add(currentUser.uid);

    final results = await FirestoreService().searchAlumni(
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      branch: _selectedBranch,
      batch: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      excludeUserIds: excludedIds,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _resetSearch() {
    setState(() {
      _nameController.clear();
      _batchController.clear();
      _cityController.clear();
      _selectedBranch = null;
      _searchResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('All Branches')),
      ...AppConstants.branches.map((b) => DropdownMenuItem<String?>(value: b, child: Text(b))),
    ];

    return Scaffold(
      appBar: AppAppBar(
        title: 'Alumni Directory',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  AppTextField(label: 'Name', controller: _nameController),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedBranch,
                          decoration: const InputDecoration(labelText: 'Branch', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                          items: branchItems,
                          onChanged: (v) => setState(() => _selectedBranch = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(label: 'Batch', controller: _batchController, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Location', controller: _cityController),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: _resetSearch, child: const Text('Reset'))),
                      const SizedBox(width: 12),
                      Expanded(child: AppButton(text: 'Search', onPressed: _performSearch, isLoading: _isSearching)),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: _searchResults != null
                ? _buildResultsList(_searchResults!)
                : _buildFullDirectory(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDirectory() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return FutureBuilder<List<String>>(
      future: FirestoreService().getAllConnectedUserIds(user.uid),
      builder: (context, idSnapshot) {
        final excludedIds = idSnapshot.data ?? [];
        excludedIds.add(user.uid);

        return StreamBuilder<List<UserModel>>(
          stream: FirestoreService().getAlumniStream(excludeUserIds: excludedIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return _buildResultsList(snapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildResultsList(List<UserModel> alumni) {
    if (alumni.isEmpty) return const Center(child: Text('No alumni found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alumni.length,
      itemBuilder: (_, i) => _AlumniCard(alumni: alumni[i]),
    );
  }
}

class _AlumniCard extends StatelessWidget {
  final UserModel alumni;
  const _AlumniCard({required this.alumni});

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
          ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alumni.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (alumni.displayBranchBatch.isNotEmpty)
                  Text(alumni.displayBranchBatch, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                if (alumni.displayLocation.isNotEmpty)
                  Text(alumni.displayLocation, style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: alumni))),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
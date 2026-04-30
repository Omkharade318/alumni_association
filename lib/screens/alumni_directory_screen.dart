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
      _showFilters = false; // Auto-hide filters after searching for a cleaner view
    });
  }

  void _resetSearch() {
    setState(() {
      _nameController.clear();
      _batchController.clear();
      _cityController.clear();
      _selectedBranch = null;
      _searchResults = null;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('All Branches')),
      ...AppConstants.branches.map((b) => DropdownMenuItem<String?>(value: b, child: Text(b))),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      appBar: AppAppBar(
        title: 'Alumni Directory',
        showBack: true,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
              color: _showFilters ? AppTheme.white : Colors.black87,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Smoothly Animated Filter Panel
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_showFilters
                ? const SizedBox.shrink()
                : Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernTextField(
                    controller: _nameController,
                    hint: 'Search by name...',
                    icon: Icons.search_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildModernDropdown(
                          value: _selectedBranch,
                          items: branchItems,
                          onChanged: (v) => setState(() => _selectedBranch = v),
                          hint: 'Branch',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildModernTextField(
                          controller: _batchController,
                          hint: 'Year',
                          icon: Icons.calendar_today_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildModernTextField(
                    controller: _cityController,
                    hint: 'Filter by city...',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onPressed: _resetSearch,
                          child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _performSearch,
                          child: _isSearching
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Results Area
          Expanded(
            child: _searchResults != null
                ? _buildResultsList(_searchResults!, isFiltered: true)
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
            return _buildResultsList(snapshot.data!, isFiltered: false);
          },
        );
      },
    );
  }

  Widget _buildResultsList(List<UserModel> alumni, {required bool isFiltered}) {
    if (alumni.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered ? 'No matching alumni found' : 'Directory is empty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered ? 'Try adjusting your search filters.' : 'Check back later as more users join.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: alumni.length,
      itemBuilder: (_, i) => _AlumniCard(alumni: alumni[i]),
    );
  }

  // Helper widget for modern text fields
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade400, size: 20) : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Helper widget for modern dropdown
  Widget _buildModernDropdown({
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      items: items,
      onChanged: onChanged,
      icon: Icon(Icons.expand_more_rounded, color: Colors.grey.shade500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AlumniCard extends StatelessWidget {
  final UserModel alumni;
  const _AlumniCard({required this.alumni});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: alumni))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ProfileAvatar(imageUrl: alumni.profileImage, name: alumni.name, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumni.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (alumni.displayBranchBatch.isNotEmpty)
                        Text(
                          alumni.displayBranchBatch,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (alumni.displayLocation.isNotEmpty)
                        Text(
                          alumni.displayLocation,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Modern Pill Button for Profile viewing
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryRed,
                    side: const BorderSide(color: AppTheme.primaryRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlumniDetailScreen(alumni: alumni))),
                  child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
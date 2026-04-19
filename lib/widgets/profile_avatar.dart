import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder ? Border.all(color: AppTheme.primaryRed, width: 2) : null,
        color: AppTheme.dividerGray,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.primaryRed.withOpacity(0.3),
      child: Center(
        child: Text(
          name != null && name!.isNotEmpty ? name![0].toUpperCase() : '?',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Circular avatar with network image support and a fallback icon.
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(imageUrl!),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Icon(fallbackIcon, size: radius),
    );
  }
}

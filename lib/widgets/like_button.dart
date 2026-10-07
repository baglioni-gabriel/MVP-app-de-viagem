import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../providers/profile_provider.dart';

/// Reusable like button with animated heart icon.
///
/// Reads the like state from [hasLikedProvider] and calls
/// [FirestoreService.toggleLike] using a batch write.
/// Can be used in both [PostCard] and [PostDetailScreen].
class LikeButton extends ConsumerWidget {
  /// The post to like/unlike.
  final String postId;

  /// Current like count (from the post document).
  final int likesCount;

  /// If true, shows the count label next to the icon.
  final bool showCount;

  /// Icon size.
  final double size;

  const LikeButton({
    super.key,
    required this.postId,
    required this.likesCount,
    this.showCount = true,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasLiked = ref.watch(hasLikedProvider(postId)).valueOrNull ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggle(ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon swap
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  hasLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(hasLiked),
                  color: hasLiked
                      ? Colors.redAccent
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: size,
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: 5),
                Text(
                  '$likesCount',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasLiked
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref) async {
    final uid = ref.read(authUidForFeedProvider);
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).toggleLike(postId, uid);
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/constants.dart';
import '../models/post_model.dart';
import '../providers/filter_provider.dart';

/// Card displayed in the home feed for each [Post].
///
/// Shows the post image, title, author info, location, availability
/// summary, like count, comment count, and — when the travel-time
/// filter is active — a travel-time badge (e.g. "🚗 23 min").
class PostCard extends ConsumerWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM dd, yyyy');
    final filter = ref.watch(filterProvider);
    final travelMinutes = filter.travelTimesMinutes[post.id];

    return GestureDetector(
      onTap: () => context.pushNamed(
        'postDetail',
        pathParameters: {'id': post.id},
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image with optional travel badge overlay ──────
            Stack(
              children: [
                if (post.imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      height: 200,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      height: 200,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, size: 40),
                      ),
                    ),
                  ),

                // Travel time badge — shown when filter is active
                if (travelMinutes != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _TravelTimeBadge(
                      minutes: travelMinutes,
                      mode: filter.criteria.travelMode,
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ────────────────────────────────────────
                  Text(
                    post.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // ── Location row ─────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Availability chip ────────────────────────────
                  _AvailabilityChip(
                    post: post,
                    dateFmt: dateFmt,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),

                  // ── Bottom row: role badge + likes/comments ──────
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: post.authorRole == 'business'
                              ? theme.colorScheme.secondary
                                  .withValues(alpha: 0.12)
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              post.authorRole == 'business'
                                  ? Icons.storefront_rounded
                                  : Icons.hiking_rounded,
                              size: 13,
                              color: post.authorRole == 'business'
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.authorRole == 'business'
                                  ? 'Business'
                                  : 'Traveler',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: post.authorRole == 'business'
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Likes
                      Icon(Icons.favorite_border_rounded,
                          size: 17,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45)),
                      const SizedBox(width: 3),
                      Text('${post.likesCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          )),
                      const SizedBox(width: 12),

                      // Comments
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45)),
                      const SizedBox(width: 3),
                      Text('${post.commentsCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          )),
                    ],
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

// ─── Travel time badge ──────────────────────────────────────────────────

class _TravelTimeBadge extends StatelessWidget {
  final int minutes;
  final TravelMode mode;

  const _TravelTimeBadge({
    required this.minutes,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      TravelMode.driving => '🚗',
      TravelMode.transit => '🚌',
      TravelMode.walking => '🚶',
    };

    final label = minutes < 60
        ? '$minutes min'
        : '${minutes ~/ 60}h ${minutes % 60}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Availability chip ──────────────────────────────────────────────────

/// Small chip that summarises the availability — Perennial vs date range.
class _AvailabilityChip extends StatelessWidget {
  final Post post;
  final DateFormat dateFmt;
  final ThemeData theme;

  const _AvailabilityChip({
    required this.post,
    required this.dateFmt,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData icon;

    if (post.isPerennial) {
      label = 'Perennial';
      icon = Icons.all_inclusive_rounded;
    } else {
      final start = dateFmt.format(post.startDateTime);
      final end =
          post.endDateTime != null ? dateFmt.format(post.endDateTime!) : '?';
      label = '$start → $end';
      icon = Icons.date_range_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.tertiary),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

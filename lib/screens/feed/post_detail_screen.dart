import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/comment_tile.dart';
import '../../widgets/like_button.dart';

/// Post detail screen — full image, description, embedded map with pin,
/// availability details, like button, comments list, and add-comment input.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(appUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _sendingComment = true);

    final comment = Comment(
      id: '',
      authorUid: user.uid,
      authorName: user.displayName,
      authorPhotoUrl: user.photoUrl,
      text: text,
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).addComment(widget.postId, comment);

    _commentCtrl.clear();
    if (mounted) setState(() => _sendingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postAsync = ref.watch(postByIdProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final dateFmt = DateFormat('MMM dd, yyyy – HH:mm');

    return postAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (post) {
        if (post == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Post not found.')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Image app bar ────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: post.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              // ── Body ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        post.title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Author & role badge row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: post.authorRole == 'business'
                                  ? theme.colorScheme.secondary
                                      .withValues(alpha: 0.12)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              post.authorRole == 'business'
                                  ? '🏪 Business'
                                  : '🥾 Traveler',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: post.authorRole == 'business'
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          // Business page link
                          if (post.businessPageId != null &&
                              post.businessPageId!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.pushNamed(
                                'businessPage',
                                pathParameters: {
                                  'id': post.businessPageId!,
                                },
                              ),
                              child: Text(
                                'View Business Page →',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        post.description,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 20),

                      // Location row
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              post.address,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Embedded map ─────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 180,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                post.location.latitude,
                                post.location.longitude,
                              ),
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId:
                                    MarkerId('post_${post.id}'),
                                position: LatLng(
                                  post.location.latitude,
                                  post.location.longitude,
                                ),
                                infoWindow:
                                    InfoWindow(title: post.title),
                              ),
                            },
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            liteModeEnabled: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Availability details ─────────────────────
                      _AvailabilitySection(
                          post: post, dateFmt: dateFmt, theme: theme),
                      const SizedBox(height: 20),

                      // ── Like button + comment count ──────────────
                      Row(
                        children: [
                          // Reusable LikeButton widget
                          LikeButton(
                            postId: post.id,
                            likesCount: post.likesCount,
                          ),
                          const SizedBox(width: 16),

                          // Comment count
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentsCount}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),

                      // ── Comments section header ────────────────
                      Text('Comments',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      // Comment input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendComment(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed:
                                _sendingComment ? null : () => _sendComment(),
                            icon: _sendingComment
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(Icons.send_rounded,
                                    color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Comments list (ASC — oldest first) ──────────────
              commentsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $e')),
                ),
                data: (comments) {
                  if (comments.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Text(
                          'No comments yet. Be the first!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, i) =>
                          CommentTile(comment: comments[i]),
                    ),
                  );
                },
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Availability section ─────────────────────────────────────────────

class _AvailabilitySection extends StatelessWidget {
  final Post post;
  final DateFormat dateFmt;
  final ThemeData theme;

  const _AvailabilitySection({
    required this.post,
    required this.dateFmt,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Availability',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // Start
          _InfoLine(
            icon: Icons.play_arrow_rounded,
            label: 'Starts',
            value: dateFmt.format(post.startDateTime),
            theme: theme,
          ),

          // End / Perennial
          if (post.isPerennial)
            _InfoLine(
              icon: Icons.all_inclusive_rounded,
              label: 'Duration',
              value: 'Perennial (no end date)',
              theme: theme,
            )
          else if (post.endDateTime != null)
            _InfoLine(
              icon: Icons.stop_rounded,
              label: 'Ends',
              value: dateFmt.format(post.endDateTime!),
              theme: theme,
            ),

          // Operating hours
          if (post.operatingHours.isNotEmpty)
            _InfoLine(
              icon: Icons.schedule_rounded,
              label: 'Hours',
              value: post.operatingHours,
              theme: theme,
            ),

          // Unavailable days
          if (post.unavailableDays.isNotEmpty)
            _InfoLine(
              icon: Icons.block_rounded,
              label: 'Closed on',
              value: post.unavailableDays.join(', '),
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 6),
          Text('$label: ',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                )),
          ),
        ],
      ),
    );
  }
}

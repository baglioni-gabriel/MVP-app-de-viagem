import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

/// Business page view — gallery carousel, description, contact info,
/// category badge. Owner can tap edit to modify.
class BusinessPageScreen extends ConsumerWidget {
  final String pageId;
  const BusinessPageScreen({super.key, required this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pageAsync = ref.watch(businessPageByIdProvider(pageId));
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;

    return pageAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (page) {
        if (page == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Business page not found.')),
          );
        }

        final isOwner = currentUid == page.ownerUid;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Image gallery / app bar ──────────────────────
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Edit page',
                      onPressed: () => context.pushNamed(
                        'editBusinessPage',
                        extra: page,
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    page.businessName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                  background: page.photoUrls.isNotEmpty
                      ? _GalleryPageView(photoUrls: page.photoUrls)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              size: 72, color: Colors.white38),
                        ),
                ),
              ),

              // ── Body ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          page.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        page.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contact info
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: page.address,
                        theme: theme,
                      ),
                      if (page.phoneNumber != null &&
                          page.phoneNumber!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          text: page.phoneNumber!,
                          theme: theme,
                        ),
                      if (page.website != null && page.website!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.language_rounded,
                          text: page.website!,
                          theme: theme,
                        ),

                      const SizedBox(height: 24),

                      // Gallery thumbnails
                      if (page.photoUrls.length > 1) ...[
                        Text('Gallery',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: page.photoUrls.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: page.photoUrls[i],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // TODO Phase 4: Show linked posts here
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Horizontally swipeable gallery behind the SliverAppBar.
class _GalleryPageView extends StatelessWidget {
  final List<String> photoUrls;
  const _GalleryPageView({required this.photoUrls});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: photoUrls.length,
      itemBuilder: (_, i) => CachedNetworkImage(
        imageUrl: photoUrls[i],
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image_rounded)),
      ),
    );
  }
}

/// Simple icon + text row used for contact information.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;
  const _InfoRow(
      {required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                )),
          ),
        ],
      ),
    );
  }
}

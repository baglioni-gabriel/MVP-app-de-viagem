import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/filter_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/wayv_logo.dart';
import '../home/widgets/filter_bar.dart';

/// Home screen — paginated feed of posts with pull-to-refresh,
/// collapsible filter bar, and a FAB for creating new posts.
///
/// When filters are active, the feed is further refined client-side
/// (date/availability) and via the Distance Matrix API (travel time).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when within 300px of the bottom
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(feedProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feed = ref.watch(feedProvider);
    final filter = ref.watch(filterProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';

    // Determine which posts to show
    final isFiltered = filter.criteria.isActive;
    final displayPosts = isFiltered ? filter.filteredPosts : feed.posts;

    // Re-apply filters when the raw feed data changes (e.g. pagination)
    ref.listen(feedProvider, (prev, next) {
      final f = ref.read(filterProvider);
      if (f.criteria.isActive) {
        f.applyFilters(next.posts);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const WayvLogo(height: 32),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'My Profile',
            onPressed: () => context.pushNamed(
              'profile',
              pathParameters: {'uid': uid},
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await feed.refresh();
          final f = ref.read(filterProvider);
          if (f.criteria.isActive) {
            await f.applyFilters(feed.posts);
          }
        },
        child: Column(
          children: [
            // ── Filter bar ──────────────────────────────────────
            const FilterBar(),

            // ── Filtering indicator ─────────────────────────────
            if (filter.filtering)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calculating travel times...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Feed list ───────────────────────────────────────
            Expanded(
              child: _buildFeedList(
                theme: theme,
                feed: feed,
                displayPosts: displayPosts,
                isFiltered: isFiltered,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('createPost'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post'),
      ),
    );
  }

  Widget _buildFeedList({
    required ThemeData theme,
    required FeedNotifier feed,
    required List displayPosts,
    required bool isFiltered,
  }) {
    if (feed.posts.isEmpty && feed.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (displayPosts.isEmpty) {
      return isFiltered
          ? _EmptyFilterResult(theme: theme)
          : _EmptyFeed(theme: theme);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: displayPosts.length +
          (!isFiltered && feed.hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= displayPosts.length) {
          // Loading indicator at the bottom
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return PostCard(post: displayPosts[i]);
      },
    );
  }
}

/// Shown when no posts match the active filters.
class _EmptyFilterResult extends StatelessWidget {
  final ThemeData theme;
  const _EmptyFilterResult({required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Icon(Icons.filter_list_off_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                'No matching posts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Try adjusting your travel time, date range, '
                  'or base location to see more results.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when the feed has no posts.
class _EmptyFeed extends StatelessWidget {
  final ThemeData theme;
  const _EmptyFeed({required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      // Wrap in ListView so pull-to-refresh still works
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Icon(Icons.explore_outlined,
                  size: 72,
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Be the first to share an experience!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/avatar_widget.dart';

/// Traveler profile screen — shows name, photo, role badge, and
/// account actions. Also shows a link to the business page for
/// Business-role users.
class TravelerProfileScreen extends ConsumerWidget {
  final String uid;
  const TravelerProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appUserAsync = ref.watch(appUserProvider);
    final currentUid =
        ref.watch(authStateProvider).valueOrNull?.uid;
    final isOwnProfile = currentUid == uid;

    return appUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (appUser) {
        if (appUser == null) {
          return const Scaffold(
            body: Center(child: Text('User not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit profile',
                  onPressed: () => context.pushNamed('editProfile'),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // ── Avatar ───────────────────────────────────────
                const SizedBox(height: 12),
                AvatarWidget(
                  imageUrl: appUser.photoUrl,
                  radius: 56,
                ),
                const SizedBox(height: 16),

                // ── Name ─────────────────────────────────────────
                Text(
                  appUser.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appUser.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Role badge ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: appUser.role == UserRole.business
                        ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        appUser.role == UserRole.business
                            ? Icons.storefront_rounded
                            : Icons.hiking_rounded,
                        size: 16,
                        color: appUser.role == UserRole.business
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        appUser.role == UserRole.business
                            ? 'Business'
                            : 'Traveler',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: appUser.role == UserRole.business
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Business Page link (business users only) ─────
                if (appUser.role == UserRole.business && isOwnProfile) ...[
                  _BusinessPageTile(ref: ref, theme: theme),
                  const SizedBox(height: 16),
                ],

                // ── Sign out (own profile) ───────────────────────
                if (isOwnProfile) ...[
                  const Divider(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authServiceProvider).signOut(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                            color: theme.colorScheme.error.withValues(alpha: 0.4)),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tile that links to the user's business page, or offers to create one.
class _BusinessPageTile extends StatelessWidget {
  final WidgetRef ref;
  final ThemeData theme;

  const _BusinessPageTile({required this.ref, required this.theme});

  @override
  Widget build(BuildContext context) {
    final bizAsync = ref.watch(myBusinessPageProvider);

    return bizAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (biz) {
        if (biz != null) {
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.storefront_rounded,
                    color: theme.colorScheme.secondary),
              ),
              title: Text(biz.businessName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(biz.category),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.pushNamed('businessPage',
                  pathParameters: {'id': biz.id}),
            ),
          );
        }

        // No business page yet — show create button
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => context.pushNamed('editBusinessPage'),
            icon: const Icon(Icons.add_business_rounded),
            label: const Text('Create your Business Page'),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/business_page_model.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/business_onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/feed/home_screen.dart';
import '../screens/feed/post_detail_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/profile/business_page_screen.dart';
import '../screens/profile/edit_business_page_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/traveler_profile_screen.dart';
import '../screens/shared/loading_screen.dart';

// ─── Auth-aware Router ───────────────────────────────────────────────

/// Routes + redirect logic, reactive to [authStateProvider] and
/// [appUserProvider] so navigation automatically updates on auth changes.
///
/// Redirect matrix:
///
/// | authState  | appUser | Redirect to |
/// |------------|---------|-------------|
/// | loading    | -       | /           |
/// | null       | -       | /login      |
/// | signed-in  | null    | /role       |
/// | signed-in  | exists  | /home       |
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final appUserAsync = ref.read(appUserProvider);

      if (authAsync.isLoading || authAsync.hasError) return '/';

      final firebaseUser = authAsync.valueOrNull;
      final appUser = appUserAsync.valueOrNull;
      final currentPath = state.matchedLocation;

      const authPaths = ['/login', '/signup'];
      final isOnAuthPage = authPaths.contains(currentPath);
      final isOnRolePage = currentPath == '/role';
      final isOnOnboarding = currentPath == '/business-onboarding';
      final isOnSplash = currentPath == '/';

      // 1) Not logged in
      if (firebaseUser == null) {
        return isOnAuthPage ? null : '/login';
      }

      // 2) Logged in but no Firestore doc
      if (appUser == null) {
        return isOnRolePage ? null : '/role';
      }

      // 3) Fully onboarded — redirect away from auth/splash pages
      //    but allow /business-onboarding for new business users
      if (isOnAuthPage || isOnRolePage || isOnSplash) {
        return '/home';
      }
      // Allow onboarding page
      if (isOnOnboarding) return null;

      return null;
    },
    routes: [
      // ─── Splash / Loading ────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const LoadingScreen(),
      ),

      // ─── Auth ────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/role',
        name: 'role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/business-onboarding',
        name: 'businessOnboarding',
        builder: (context, state) => const BusinessOnboardingScreen(),
      ),

      // ─── Home feed ───────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ─── Profiles ────────────────────────────────────────────────
      GoRoute(
        path: '/profile/:uid',
        name: 'profile',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return TravelerProfileScreen(uid: uid);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // ─── Business Pages ──────────────────────────────────────────
      GoRoute(
        path: '/business/:id',
        name: 'businessPage',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BusinessPageScreen(pageId: id);
        },
      ),
      GoRoute(
        path: '/business/edit',
        name: 'editBusinessPage',
        builder: (context, state) {
          final existing = state.extra as BusinessPage?;
          return EditBusinessPageScreen(existingPage: existing);
        },
      ),

      // ─── Post creation ───────────────────────────────────────────
      GoRoute(
        path: '/post/create',
        name: 'createPost',
        builder: (context, state) => const CreatePostScreen(),
      ),

      // ─── Post detail ─────────────────────────────────────────────
      GoRoute(
        path: '/post/:id',
        name: 'postDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostDetailScreen(postId: id);
        },
      ),
    ],
  );
});

/// A [ChangeNotifier] that fires whenever auth or appUser providers emit.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(appUserProvider, (_, _) => notifyListeners());
  }
}

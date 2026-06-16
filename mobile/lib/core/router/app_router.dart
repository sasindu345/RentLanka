import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/features/activity/screens/activity_screen.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/screens/register_screen.dart';
import 'package:mobile/features/auth/screens/welcome_screen.dart';
import 'package:mobile/features/explore/screens/home_feed_screen.dart';
import 'package:mobile/features/explore/screens/listing_detail_screen.dart';
import 'package:mobile/features/explore/screens/search_results_screen.dart';
import 'package:mobile/features/listings/screens/create_listing_screen.dart';
import 'package:mobile/features/profile/screens/profile_screen.dart';
import 'package:mobile/features/saved/screens/wishlist_screen.dart';
import 'package:mobile/shared/widgets/bottom_nav_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final api = ref.watch(listingsApiProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final loggedIn = await api.isLoggedIn();
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/welcome' || location == '/login' || location == '/register';
      final isPublicAppRoute = location.startsWith('/app/explore');
      final isProtectedRoute = location.startsWith('/app/') && !isPublicAppRoute;

      if (!loggedIn && isProtectedRoute) {
        return '/welcome';
      }
      if (loggedIn && isAuthRoute) {
        return '/app/explore';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/explore',
                builder: (context, state) => const HomeFeedScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) {
                      final q = state.uri.queryParameters['q'] ?? '';
                      final category = state.uri.queryParameters['category'];
                      return SearchResultsScreen(
                        initialQuery: q,
                        category: category,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) {
                      return ListingDetailScreen(id: state.pathParameters['id']!);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/saved',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/list',
                builder: (context, state) => const CreateListingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/activity',
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) async {
          final loggedIn = await api.isLoggedIn();
          return loggedIn ? '/app/explore' : '/welcome';
        },
      ),
    ],
  );
});

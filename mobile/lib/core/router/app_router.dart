import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/features/activity/screens/activity_screen.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';
import 'package:mobile/features/auth/screens/register_screen.dart';
import 'package:mobile/features/auth/screens/welcome_screen.dart';
import 'package:mobile/features/auth/screens/splash_screen.dart';
import 'package:mobile/features/auth/screens/signup_verification_screen.dart';
import 'package:mobile/features/explore/screens/home_feed_screen.dart';
import 'package:mobile/features/explore/screens/listing_detail_screen.dart';
import 'package:mobile/features/explore/screens/booking_request_screen.dart';
import 'package:mobile/features/explore/screens/search_results_screen.dart';
import 'package:mobile/features/listings/screens/create_listing_screen.dart';
import 'package:mobile/features/listings/screens/edit_listing_screen.dart';
import 'package:mobile/features/listings/screens/owner_dashboard_screen.dart';
import 'package:mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:mobile/features/profile/screens/profile_screen.dart';
import 'package:mobile/features/profile/screens/verification_screen.dart';
import 'package:mobile/features/profile/screens/earnings_screen.dart';
import 'package:mobile/features/saved/screens/wishlist_screen.dart';
import 'package:mobile/shared/widgets/bottom_nav_shell.dart';
import 'package:mobile/features/chat/screens/inbox_screen.dart';
import 'package:mobile/features/chat/screens/chat_thread_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final api = ref.watch(listingsApiProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) async {
      final loggedIn = await api.isLoggedIn();
      final location = state.matchedLocation;
      final isAuthRoute =
          location == '/welcome' || location == '/login' || location == '/register' || location == '/signup-verification';
      final isPublicAppRoute = location.startsWith('/app/explore');
      final isProtectedRoute = location.startsWith('/app/') && !isPublicAppRoute;

      if (!loggedIn && isProtectedRoute) {
        return '/welcome';
      }
      if (loggedIn && (location == '/welcome' || location == '/login' || location == '/register')) {
        return '/app/explore';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 450),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 450),
        ),
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
                    parentNavigatorKey: _rootNavigatorKey,
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
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return ListingDetailScreen(id: state.pathParameters['id']!);
                    },
                    routes: [
                      GoRoute(
                        path: 'book',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          return BookingRequestScreen(listingId: state.pathParameters['id']!);
                        },
                      ),
                    ],
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
                builder: (context, state) => const InboxScreen(),
                routes: [
                  GoRoute(
                    path: 'messages/thread/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return ChatThreadScreen(conversationId: state.pathParameters['id']!);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'verification',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const VerificationScreen(),
                  ),
                  GoRoute(
                    path: 'earnings',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EarningsScreen(),
                  ),
                  GoRoute(
                    path: 'listing/:id/edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      return EditListingScreen(listingId: state.pathParameters['id']!);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 5: Owner Dashboard (owner mode home tab)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/owner',
                builder: (context, state) => const OwnerDashboardScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/signup-verification',
        builder: (context, state) {
          final devToken = state.uri.queryParameters['devToken'];
          return SignupVerificationScreen(devToken: devToken);
        },
      ),
    ],
  );
});

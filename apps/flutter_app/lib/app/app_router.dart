import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/ads/presentation/ads_page.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/auth/logic/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/dashboard/presentation/dashboard_shell.dart';
import '../features/dashboard/presentation/home_overview_page.dart';
import '../features/gamification/presentation/gamification_page.dart';
import '../features/move_earn/presentation/move_earn_page.dart';
import '../features/offerwall/presentation/offerwall_page.dart';
import '../features/referrals/presentation/referrals_page.dart';
import '../features/wallet/presentation/wallet_page.dart';
import '../features/withdrawals/presentation/withdrawals_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final isAuthenticated = authState.value != null;

  return GoRouter(
    initialLocation: isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isAuthRoute = state.uri.path == '/login';
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const HomeOverviewPage()),
          GoRoute(path: '/move', builder: (_, __) => const MoveEarnPage()),
          GoRoute(path: '/ads', builder: (_, __) => const AdsPage()),
          GoRoute(path: '/offerwall', builder: (_, __) => const OfferwallPage()),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletPage()),
          GoRoute(path: '/withdrawals', builder: (_, __) => const WithdrawalsPage()),
          GoRoute(path: '/referrals', builder: (_, __) => const ReferralsPage()),
          GoRoute(path: '/gamification', builder: (_, __) => const GamificationPage()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminPage()),
        ],
      ),
    ],
  );
});

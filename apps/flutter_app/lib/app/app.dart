import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'app_router.dart';

class EarnDashApp extends ConsumerWidget {
  const EarnDashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appNickname,
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

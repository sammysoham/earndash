import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user_session.dart';
import '../../../core/widgets/brand_logo.dart';
import '../logic/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController(
    text: AppConstants.useMockApi ? 'admin@earndash.dev' : '',
  );
  final _passwordController = TextEditingController(
    text: AppConstants.useMockApi ? 'password123' : '',
  );
  final _displayNameController = TextEditingController(text: 'Soham');
  final _referralCodeController = TextEditingController();
  bool _isSignup = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserSession?>>(authControllerProvider, (_, next) {
      next.whenOrNull(data: (session) {
        if (session != null && mounted) {
          context.go('/dashboard');
        }
      });
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: _MarketingPanel()),
                            const SizedBox(width: 32),
                            Expanded(child: _AuthCard(
                              isSignup: _isSignup,
                              isLoading: isLoading,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              displayNameController: _displayNameController,
                              referralCodeController: _referralCodeController,
                              onPrimaryAction: () async {
                                if (_isSignup) {
                                  await ref.read(authControllerProvider.notifier).signup(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        displayName: _displayNameController.text,
                                        referralCode: _referralCodeController.text,
                                      );
                                } else {
                                  await ref.read(authControllerProvider.notifier).login(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );
                                }
                              },
                              onGoogleAction: () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                              onAdminDemo: () => ref.read(authControllerProvider.notifier).loginAsDemo(admin: true),
                              onUserDemo: () => ref.read(authControllerProvider.notifier).loginAsDemo(),
                              onToggleMode: () => setState(() => _isSignup = !_isSignup),
                              errorText: authState.whenOrNull(error: (error, _) => '$error'),
                            )),
                          ],
                        )
                      : Column(
                          children: [
                            const _MarketingPanel(),
                            const SizedBox(height: 24),
                            _AuthCard(
                              isSignup: _isSignup,
                              isLoading: isLoading,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              displayNameController: _displayNameController,
                              referralCodeController: _referralCodeController,
                              onPrimaryAction: () async {
                                if (_isSignup) {
                                  await ref.read(authControllerProvider.notifier).signup(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                        displayName: _displayNameController.text,
                                        referralCode: _referralCodeController.text,
                                      );
                                } else {
                                  await ref.read(authControllerProvider.notifier).login(
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );
                                }
                              },
                              onGoogleAction: () => ref.read(authControllerProvider.notifier).loginWithGoogle(),
                              onAdminDemo: () => ref.read(authControllerProvider.notifier).loginAsDemo(admin: true),
                              onUserDemo: () => ref.read(authControllerProvider.notifier).loginAsDemo(),
                              onToggleMode: () => setState(() => _isSignup = !_isSignup),
                              errorText: authState.whenOrNull(error: (error, _) => '$error'),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MarketingPanel extends StatelessWidget {
  const _MarketingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF163522), Color(0xFF09120D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EarndashBrand(),
          const SizedBox(height: 16),
          const Text(
            'Earn through daily movement, rewarded videos, referrals, and a wallet built to keep every coin easy to track.',
            style: TextStyle(fontSize: 18, color: Color(0xFF9CB1AA), height: 1.5),
          ),
          const SizedBox(height: 24),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniBadge(label: 'Offerwalls'),
              _MiniBadge(label: 'Rewarded ads'),
              _MiniBadge(label: 'Withdrawals'),
              _MiniBadge(label: 'Referrals'),
            ],
          ),
          const SizedBox(height: 24),
            Text(
              AppConstants.useMockApi ? 'Quick test accounts' : 'Real backend mode',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
          Text(
              AppConstants.useMockApi
                ? 'Admin: admin@earndash.dev / password123'
                : 'Create your account to start earning and tracking your progress.',
            ),
          const SizedBox(height: 4),
          Text(
            AppConstants.useMockApi
                ? 'User: sara@earndash.dev / password123'
                : 'Google sign-in is also available on supported devices.',
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x141FF5C6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isSignup,
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.displayNameController,
    required this.referralCodeController,
    required this.onPrimaryAction,
    required this.onGoogleAction,
    required this.onAdminDemo,
    required this.onUserDemo,
    required this.onToggleMode,
    required this.errorText,
  });

  final bool isSignup;
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final TextEditingController referralCodeController;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onGoogleAction;
  final VoidCallback onAdminDemo;
  final VoidCallback onUserDemo;
  final VoidCallback onToggleMode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSignup ? 'Create your EarnDash account' : 'Welcome back',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.useMockApi
                  ? 'Email login works offline for the MVP, and Google sign-in now uses Firebase on supported devices.'
                  : 'Sign in with your email or continue with Google to access your wallet, offers, and activity rewards.',
            ),
            const SizedBox(height: 24),
            if (isSignup) ...[
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: referralCodeController,
                decoration: const InputDecoration(
                  labelText: 'Referral code (optional)',
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isLoading ? null : onPrimaryAction,
              child: Text(isSignup ? 'Create account' : 'Log in'),
            ),
            const SizedBox(height: 12),
            if (AppConstants.firebaseAuthEnabled) ...[
              OutlinedButton.icon(
                onPressed: isLoading ? null : onGoogleAction,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const Text(
                'Google sign-in will appear automatically on devices where Firebase login is enabled.',
                style: TextStyle(color: Color(0xFF8FAE99), height: 1.5),
              ),
              const SizedBox(height: 12),
            ],
            if (AppConstants.useMockApi) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: isLoading ? null : onAdminDemo,
                    child: const Text('Use admin demo'),
                  ),
                  OutlinedButton(
                    onPressed: isLoading ? null : onUserDemo,
                    child: const Text('Use user demo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: isLoading ? null : onToggleMode,
              child: Text(isSignup ? 'Already have an account?' : 'Need an account?'),
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(errorText!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }
}

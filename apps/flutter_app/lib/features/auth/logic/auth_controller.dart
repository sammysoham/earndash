import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/auth/firebase_auth_service.dart';
import '../../../core/fitness/activity_tracking_service.dart';
import '../../../core/models/user_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/device_identity_service.dart';

final activityTrackingServiceProvider = Provider<ActivityTrackingService>(
  (ref) => ActivityTrackingService.instance,
);
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    activityTrackingService: ref.read(activityTrackingServiceProvider),
  ),
);
final authStorageProvider = Provider<AuthStorage>(
  (ref) => const AuthStorage(FlutterSecureStorage()),
);
final deviceIdentityProvider = Provider<DeviceIdentityService>((ref) => DeviceIdentityService());
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) => FirebaseAuthService());

class AuthController extends StateNotifier<AsyncValue<UserSession?>> {
  AuthController(this._ref) : super(const AsyncLoading()) {
    _restoreSession();
  }

  final Ref _ref;

  Future<void> _restoreSession() async {
    try {
      final token = await _ref.read(authStorageProvider).readToken();
      if (token == null || token.isEmpty) {
        state = const AsyncData(null);
        return;
      }

      final session = await _ref.read(apiClientProvider).restoreSession(token);
      state = AsyncData(session);
    } catch (_) {
      await _ref.read(authStorageProvider).clear();
      state = const AsyncData(null);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final deviceFingerprint = await _ref.read(deviceIdentityProvider).fingerprint();
      final session = await _ref.read(apiClientProvider).login(
            email: email,
            password: password,
            deviceFingerprint: deviceFingerprint,
          );
      await _ref.read(authStorageProvider).saveToken(session.accessToken);
      state = AsyncData(session);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String displayName,
    String? referralCode,
  }) async {
    state = const AsyncLoading();
    try {
      final deviceFingerprint = await _ref.read(deviceIdentityProvider).fingerprint();
      final session = await _ref.read(apiClientProvider).signup(
            email: email,
            password: password,
            displayName: displayName,
            deviceFingerprint: deviceFingerprint,
            referralCode: referralCode,
          );
      await _ref.read(authStorageProvider).saveToken(session.accessToken);
      state = AsyncData(session);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> loginAsDemo({bool admin = false}) async {
    await login(
      email: admin ? 'admin@earndash.dev' : 'sara@earndash.dev',
      password: 'password123',
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    try {
      final identity = await _ref.read(firebaseAuthServiceProvider).signInWithGoogle();
      final deviceFingerprint = await _ref.read(deviceIdentityProvider).fingerprint();
      final session = await _ref.read(apiClientProvider).loginWithGoogle(
            email: identity.email,
            displayName: identity.displayName,
            deviceFingerprint: deviceFingerprint,
            idToken: identity.idToken,
            googleId: identity.providerUserId,
          );
      await _ref.read(authStorageProvider).saveToken(session.accessToken);
      state = AsyncData(session);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await _ref.read(authStorageProvider).clear();
    await _ref.read(firebaseAuthServiceProvider).signOutIfNeeded();
    _ref.read(apiClientProvider).setAccessToken(null);
    state = const AsyncData(null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<UserSession?>>(
  AuthController.new,
);

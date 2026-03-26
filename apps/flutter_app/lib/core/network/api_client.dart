import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../fitness/activity_tracking_service.dart';
import '../models/admin_entities.dart';
import '../models/admin_metrics.dart';
import '../models/fitness_models.dart';
import '../models/gamification_models.dart';
import '../models/offer_model.dart';
import '../models/referral_overview.dart';
import '../models/user_session.dart';
import '../models/wallet_summary.dart';
import 'mock_backend.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    required ActivityTrackingService activityTrackingService,
  })  : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl)),
        _activityTrackingService = activityTrackingService;

  final Dio _dio;
  final ActivityTrackingService _activityTrackingService;
  final MockBackend _mockBackend = MockBackend.instance;
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<UserSession?> restoreSession(String token) async {
    if (AppConstants.useMockApi) {
      final session = await _mockBackend.restoreSession(token);
      if (session != null) {
        setAccessToken(session.accessToken);
      }
      return session;
    }

    setAccessToken(token);
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserSession(
      accessToken: token,
      user: SessionUser.fromJson(response.data!['user'] as Map<String, dynamic>),
    );
  }

  Future<UserSession> login({
    required String email,
    required String password,
    required String deviceFingerprint,
  }) async {
    if (AppConstants.useMockApi) {
      final session = await _mockBackend.login(
        email: email,
        password: password,
        deviceFingerprint: deviceFingerprint,
      );
      setAccessToken(session.accessToken);
      return session;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'deviceFingerprint': deviceFingerprint,
        'deviceType': 'flutter',
      },
    );
    final session = UserSession.fromJson(response.data!);
    setAccessToken(session.accessToken);
    return session;
  }

  Future<UserSession> signup({
    required String email,
    required String password,
    required String displayName,
    required String deviceFingerprint,
    String? referralCode,
  }) async {
    if (AppConstants.useMockApi) {
      final session = await _mockBackend.signup(
        email: email,
        password: password,
        displayName: displayName,
        deviceFingerprint: deviceFingerprint,
        referralCode: referralCode,
      );
      setAccessToken(session.accessToken);
      return session;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
        'deviceFingerprint': deviceFingerprint,
        'deviceType': 'flutter',
        'referralCode': referralCode,
      },
    );
    final session = UserSession.fromJson(response.data!);
    setAccessToken(session.accessToken);
    return session;
  }

  Future<UserSession> loginWithGoogle({
    required String email,
    required String displayName,
    required String deviceFingerprint,
    required String googleId,
    String? idToken,
  }) async {
    if (AppConstants.useMockApi) {
      final session = await _mockBackend.loginWithGoogle(
        email: email,
        displayName: displayName,
        deviceFingerprint: deviceFingerprint,
      );
      setAccessToken(session.accessToken);
      return session;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google/mobile',
      data: {
        'idToken': idToken,
        'email': email,
        'displayName': displayName,
        'googleId': googleId,
        'deviceFingerprint': deviceFingerprint,
        'deviceType': 'flutter',
      },
    );
    final session = UserSession.fromJson(response.data!);
    setAccessToken(session.accessToken);
    return session;
  }

  Future<List<OfferModel>> getOffers({required String userId, required String country}) async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getOffers(userId: userId, country: country);
    }

    final response = await _dio.get<List<dynamic>>(
      '/offerwall',
      queryParameters: {
        'userId': userId,
        'country': country,
        'device': 'flutter',
      },
    );

    return (response.data ?? <dynamic>[])
        .map((item) => OfferModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OfferModel> completeOffer(String offerId) async {
    final userId = _requireUserId();
    if (AppConstants.useMockApi) {
      return _mockBackend.completeOffer(userId: userId, offerId: offerId);
    }

    throw UnimplementedError('Real offer completion simulation is not implemented.');
  }

  Future<int> settlePendingRewards() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.settlePendingRewards(_requireUserId());
    }

    final response = await _dio.post<Map<String, dynamic>>('/rewards/settle');
    return response.data?['releasedCount'] as int? ?? 0;
  }

  Future<WalletSummary> getWallet() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getWallet(_requireUserId());
    }

    final response = await _dio.get<Map<String, dynamic>>('/wallet');
    return WalletSummary.fromJson(response.data!);
  }

  Future<void> requestWithdrawal({required String method, required String destination, required int coins}) async {
    if (AppConstants.useMockApi) {
      return _mockBackend.requestWithdrawal(
        userId: _requireUserId(),
        method: method,
        destination: destination,
        coins: coins,
      );
    }

    await _dio.post<void>('/withdrawals', data: {
      'method': method,
      'destination': destination,
      'coins': coins,
    });
  }

  Future<GamificationProfile> getGamificationProfile() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getGamificationProfile(_requireUserId());
    }

    final response = await _dio.get<Map<String, dynamic>>('/gamification/profile');
    return GamificationProfile.fromJson(response.data!);
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getLeaderboard(_requireUserId());
    }

    final response = await _dio.get<List<dynamic>>('/gamification/leaderboard');
    return (response.data ?? <dynamic>[])
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReferralOverview> getReferralOverview() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getReferralOverview(_requireUserId());
    }

    final response = await _dio.get<Map<String, dynamic>>('/referrals/overview');
    return ReferralOverview.fromJson(response.data!);
  }

  Future<AdminMetrics> getAdminMetrics() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getAdminMetrics();
    }

    final response = await _dio.get<Map<String, dynamic>>('/admin/analytics');
    return AdminMetrics.fromJson(response.data!);
  }

  Future<List<AdminUserSummary>> getAdminUsers() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getAdminUsers(_requireUserId());
    }

    final response = await _dio.get<List<dynamic>>('/admin/users');
    return (response.data ?? <dynamic>[])
        .map((item) => AdminUserSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminWithdrawalRequest>> getAdminWithdrawals() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.getAdminWithdrawals(_requireUserId());
    }

    final response = await _dio.get<List<dynamic>>('/admin/withdrawals');
    return (response.data ?? <dynamic>[])
        .map(
          (item) => AdminWithdrawalRequest.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> giftCoins({
    required String targetUserId,
    required int coins,
    required String note,
  }) async {
    if (AppConstants.useMockApi) {
      return _mockBackend.giftCoins(
        adminUserId: _requireUserId(),
        targetUserId: targetUserId,
        coins: coins,
        note: note,
      );
    }

    await _dio.post<void>(
      '/admin/users/$targetUserId/gift',
      data: {'coins': coins, 'note': note},
    );
  }

  Future<void> setUserBlocked({
    required String targetUserId,
    required bool blocked,
  }) async {
    if (AppConstants.useMockApi) {
      return _mockBackend.setUserBlocked(
        adminUserId: _requireUserId(),
        targetUserId: targetUserId,
        blocked: blocked,
      );
    }

    await _dio.patch<void>(
      '/admin/users/$targetUserId/block',
      data: {'blocked': blocked},
    );
  }

  Future<void> updateWithdrawalStatus({
    required String withdrawalId,
    required String status,
    String? note,
  }) async {
    if (AppConstants.useMockApi) {
      return _mockBackend.updateWithdrawalStatus(
        adminUserId: _requireUserId(),
        withdrawalId: withdrawalId,
        status: status,
        note: note,
      );
    }

    await _dio.patch<void>(
      '/admin/withdrawals/$withdrawalId/status',
      data: {'status': status, 'note': note},
    );
  }

  Future<MoveEarnOverview> getMoveEarnOverview() async {
    if (AppConstants.useMockApi) {
      final snapshot = await _activityTrackingService.refresh();
      return _mockBackend.getMoveEarnOverview(
        _requireUserId(),
        snapshot: snapshot,
      );
    }

    final snapshot = await _activityTrackingService.refresh();
    final response = await _dio.post<Map<String, dynamic>>(
      '/fitness/move/sync',
      data: _deviceSnapshotToJson(snapshot),
    );
    return MoveEarnOverview.fromJson(response.data!);
  }

  Future<MoveEarnOverview> syncMoveActivity() async {
    if (AppConstants.useMockApi) {
      final snapshot = await _activityTrackingService.refresh();
      return _mockBackend.syncDeviceActivity(
        userId: _requireUserId(),
        snapshot: snapshot,
      );
    }

    final snapshot = await _activityTrackingService.refresh();
    final response = await _dio.post<Map<String, dynamic>>(
      '/fitness/move/sync',
      data: _deviceSnapshotToJson(snapshot),
    );
    return MoveEarnOverview.fromJson(response.data!);
  }

  Future<MoveEarnOverview> activateStepBoost() async {
    if (AppConstants.useMockApi) {
      return _mockBackend.activateStepBoost(_requireUserId());
    }

    final response = await _dio.post<Map<String, dynamic>>('/fitness/move/boost');
    return MoveEarnOverview.fromJson(response.data!);
  }

  Future<int> confirmAdReward({required String adUnitId, required String sessionId, required int coins}) async {
    if (AppConstants.useMockApi) {
      return _mockBackend.confirmAdReward(userId: _requireUserId(), coins: coins);
    }

    await _dio.post<void>('/ads/reward', data: {
      'adUnitId': adUnitId,
      'sessionId': sessionId,
      'coins': coins,
    });
    return coins;
  }

  String _requireUserId() {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

    final segments = token.split('mock-token-');
    if (AppConstants.useMockApi && segments.length == 2) {
      return segments.last;
    }

    throw Exception('Unable to resolve the current user');
  }

  Map<String, dynamic> _deviceSnapshotToJson(DeviceActivitySnapshot snapshot) {
    return <String, dynamic>{
      'supported': snapshot.supported,
      'permissionGranted': snapshot.permissionGranted,
      'status': snapshot.status,
      'source': snapshot.source,
      'todayDateKey': snapshot.todayDateKey,
      'todaySteps': snapshot.todaySteps,
      'distanceKm': snapshot.distanceKm,
      'activeMinutes': snapshot.activeMinutes,
      'walkMinutes': snapshot.walkMinutes,
      'runMinutes': snapshot.runMinutes,
      'calories': snapshot.calories,
      'message': snapshot.message,
      'weeklyHistory': snapshot.weeklyHistory.map((item) => item.toJson()).toList(),
    };
  }
}

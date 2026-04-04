import 'dart:async';
import 'dart:math';
import '../models/admin_entities.dart';
import '../models/admin_metrics.dart';
import '../models/fitness_models.dart';
import '../models/gamification_models.dart';
import '../models/offer_model.dart';
import '../models/referral_overview.dart';
import '../models/user_session.dart';
import '../models/wallet_summary.dart';
import '../models/withdrawal_request.dart';

class MockBackend {
  MockBackend._() {
    _seed();
  }

  static final MockBackend instance = MockBackend._();

  final Random _random = Random(7);
  final Map<String, _MockUser> _usersById = <String, _MockUser>{};
  final Map<String, String> _userIdByEmail = <String, String>{};
  final Map<String, String> _tokenToUserId = <String, String>{};
  final List<_MockWithdrawal> _withdrawals = <_MockWithdrawal>[];
  int _userSequence = 0;
  int _withdrawalSequence = 0;

  final List<OfferModel> _offers = <OfferModel>[
    OfferModel(
      provider: 'AdGem',
      externalOfferId: 'adgem-merge-empire',
      title: 'Reach level 12 in Merge Empire',
      description: 'A fast-start mobile offer with a strong completion rate.',
      payoutCoins: 1800,
      ctaUrl: 'mock://offer/adgem-merge-empire',
      iconUrl: '',
      estimatedMinutes: 20,
    ),
    OfferModel(
      provider: 'Ayet Studios',
      externalOfferId: 'ayet-premium-survey',
      title: 'Complete a premium survey',
      description: 'Short qualification flow with a moderate payout.',
      payoutCoins: 950,
      ctaUrl: 'mock://offer/ayet-premium-survey',
      iconUrl: '',
      estimatedMinutes: 12,
    ),
  ];

  int _offerStarts = 0;
  int _completedOffers = 0;

  Future<T> _withLatency<T>(T Function() callback) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    return callback();
  }

  Future<UserSession> login({
    required String email,
    required String password,
    required String deviceFingerprint,
  }) {
    return _withLatency(() {
      final normalized = email.trim().toLowerCase();
      final existingId = _userIdByEmail[normalized];
      final user = existingId != null
          ? _usersById[existingId]!
          : _createUser(
              email: normalized,
              displayName: _displayNameFromEmail(normalized),
              role: normalized == 'admin@earndash.dev' ? 'ADMIN' : 'USER',
              referralCode:
                  _generateReferralCode(_displayNameFromEmail(normalized)),
              countryCode: 'US',
              fraudScore: normalized == 'admin@earndash.dev' ? 6 : 12,
              totalCoins: normalized == 'admin@earndash.dev' ? 12480 : 3200,
              pendingCoins: normalized == 'admin@earndash.dev' ? 3200 : 600,
              withdrawableCoins:
                  normalized == 'admin@earndash.dev' ? 9280 : 2600,
              lifetimeEarned: normalized == 'admin@earndash.dev' ? 68420 : 9700,
              xp: normalized == 'admin@earndash.dev' ? 2860 : 840,
              dailyStreak: normalized == 'admin@earndash.dev' ? 5 : 3,
              referredEarners: normalized == 'admin@earndash.dev' ? 18 : 2,
              commissionEarnedCoins:
                  normalized == 'admin@earndash.dev' ? 4920 : 180,
              activeReferrals: normalized == 'admin@earndash.dev'
                  ? <ReferralEntry>[
                      ReferralEntry(
                          displayName: 'Ava',
                          lifetimeEarnedCoins: 12400,
                          commissionCoins: 1240,
                          status: 'Healthy'),
                      ReferralEntry(
                          displayName: 'Noah',
                          lifetimeEarnedCoins: 9800,
                          commissionCoins: 980,
                          status: 'Healthy'),
                      ReferralEntry(
                          displayName: 'Mia',
                          lifetimeEarnedCoins: 7600,
                          commissionCoins: 760,
                          status: 'Review-free'),
                    ]
                  : <ReferralEntry>[
                      ReferralEntry(
                          displayName: 'Kai',
                          lifetimeEarnedCoins: 1200,
                          commissionCoins: 120,
                          status: 'Healthy'),
                    ],
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
            );

      if (user.isBlocked) {
        throw Exception('This account has been blocked by admin review.');
      }

      user.lastDeviceFingerprint = deviceFingerprint;
      user.lastSeenAt = DateTime.now();
      final token = 'mock-token-${user.id}';
      _tokenToUserId[token] = user.id;
      return _toSession(user, token);
    });
  }

  Future<UserSession> signup({
    required String email,
    required String password,
    required String displayName,
    required String deviceFingerprint,
    String? referralCode,
    bool acceptedTerms = true,
  }) {
    return _withLatency(() {
      final normalized = email.trim().toLowerCase();
      if (_userIdByEmail.containsKey(normalized)) {
        throw Exception('Email already registered in demo mode');
      }

      final cleanName = displayName.trim().isEmpty
          ? _displayNameFromEmail(normalized)
          : displayName.trim();
      _MockUser? referrer;
      final normalizedReferral = referralCode?.trim().toUpperCase();
      if (normalizedReferral != null && normalizedReferral.isNotEmpty) {
        referrer = _findUserByReferralCode(normalizedReferral);
        if (referrer == null) {
          throw Exception('Referral code is not valid');
        }
      }

      final user = _createUser(
        email: normalized,
        displayName: cleanName,
        role: 'USER',
        referralCode: _generateReferralCode(cleanName),
        countryCode: 'US',
        fraudScore: 4,
        totalCoins: 250,
        pendingCoins: 0,
        withdrawableCoins: 250,
        lifetimeEarned: 0,
        xp: 80,
        dailyStreak: 1,
        referredEarners: 0,
        commissionEarnedCoins: 0,
        activeReferrals: <ReferralEntry>[],
        createdAt: DateTime.now(),
      );

      user.lastDeviceFingerprint = deviceFingerprint;
      user.lastSeenAt = DateTime.now();
      user.transactions.insert(
        0,
        _transaction(
          type: 'WELCOME_BONUS',
          status: 'COMPLETED',
          coins: 250,
          referenceType: 'SYSTEM',
        ),
      );

      if (referrer != null) {
        user.referredByUserId = referrer.id;
        referrer.activeReferrals.insert(
          0,
          ReferralEntry(
            displayName: user.displayName,
            lifetimeEarnedCoins: 0,
            commissionCoins: 0,
            status: 'New',
          ),
        );
        referrer.referredEarners = referrer.activeReferrals.length;
      }

      final token = 'mock-token-${user.id}';
      _tokenToUserId[token] = user.id;
      return _toSession(user, token);
    });
  }

  Future<UserSession> loginWithGoogle({
    required String email,
    required String displayName,
    required String deviceFingerprint,
    bool acceptedTerms = true,
  }) {
    return _withLatency(() {
      final normalized = email.trim().toLowerCase();
      final existingId = _userIdByEmail[normalized];
      final user = existingId != null
          ? _usersById[existingId]!
          : _createUser(
              email: normalized,
              displayName: displayName.trim().isEmpty
                  ? _displayNameFromEmail(normalized)
                  : displayName.trim(),
              role: 'USER',
              referralCode: _generateReferralCode(displayName),
              countryCode: 'US',
              fraudScore: 3,
              totalCoins: 250,
              pendingCoins: 0,
              withdrawableCoins: 250,
              lifetimeEarned: 0,
              xp: 120,
              dailyStreak: 1,
              referredEarners: 0,
              commissionEarnedCoins: 0,
              activeReferrals: <ReferralEntry>[],
              createdAt: DateTime.now(),
            );

      if (user.isBlocked) {
        throw Exception('This account has been blocked by admin review.');
      }

      user.lastDeviceFingerprint = deviceFingerprint;
      user.lastSeenAt = DateTime.now();
      final token = 'mock-token-${user.id}';
      _tokenToUserId[token] = user.id;
      return _toSession(user, token);
    });
  }

  Future<UserSession?> restoreSession(String token) {
    return _withLatency(() {
      final userId = _tokenToUserId[token];
      if (userId == null) {
        return null;
      }
      final user = _usersById[userId];
      if (user == null || user.isBlocked) {
        return null;
      }
      return _toSession(user, token);
    });
  }

  Future<List<OfferModel>> getOffers({
    required String userId,
    required String country,
  }) {
    return _withLatency(() => List<OfferModel>.from(_offers));
  }

  Future<WalletSummary> getWallet(String userId) {
    return _withLatency(() => _usersById[userId]!.walletSummary);
  }

  Future<GamificationProfile> getGamificationProfile(String userId) {
    return _withLatency(() => _usersById[userId]!.gamificationProfile);
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String currentUserId) {
    return _withLatency(() {
      final entries = _usersById.values
          .where((user) => !user.isBlocked)
          .map(
            (user) => LeaderboardEntry(
              userId: user.id,
              displayName: user.showInLeaderboard
                  ? user.displayName
                  : 'Anonymous ${_anonymousSuffixForUser(user.id)}',
              level: user.level,
              xp: user.xp,
              lifetimeEarned: user.lifetimeEarned,
            ),
          )
          .toList()
        ..sort((a, b) => b.lifetimeEarned.compareTo(a.lifetimeEarned));
      return entries.take(20).toList();
    });
  }

  Future<ReferralOverview> getReferralOverview(String userId) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      return ReferralOverview(
        referralCode: user.referralCode,
        referredEarners: user.referredEarners,
        commissionEarnedCoins: user.commissionEarnedCoins,
        abuseFlags: user.abuseFlags,
        activeReferrals: List<ReferralEntry>.from(user.activeReferrals),
        invitedByDisplayName: user.referredByUserId == null
            ? null
            : _usersById[user.referredByUserId!]?.displayName,
      );
    });
  }

  String _anonymousSuffixForUser(String userId) {
    final compactId = userId.replaceAll('-', '');
    final startIndex = compactId.length > 4 ? compactId.length - 4 : 0;
    return compactId.substring(startIndex).toUpperCase();
  }

  Future<AdminMetrics> getAdminMetrics() {
    return _withLatency(() {
      final users = _usersById.values.toList();
      final totalUsers = users.length;
      final dau = users.where((user) => user.dailyStreak > 0).length;
      final totalLifetimeCoins =
          users.fold<int>(0, (sum, user) => sum + user.lifetimeEarned);
      final fraudUsers = users.where((user) => user.fraudScore >= 60).length;

      return AdminMetrics(
        totalUsers: totalUsers,
        dailyActiveUsers: dau,
        offerConversionRate:
            _offerStarts == 0 ? 0 : (_completedOffers / _offerStarts) * 100,
        withdrawalRate:
            totalUsers == 0 ? 0 : (_withdrawals.length / totalUsers) * 100,
        fraudRate: totalUsers == 0 ? 0 : (fraudUsers / totalUsers) * 100,
        averageLtvUsd:
            totalUsers == 0 ? 0 : (totalLifetimeCoins / 1000) / totalUsers,
        revenuePerUserUsd:
            totalUsers == 0 ? 0 : (totalLifetimeCoins / 1000) / totalUsers,
      );
    });
  }

  Future<MoveEarnOverview> getMoveEarnOverview(
    String userId, {
    DeviceActivitySnapshot? snapshot,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      if (snapshot != null) {
        _applyDeviceSnapshot(user, snapshot: snapshot, awardRewards: false);
      }
      return _buildMoveOverview(user);
    });
  }

  Future<MoveEarnOverview> syncDeviceActivity({
    required String userId,
    required DeviceActivitySnapshot snapshot,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      _applyDeviceSnapshot(user, snapshot: snapshot, awardRewards: true);
      return _buildMoveOverview(user);
    });
  }

  Future<MoveEarnOverview> activateStepBoost(String userId) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      user.stepBoostEndsAt = DateTime.now().add(const Duration(minutes: 30));
      user.transactions.insert(
        0,
        _transaction(
          type: 'STEP_BOOST',
          status: 'COMPLETED',
          coins: 0,
          referenceType: 'BOOST_2X',
        ),
      );
      return _buildMoveOverview(user);
    });
  }

  Future<List<AdminUserSummary>> getAdminUsers(String adminUserId) {
    return _withLatency(() {
      _assertAdmin(adminUserId);
      final users = _usersById.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users
          .map(
            (user) => AdminUserSummary(
              id: user.id,
              displayName: user.displayName,
              email: user.email,
              role: user.role,
              countryCode: user.countryCode,
              referralCode: user.referralCode,
              fraudScore: user.fraudScore,
              totalCoins: user.totalCoins,
              pendingCoins: user.pendingCoins,
              withdrawableCoins: user.withdrawableCoins,
              lifetimeEarned: user.lifetimeEarned,
              dailyStreak: user.dailyStreak,
              isBlocked: user.isBlocked,
              isNewUser: _isNewUser(user),
              referredByDisplayName: user.referredByUserId == null
                  ? null
                  : _usersById[user.referredByUserId!]?.displayName,
              createdAt: user.createdAt,
            ),
          )
          .toList();
    });
  }

  Future<List<AdminWithdrawalRequest>> getAdminWithdrawals(String adminUserId) {
    return _withLatency(() {
      _assertAdmin(adminUserId);
      final items = List<_MockWithdrawal>.from(_withdrawals)
        ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return items
          .map(
            (item) => AdminWithdrawalRequest(
              id: item.id,
              userId: item.userId,
              userDisplayName:
                  _usersById[item.userId]?.displayName ?? 'Unknown',
              method: item.method,
              destination: item.destination,
              coins: item.coins,
              status: item.status,
              requestedAt: item.requestedAt,
              note: item.note,
            ),
          )
          .toList();
    });
  }

  Future<void> giftCoins({
    required String adminUserId,
    required String targetUserId,
    required int coins,
    required String note,
  }) {
    return _withLatency(() {
      _assertAdmin(adminUserId);
      if (coins <= 0) {
        throw Exception('Gift amount must be positive');
      }

      final user = _usersById[targetUserId]!;
      user.totalCoins += coins;
      user.withdrawableCoins += coins;
      user.transactions.insert(
        0,
        _transaction(
          type: 'ADMIN_GIFT',
          status: 'COMPLETED',
          coins: coins,
          referenceType: note.isEmpty ? 'ADMIN' : note,
        ),
      );
    });
  }

  Future<void> setUserBlocked({
    required String adminUserId,
    required String targetUserId,
    required bool blocked,
  }) {
    return _withLatency(() {
      _assertAdmin(adminUserId);
      final user = _usersById[targetUserId]!;
      if (user.role == 'ADMIN') {
        throw Exception('You cannot block the admin demo account');
      }
      user.isBlocked = blocked;
      user.transactions.insert(
        0,
        _transaction(
          type: blocked ? 'ACCOUNT_BLOCKED' : 'ACCOUNT_RESTORED',
          status: 'COMPLETED',
          coins: 0,
          referenceType: 'ADMIN_REVIEW',
        ),
      );
    });
  }

  Future<void> updateWithdrawalStatus({
    required String adminUserId,
    required String withdrawalId,
    required String status,
    String? note,
  }) {
    return _withLatency(() {
      _assertAdmin(adminUserId);
      final withdrawal =
          _withdrawals.firstWhere((item) => item.id == withdrawalId);
      final user = _usersById[withdrawal.userId]!;
      final nextStatus = status.trim().toUpperCase();
      final shouldRefund = nextStatus == 'REJECTED' &&
          withdrawal.status != 'REJECTED' &&
          !withdrawal.refunded;

      withdrawal.status = nextStatus;
      withdrawal.note = note;
      if (shouldRefund) {
        user.totalCoins += withdrawal.coins;
        user.withdrawableCoins += withdrawal.coins;
        withdrawal.refunded = true;
        user.transactions.insert(
          0,
          _transaction(
            type: 'WITHDRAWAL_REFUND',
            status: 'COMPLETED',
            coins: withdrawal.coins,
            referenceType: 'ADMIN_REJECTED',
          ),
        );
      } else {
        user.transactions.insert(
          0,
          _transaction(
            type: 'WITHDRAWAL_$nextStatus',
            status: 'COMPLETED',
            coins: 0,
            referenceType: 'ADMIN_REVIEW',
          ),
        );
      }
    });
  }

  Future<OfferModel> completeOffer({
    required String userId,
    required String offerId,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      final offer =
          _offers.firstWhere((item) => item.externalOfferId == offerId);
      _offerStarts += 1;
      _completedOffers += 1;

      user.totalCoins += offer.payoutCoins;
      user.pendingCoins += offer.payoutCoins;
      user.lifetimeEarned += offer.payoutCoins;
      user.xp += max(25, offer.payoutCoins ~/ 20);
      user.level = _levelForXp(user.xp);
      user.transactions.insert(
        0,
        _transaction(
          type: 'OFFER_PENDING',
          status: 'PENDING',
          coins: offer.payoutCoins,
          referenceType: offer.provider,
        ),
      );
      _ensureAchievement(
        user,
        title: 'First offer complete',
        description: 'You finished a rewarded offer.',
      );
      _creditReferralCommission(user, offer.payoutCoins, 'REFERRAL_OFFER');
      return offer;
    });
  }

  Future<int> settlePendingRewards(String userId) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      final settledCoins = user.pendingCoins;
      if (settledCoins == 0) {
        return 0;
      }

      user.pendingCoins = 0;
      user.withdrawableCoins += settledCoins;
      user.transactions.insert(
        0,
        _transaction(
          type: 'PENDING_RELEASE',
          status: 'COMPLETED',
          coins: settledCoins,
          referenceType: 'CRON_SIMULATION',
        ),
      );
      return settledCoins;
    });
  }

  Future<int> confirmAdReward({
    required String userId,
    required int coins,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      user.totalCoins += coins;
      user.withdrawableCoins += coins;
      user.lifetimeEarned += coins;
      user.xp += 10;
      user.level = _levelForXp(user.xp);
      user.transactions.insert(
        0,
        _transaction(
          type: 'AD_REWARD',
          status: 'COMPLETED',
          coins: coins,
          referenceType: 'ADMOB',
        ),
      );
      _ensureAchievement(
        user,
        title: 'Ad earner',
        description: 'Claimed coins from rewarded videos.',
      );
      _creditReferralCommission(user, coins, 'REFERRAL_ADS');
      return coins;
    });
  }

  Future<int> claimMiniGameReward({
    required String userId,
    required String gameId,
    required int score,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      if (score <= 0) {
        throw Exception('Finish a game with a score before claiming coins.');
      }

      final now = DateTime.now();
      final todayCoins = user.transactions
          .where(
            (item) =>
                item.referenceType == 'MINI_GAME' &&
                item.coins > 0 &&
                item.createdAt.year == now.year &&
                item.createdAt.month == now.month &&
                item.createdAt.day == now.day,
          )
          .fold<int>(0, (sum, item) => sum + item.coins);
      if (todayCoins >= 12) {
        throw Exception('Mini game daily cap reached. Come back tomorrow.');
      }

      final latestForGame =
          user.transactions.cast<WalletTransactionModel?>().firstWhere(
                (item) => item != null && item.type == 'MINI_GAME_$gameId',
                orElse: () => null,
              );
      if (latestForGame != null &&
          now.difference(latestForGame.createdAt).inSeconds < 30) {
        final waitSeconds =
            30 - now.difference(latestForGame.createdAt).inSeconds;
        throw Exception(
            'Please wait ${waitSeconds}s before claiming this mini game again.');
      }

      final divisor = switch (gameId) {
        'CARROM' => 35,
        'POOL' => 28,
        'TABLE_TENNIS' => 8,
        _ => 40,
      };
      final reward =
          min(3, min(12 - todayCoins, max(1, (score / divisor).ceil())));

      user.totalCoins += reward;
      user.pendingCoins += reward;
      user.lifetimeEarned += reward;
      user.xp += reward * 4;
      user.level = _levelForXp(user.xp);
      user.transactions.insert(
        0,
        _transaction(
          type: 'MINI_GAME_$gameId',
          status: 'PENDING',
          coins: reward,
          referenceType: 'MINI_GAME',
        ),
      );
      _ensureAchievement(
        user,
        title: 'Arcade starter',
        description: 'Claimed coins from the mini games corner.',
      );
      return reward;
    });
  }

  Future<void> requestWithdrawal({
    required String userId,
    required String method,
    required String destination,
    required int coins,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      if (user.isBlocked) {
        throw Exception('Withdrawals are disabled on this account');
      }
      if (coins < 50000) {
        throw Exception('Minimum withdrawal is 5,000 coins');
      }
      if (user.withdrawableCoins < coins) {
        throw Exception('Not enough withdrawable balance');
      }

      if (_isNewUser(user)) {
        final now = DateTime.now();
        final todayTotal = _withdrawals
            .where(
              (item) =>
                  item.userId == userId &&
                  item.requestedAt.year == now.year &&
                  item.requestedAt.month == now.month &&
                  item.requestedAt.day == now.day &&
                  item.status != 'REJECTED',
            )
            .fold<int>(0, (sum, item) => sum + item.coins);
        if (todayTotal + coins > 200000) {
          throw Exception('New users are capped at 20,000 coins per day');
        }
      }

      user.withdrawableCoins -= coins;
      user.totalCoins -= coins;
      final withdrawal = _MockWithdrawal(
        id: 'wd-${++_withdrawalSequence}',
        userId: userId,
        method: method,
        destination: destination,
        coins: coins,
        status: 'PENDING_APPROVAL',
        requestedAt: DateTime.now(),
        note: null,
      );
      _withdrawals.insert(0, withdrawal);
      user.transactions.insert(
        0,
        _transaction(
          type: 'WITHDRAWAL_REQUEST',
          status: 'PENDING_APPROVAL',
          coins: -coins,
          referenceType: method,
        ),
      );
    });
  }

  Future<List<WithdrawalRequestModel>> getWithdrawals(String userId) {
    return _withLatency(() {
      return _withdrawals
          .where((item) => item.userId == userId)
          .toList()
          .reversed
          .map(
            (item) => WithdrawalRequestModel(
              id: item.id,
              method: item.method,
              destination: item.destination,
              coins: item.coins,
              status: item.status,
              createdAt: item.requestedAt,
              note: item.note,
            ),
          )
          .toList();
    });
  }

  Future<SessionUser> updatePreferences({
    required String userId,
    required bool showInLeaderboard,
  }) {
    return _withLatency(() {
      final user = _usersById[userId]!;
      user.showInLeaderboard = showInLeaderboard;
      return _toSession(user, 'mock-token-${user.id}').user;
    });
  }

  _MockUser _createUser({
    required String email,
    required String displayName,
    required String role,
    required String referralCode,
    required String countryCode,
    required int fraudScore,
    required int totalCoins,
    required int pendingCoins,
    required int withdrawableCoins,
    required int lifetimeEarned,
    required int xp,
    required int dailyStreak,
    required int referredEarners,
    required int commissionEarnedCoins,
    required List<ReferralEntry> activeReferrals,
    required DateTime createdAt,
  }) {
    final user = _MockUser(
      id: 'user-${++_userSequence}',
      email: email,
      displayName: displayName,
      role: role,
      referralCode: referralCode,
      countryCode: countryCode,
      fraudScore: fraudScore,
      totalCoins: totalCoins,
      pendingCoins: pendingCoins,
      withdrawableCoins: withdrawableCoins,
      lifetimeEarned: lifetimeEarned,
      xp: xp,
      level: _levelForXp(xp),
      dailyStreak: dailyStreak,
      referredEarners: referredEarners,
      commissionEarnedCoins: commissionEarnedCoins,
      abuseFlags: 0,
      activeReferrals: activeReferrals,
      achievements: <AchievementModel>[
        AchievementModel(
          title: 'Verified account',
          description: 'Completed a secure sign in.',
        ),
      ],
      transactions: <WalletTransactionModel>[
        _transaction(
          type: 'INITIAL_BALANCE',
          status: 'COMPLETED',
          coins: withdrawableCoins,
          referenceType: 'SEED',
        ),
      ],
      createdAt: createdAt,
      lastSeenAt: createdAt,
    );

    _usersById[user.id] = user;
    _userIdByEmail[email] = user.id;
    return user;
  }

  UserSession _toSession(_MockUser user, String token) {
    return UserSession(
      accessToken: token,
      user: SessionUser(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        referralCode: user.referralCode,
        showInLeaderboard: user.showInLeaderboard,
        countryCode: user.countryCode,
        fraudScore: user.fraudScore,
      ),
    );
  }

  WalletTransactionModel _transaction({
    required String type,
    required String status,
    required int coins,
    required String referenceType,
  }) {
    return WalletTransactionModel(
      type: type,
      status: status,
      coins: coins,
      referenceType: referenceType,
      createdAt: DateTime.now(),
    );
  }

  void _seed() {
    final admin = _createUser(
      email: 'admin@earndash.dev',
      displayName: 'Soham',
      role: 'ADMIN',
      referralCode: 'SOHAMX1',
      countryCode: 'US',
      fraudScore: 12,
      totalCoins: 12480,
      pendingCoins: 3200,
      withdrawableCoins: 9280,
      lifetimeEarned: 68420,
      xp: 2860,
      dailyStreak: 5,
      referredEarners: 18,
      commissionEarnedCoins: 4920,
      activeReferrals: <ReferralEntry>[
        ReferralEntry(
            displayName: 'Ava',
            lifetimeEarnedCoins: 12400,
            commissionCoins: 1240,
            status: 'Healthy'),
        ReferralEntry(
            displayName: 'Noah',
            lifetimeEarnedCoins: 9800,
            commissionCoins: 980,
            status: 'Healthy'),
        ReferralEntry(
            displayName: 'Mia',
            lifetimeEarnedCoins: 7600,
            commissionCoins: 760,
            status: 'Review-free'),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    );

    final sara = _createUser(
      email: 'sara@earndash.dev',
      displayName: 'Sara',
      role: 'USER',
      referralCode: 'SARAX2',
      countryCode: 'CA',
      fraudScore: 18,
      totalCoins: 9820,
      pendingCoins: 700,
      withdrawableCoins: 9120,
      lifetimeEarned: 32840,
      xp: 2140,
      dailyStreak: 9,
      referredEarners: 2,
      commissionEarnedCoins: 1310,
      activeReferrals: <ReferralEntry>[],
      createdAt: DateTime.now().subtract(const Duration(days: 75)),
    );

    final leo = _createUser(
      email: 'leo@earndash.dev',
      displayName: 'Leo',
      role: 'USER',
      referralCode: 'LEOX3',
      countryCode: 'UK',
      fraudScore: 64,
      totalCoins: 6320,
      pendingCoins: 2100,
      withdrawableCoins: 4220,
      lifetimeEarned: 18400,
      xp: 1390,
      dailyStreak: 2,
      referredEarners: 0,
      commissionEarnedCoins: 120,
      activeReferrals: <ReferralEntry>[],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    );
    leo.referredByUserId = sara.id;

    final nia = _createUser(
      email: 'nia@earndash.dev',
      displayName: 'Nia',
      role: 'USER',
      referralCode: 'NIAX4',
      countryCode: 'US',
      fraudScore: 9,
      totalCoins: 1400,
      pendingCoins: 0,
      withdrawableCoins: 1400,
      lifetimeEarned: 2150,
      xp: 420,
      dailyStreak: 2,
      referredEarners: 0,
      commissionEarnedCoins: 0,
      activeReferrals: <ReferralEntry>[],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    nia.referredByUserId = sara.id;
    sara.activeReferrals = <ReferralEntry>[
      ReferralEntry(
          displayName: 'Leo',
          lifetimeEarnedCoins: leo.lifetimeEarned,
          commissionCoins: 120,
          status: 'Review'),
      ReferralEntry(
          displayName: 'Nia',
          lifetimeEarnedCoins: nia.lifetimeEarned,
          commissionCoins: 215,
          status: 'Healthy'),
    ];

    for (final user in _usersById.values) {
      if (user.transactions.length == 1) {
        user.transactions.insert(
          0,
          _transaction(
            type: 'AD_REWARD',
            status: 'COMPLETED',
            coins: 15,
            referenceType: 'SEED',
          ),
        );
        if (user.pendingCoins > 0) {
          user.transactions.insert(
            0,
            _transaction(
              type: 'OFFER_PENDING',
              status: 'PENDING',
              coins: min(1800, user.pendingCoins),
              referenceType: 'SEED',
            ),
          );
        }
      }
      _ensureAchievement(
        user,
        title: 'Streak runner',
        description: 'Logged in on consecutive days.',
      );
    }

    _withdrawals.addAll(<_MockWithdrawal>[
      _MockWithdrawal(
        id: 'wd-${++_withdrawalSequence}',
        userId: sara.id,
        method: 'PAYPAL',
        destination: 'sara@paypal.test',
        coins: 50000,
        status: 'PENDING_APPROVAL',
        requestedAt: DateTime.now().subtract(const Duration(hours: 5)),
        note: 'First cash out',
      ),
      _MockWithdrawal(
        id: 'wd-${++_withdrawalSequence}',
        userId: leo.id,
        method: 'USDT',
        destination: 'TRX-T12345',
        coins: 60000,
        status: 'APPROVED',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        note: 'Manual review required',
      ),
      _MockWithdrawal(
        id: 'wd-${++_withdrawalSequence}',
        userId: nia.id,
        method: 'GIFT_CARD',
        destination: 'Amazon',
        coins: 50000,
        status: 'REJECTED',
        requestedAt: DateTime.now().subtract(const Duration(days: 2)),
        note: 'KYC mismatch',
      ),
    ]);

    _offerStarts = 42;
    _completedOffers = 18;
    admin.transactions.insert(
      0,
      _transaction(
        type: 'REFERRAL_COMMISSION',
        status: 'COMPLETED',
        coins: 220,
        referenceType: 'SEED',
      ),
    );
    for (final user in _usersById.values) {
      user.weeklyActivity = _seedWeeklyActivity(user.displayName);
      user.todayActivity = user.weeklyActivity.last.copy();
      user.activityDateKey =
          '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      _updateActivityRank(user);
      _updateGoalStreak(user);
      for (final milestone in <int>[3, 7, 30]) {
        if (user.goalStreakDays >= milestone) {
          user.claimedGoalStreakMilestones.add(milestone);
        }
      }
    }
  }

  void _ensureAchievement(
    _MockUser user, {
    required String title,
    required String description,
  }) {
    final exists = user.achievements.any((item) => item.title == title);
    if (!exists) {
      user.achievements.insert(
        0,
        AchievementModel(title: title, description: description),
      );
    }
  }

  void _creditReferralCommission(
    _MockUser earningUser,
    int earnedCoins,
    String referenceType,
  ) {
    final referrerId = earningUser.referredByUserId;
    if (referrerId == null || earnedCoins <= 0) {
      return;
    }

    final referrer = _usersById[referrerId];
    if (referrer == null) {
      return;
    }

    final commission = max(1, earnedCoins ~/ 10);
    referrer.totalCoins += commission;
    referrer.withdrawableCoins += commission;
    referrer.commissionEarnedCoins += commission;
    referrer.transactions.insert(
      0,
      _transaction(
        type: 'REFERRAL_COMMISSION',
        status: 'COMPLETED',
        coins: commission,
        referenceType: referenceType,
      ),
    );

    final index = referrer.activeReferrals.indexWhere(
      (entry) => entry.displayName == earningUser.displayName,
    );
    final updatedEntry = ReferralEntry(
      displayName: earningUser.displayName,
      lifetimeEarnedCoins: earningUser.lifetimeEarned,
      commissionCoins:
          (index >= 0 ? referrer.activeReferrals[index].commissionCoins : 0) +
              commission,
      status: earningUser.fraudScore >= 60 ? 'Review' : 'Healthy',
    );
    if (index >= 0) {
      referrer.activeReferrals[index] = updatedEntry;
    } else {
      referrer.activeReferrals.insert(0, updatedEntry);
    }
    referrer.referredEarners = referrer.activeReferrals.length;
  }

  _MockUser? _findUserByReferralCode(String referralCode) {
    for (final user in _usersById.values) {
      if (user.referralCode.toUpperCase() == referralCode) {
        return user;
      }
    }
    return null;
  }

  void _assertAdmin(String adminUserId) {
    final user = _usersById[adminUserId];
    if (user == null || user.role != 'ADMIN') {
      throw Exception('Admin access required');
    }
  }

  bool _isNewUser(_MockUser user) {
    return DateTime.now().difference(user.createdAt).inDays < 14;
  }

  MoveEarnOverview _buildMoveOverview(_MockUser user) {
    final weeklySteps = user.weeklyActivity.fold<int>(
      0,
      (sum, item) => sum + item.steps,
    );
    return MoveEarnOverview(
      todaySteps: user.todayActivity.steps,
      distanceKm: user.todayActivity.distanceKm,
      activeMinutes: user.todayActivity.activeMinutes,
      walkMinutes: user.todayActivity.walkMinutes,
      runMinutes: user.todayActivity.runMinutes,
      calories: user.todayActivity.calories,
      rewardedCoinsToday: user.todayActivity.rewardedCoins,
      rewardedStepsToday: user.todayActivity.rewardedSteps,
      dailyRewardStepCap: user.rankDailyCap,
      dailyGoalSteps: user.dailyGoalSteps,
      weeklySteps: weeklySteps,
      weeklyGoalSteps: 50000,
      goalStreakDays: user.goalStreakDays,
      rank: user.fitnessRank,
      rankMultiplier: user.rankMultiplier,
      rankDailyCap: user.rankDailyCap,
      stepBoostActive: user.stepBoostEndsAt != null,
      stepBoostMultiplier: user.stepBoostEndsAt != null ? 2 : 1,
      stepBoostEndsAt: user.stepBoostEndsAt,
      weeklyChart: user.weeklyActivity
          .map(
            (item) => WeeklyActivityBar(
              label: item.label,
              steps: item.steps,
              distanceKm: item.distanceKm,
            ),
          )
          .toList(),
      weeklyChallenges: <WeeklyChallengeModel>[
        WeeklyChallengeModel(
          title: 'Walk 30,000 steps',
          progress: weeklySteps.toDouble(),
          target: 30000,
          rewardCoins: 180,
          unit: 'steps',
          completed: weeklySteps >= 30000,
        ),
        WeeklyChallengeModel(
          title: 'Run 5 km',
          progress: user.weeklyActivity.fold<double>(
            0,
            (sum, item) => sum + item.runDistanceKm,
          ),
          target: 5,
          rewardCoins: 140,
          unit: 'km',
          completed: user.weeklyActivity.fold<double>(
                0,
                (sum, item) => sum + item.runDistanceKm,
              ) >=
              5,
        ),
        WeeklyChallengeModel(
          title: 'Stay active 5 days',
          progress: user.weeklyActivity
              .where((item) => item.steps >= user.dailyGoalSteps)
              .length
              .toDouble(),
          target: 5,
          rewardCoins: 120,
          unit: 'days',
          completed: user.weeklyActivity
                  .where((item) => item.steps >= user.dailyGoalSteps)
                  .length >=
              5,
        ),
      ],
      leaderboard: _usersById.values
          .where((item) => !item.isBlocked)
          .map(
            (item) => ActivityLeaderboardEntry(
              displayName: item.displayName,
              steps: item.weeklyActivity.fold<int>(
                0,
                (sum, day) => sum + day.steps,
              ),
              distanceKm: item.weeklyActivity.fold<double>(
                0,
                (sum, day) => sum + day.distanceKm,
              ),
              rank: item.fitnessRank,
            ),
          )
          .toList()
        ..sort((a, b) => b.steps.compareTo(a.steps)),
      suspiciousActivityBlocked: user.todayActivity.cheatBlocked,
      antiCheatMessage: user.todayActivity.cheatBlocked
          ? 'Activity rejected because the detected speed looked unrealistic.'
          : user.trackingMessage,
      trackingAvailable: user.trackingAvailable,
      trackingPermissionGranted: user.trackingPermissionGranted,
      trackingStatus: user.trackingStatus,
      trackingSource: user.trackingSource,
      trackingMessage: user.trackingMessage,
    );
  }

  void _applyDeviceSnapshot(
    _MockUser user, {
    required DeviceActivitySnapshot snapshot,
    required bool awardRewards,
  }) {
    _refreshBoost(user);
    user.trackingAvailable = snapshot.supported;
    user.trackingPermissionGranted = snapshot.permissionGranted;
    user.trackingStatus = snapshot.status;
    user.trackingSource = snapshot.source;
    user.trackingMessage = snapshot.message;

    if (snapshot.weeklyHistory.isNotEmpty) {
      final previousRewardedSteps =
          user.activityDateKey == snapshot.todayDateKey
              ? user.todayActivity.rewardedSteps
              : 0;
      final previousRewardedCoins =
          user.activityDateKey == snapshot.todayDateKey
              ? user.todayActivity.rewardedCoins
              : 0;

      user.activityDateKey = snapshot.todayDateKey;
      user.weeklyActivity = snapshot.weeklyHistory
          .map(
            (item) => _ActivityDay(
              label: item.label,
              steps: item.steps,
              distanceKm: item.distanceKm,
              runDistanceKm: item.runMinutes <= 0
                  ? 0
                  : item.distanceKm *
                      (item.runMinutes / max(1, item.activeMinutes)),
              activeMinutes: item.activeMinutes,
              walkMinutes: item.walkMinutes,
              runMinutes: item.runMinutes,
              calories: item.calories,
            ),
          )
          .toList();

      user.todayActivity = user.weeklyActivity.last.copy();
      user.todayActivity.rewardedSteps = min(
        previousRewardedSteps,
        user.todayActivity.steps,
      );
      user.todayActivity.rewardedCoins = previousRewardedCoins;
    }

    final activeMinutes = max(1, user.todayActivity.activeMinutes);
    final speedKmh = user.todayActivity.distanceKm / (activeMinutes / 60);
    user.todayActivity.cheatBlocked =
        speedKmh > 18 || user.todayActivity.steps > 75000;

    _updateActivityRank(user);
    _updateGoalStreak(user);

    if (!awardRewards ||
        user.todayActivity.cheatBlocked ||
        !snapshot.permissionGranted ||
        !snapshot.supported) {
      return;
    }

    final rewardableSteps = min(user.todayActivity.steps, user.rankDailyCap);
    final newRewardableSteps = max(
      0,
      rewardableSteps - user.todayActivity.rewardedSteps,
    );
    final stepChunks = newRewardableSteps ~/ 1000;
    var earnedCoins = (stepChunks * 10 * user.rankMultiplier).round();
    if (user.stepBoostEndsAt != null) {
      earnedCoins *= 2;
    }

    if (stepChunks <= 0) {
      return;
    }

    final consumedSteps = stepChunks * 1000;
    user.todayActivity.rewardedSteps += consumedSteps;
    user.todayActivity.rewardedCoins += earnedCoins;
    user.weeklyActivity[user.weeklyActivity.length - 1] =
        user.todayActivity.copy();
    user.totalCoins += earnedCoins;
    user.withdrawableCoins += earnedCoins;
    user.lifetimeEarned += earnedCoins;
    user.xp += max(12, earnedCoins);
    user.level = _levelForXp(user.xp);
    user.transactions.insert(
      0,
      _transaction(
        type: user.todayActivity.runMinutes > user.todayActivity.walkMinutes
            ? 'RUN_REWARD'
            : 'WALK_REWARD',
        status: 'COMPLETED',
        coins: earnedCoins,
        referenceType: 'MOVE_EARN_DEVICE',
      ),
    );
    _ensureAchievement(
      user,
      title: 'Move & earn unlocked',
      description: 'Earned coins from daily activity.',
    );
    _creditReferralCommission(user, earnedCoins, 'REFERRAL_MOVE');
    _grantGoalStreakBonus(user);
  }

  List<_ActivityDay> _seedWeeklyActivity(String displayName) {
    final base = 3200 + displayName.length * 550;
    const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List<_ActivityDay>.generate(labels.length, (index) {
      final steps = base + _random.nextInt(4500);
      final distance = steps * 0.00078;
      final runDistance = index.isEven ? distance * 0.35 : distance * 0.18;
      return _ActivityDay(
        label: labels[index],
        steps: steps,
        distanceKm: distance,
        runDistanceKm: runDistance,
        activeMinutes: max(18, (distance * 11).round()),
        walkMinutes: max(10, (distance * 8).round()),
        runMinutes: max(4, (runDistance * 10).round()),
        calories: (steps * 0.04).round(),
        rewardedSteps: min(steps, 8000),
        rewardedCoins: (min(steps, 8000) ~/ 1000) * 10,
      );
    });
  }

  void _refreshBoost(_MockUser user) {
    final endsAt = user.stepBoostEndsAt;
    if (endsAt != null && endsAt.isBefore(DateTime.now())) {
      user.stepBoostEndsAt = null;
    }
  }

  void _updateActivityRank(_MockUser user) {
    final weeklySteps =
        user.weeklyActivity.fold<int>(0, (sum, item) => sum + item.steps);
    user.fitnessRank = _activityRank(weeklySteps);
    switch (user.fitnessRank) {
      case 'Elite':
        user.rankMultiplier = 1.6;
        user.rankDailyCap = 20000;
        break;
      case 'Gold':
        user.rankMultiplier = 1.4;
        user.rankDailyCap = 15000;
        break;
      case 'Silver':
        user.rankMultiplier = 1.2;
        user.rankDailyCap = 12000;
        break;
      default:
        user.rankMultiplier = 1.0;
        user.rankDailyCap = 10000;
    }
  }

  void _updateGoalStreak(_MockUser user) {
    var streak = 0;
    for (final day in user.weeklyActivity.reversed) {
      if (day.steps >= user.dailyGoalSteps) {
        streak += 1;
      } else {
        break;
      }
    }
    user.goalStreakDays = max(user.goalStreakDays, streak);
  }

  void _grantGoalStreakBonus(_MockUser user) {
    const bonuses = <int, int>{3: 30, 7: 90, 30: 400};
    for (final entry in bonuses.entries) {
      final milestone = entry.key;
      final coins = entry.value;
      if (user.goalStreakDays >= milestone &&
          !user.claimedGoalStreakMilestones.contains(milestone)) {
        user.claimedGoalStreakMilestones.add(milestone);
        user.totalCoins += coins;
        user.withdrawableCoins += coins;
        user.lifetimeEarned += coins;
        user.transactions.insert(
          0,
          _transaction(
            type: 'GOAL_STREAK_BONUS',
            status: 'COMPLETED',
            coins: coins,
            referenceType: '${milestone}_DAY_STREAK',
          ),
        );
      }
    }
  }

  String _activityRank(int weeklySteps) {
    if (weeklySteps >= 80000) {
      return 'Elite';
    }
    if (weeklySteps >= 55000) {
      return 'Gold';
    }
    if (weeklySteps >= 35000) {
      return 'Silver';
    }
    return 'Bronze';
  }

  int _levelForXp(int xp) => (xp ~/ 500) + 1;

  String _displayNameFromEmail(String email) {
    final local = email.split('@').first;
    return local.isEmpty
        ? 'Earner'
        : '${local[0].toUpperCase()}${local.substring(1)}';
  }

  String _generateReferralCode(String displayName) {
    final safe =
        displayName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final prefix = (safe.isEmpty ? 'USER' : safe)
        .substring(0, min(6, max(1, safe.length)));
    return '$prefix${100 + _random.nextInt(899)}';
  }
}

class _MockUser {
  _MockUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.referralCode,
    required this.countryCode,
    required this.fraudScore,
    required this.totalCoins,
    required this.pendingCoins,
    required this.withdrawableCoins,
    required this.lifetimeEarned,
    required this.xp,
    required this.level,
    required this.dailyStreak,
    required this.referredEarners,
    required this.commissionEarnedCoins,
    required this.abuseFlags,
    required this.activeReferrals,
    required this.achievements,
    required this.transactions,
    required this.createdAt,
    required this.lastSeenAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String referralCode;
  final String countryCode;
  final int fraudScore;
  int totalCoins;
  int pendingCoins;
  int withdrawableCoins;
  int lifetimeEarned;
  int xp;
  int level;
  int dailyStreak;
  int referredEarners;
  int commissionEarnedCoins;
  int abuseFlags;
  bool isBlocked = false;
  bool showInLeaderboard = false;
  String? lastDeviceFingerprint;
  String? referredByUserId;
  DateTime createdAt;
  DateTime lastSeenAt;
  _ActivityDay todayActivity = _ActivityDay(label: 'Today');
  List<_ActivityDay> weeklyActivity = <_ActivityDay>[];
  String fitnessRank = 'Bronze';
  double rankMultiplier = 1.0;
  int rankDailyCap = 10000;
  String activityDateKey = '';
  int dailyGoalSteps = 5000;
  int goalStreakDays = 0;
  DateTime? stepBoostEndsAt;
  final Set<int> claimedGoalStreakMilestones = <int>{};
  bool trackingAvailable = true;
  bool trackingPermissionGranted = true;
  String trackingStatus = 'unknown';
  String trackingSource = 'demo';
  String? trackingMessage;
  List<ReferralEntry> activeReferrals;
  List<AchievementModel> achievements;
  List<WalletTransactionModel> transactions;

  WalletSummary get walletSummary => WalletSummary(
        totalCoins: totalCoins,
        pendingCoins: pendingCoins,
        withdrawableCoins: withdrawableCoins,
        lifetimeEarned: lifetimeEarned,
        transactionHistory: List<WalletTransactionModel>.from(transactions),
      );

  GamificationProfile get gamificationProfile => GamificationProfile(
        level: level,
        xp: xp,
        dailyStreak: dailyStreak,
        achievements: List<AchievementModel>.from(achievements),
      );
}

class _ActivityDay {
  _ActivityDay({
    required this.label,
    this.steps = 0,
    this.distanceKm = 0,
    this.runDistanceKm = 0,
    this.activeMinutes = 0,
    this.walkMinutes = 0,
    this.runMinutes = 0,
    this.calories = 0,
    this.rewardedSteps = 0,
    this.rewardedCoins = 0,
    this.cheatBlocked = false,
  });

  final String label;
  int steps;
  double distanceKm;
  double runDistanceKm;
  int activeMinutes;
  int walkMinutes;
  int runMinutes;
  int calories;
  int rewardedSteps;
  int rewardedCoins;
  bool cheatBlocked;

  _ActivityDay copy() => _ActivityDay(
        label: label,
        steps: steps,
        distanceKm: distanceKm,
        runDistanceKm: runDistanceKm,
        activeMinutes: activeMinutes,
        walkMinutes: walkMinutes,
        runMinutes: runMinutes,
        calories: calories,
        rewardedSteps: rewardedSteps,
        rewardedCoins: rewardedCoins,
        cheatBlocked: cheatBlocked,
      );
}

class _MockWithdrawal {
  _MockWithdrawal({
    required this.id,
    required this.userId,
    required this.method,
    required this.destination,
    required this.coins,
    required this.status,
    required this.requestedAt,
    required this.note,
  });

  final String id;
  final String userId;
  final String method;
  final String destination;
  final int coins;
  final DateTime requestedAt;
  String status;
  String? note;
  bool refunded = false;
}

import { Injectable } from '@nestjs/common';
import { AnalyticsService } from '../analytics/analytics.service';
import { AuditService } from '../audit/audit.service';
import { FraudService } from '../fraud/fraud.service';
import { UsersService } from '../users/users.service';
import { WithdrawalsService } from '../withdrawals/withdrawals.service';
import { WalletService } from '../wallet/wallet.service';
import { WalletTransactionType } from '../wallet/entities/wallet-transaction.entity';

@Injectable()
export class AdminService {
  constructor(
    private readonly usersService: UsersService,
    private readonly fraudService: FraudService,
    private readonly withdrawalsService: WithdrawalsService,
    private readonly analyticsService: AnalyticsService,
    private readonly auditService: AuditService,
    private readonly walletService: WalletService,
  ) {}

  async listUsers() {
    const users = await this.usersService.listAllWithWallet();
    return users.map((user) => ({
      id: user.id,
      displayName: user.displayName,
      email: user.email,
      role: user.role,
      countryCode: user.countryCode,
      referralCode: user.referralCode,
      fraudScore: user.fraudScore,
      totalCoins: user.wallet?.totalCoins ?? 0,
      pendingCoins: user.wallet?.pendingCoins ?? 0,
      withdrawableCoins: user.wallet?.withdrawableCoins ?? 0,
      lifetimeEarned: user.wallet?.lifetimeEarned ?? 0,
      dailyStreak: user.dailyStreak,
      isBlocked: user.isBlocked,
      isNewUser: user.createdAt.getTime() > Date.now() - 14 * 24 * 60 * 60 * 1000,
      referredByDisplayName: user.referredBy?.displayName ?? null,
      createdAt: user.createdAt,
    }));
  }

  async giftCoins(
    actorId: string,
    targetUserId: string,
    coins: number,
    note: string,
    referenceId?: string,
  ) {
    await this.walletService.addAvailableCoins(
      targetUserId,
      coins,
      WalletTransactionType.ADJUSTMENT,
      'ADMIN_GIFT',
      referenceId ?? `gift:${Date.now()}`,
      { note, actorId },
    );
    await this.auditService.log(actorId, 'ADMIN_GIFT_COINS', 'USER', targetUserId, {
      coins,
      note,
    });
    return { success: true };
  }

  async setUserBlocked(actorId: string, targetUserId: string, blocked: boolean) {
    const user = await this.usersService.getByIdOrFail(targetUserId);
    user.isBlocked = blocked;
    user.withdrawalsDisabled = blocked || user.withdrawalsDisabled;
    await this.usersService.save(user);
    await this.auditService.log(actorId, 'ADMIN_SET_USER_BLOCK', 'USER', targetUserId, {
      blocked,
    });
    return { success: true, blocked };
  }

  async fraudPanel() {
    const users = await this.usersService.listFlaggedUsers();
    return Promise.all(users.map((user) => this.fraudService.analyzeUser(user.id)));
  }

  withdrawals() {
    return this.withdrawalsService.pendingReview();
  }

  analytics() {
    return this.analyticsService.overview();
  }

  auditLogs() {
    return this.auditService.listRecent();
  }
}

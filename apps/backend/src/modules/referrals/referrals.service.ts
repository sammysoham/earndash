import { Injectable } from '@nestjs/common';
import { WalletService } from '../wallet/wallet.service';
import { OfferCompletion } from '../offerwall/entities/offer-completion.entity';
import { ReferralsRepository } from './repositories/referrals.repository';
import { User } from '../users/entities/user.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class ReferralsService {
  constructor(
    private readonly referralsRepository: ReferralsRepository,
    private readonly walletService: WalletService,
    private readonly usersService: UsersService,
  ) {}

  async createReferralRelationship(referrer: User, referredUser: User): Promise<void> {
    const existing = await this.referralsRepository.findByReferredUserId(referredUser.id);
    if (existing || referrer.id === referredUser.id) {
      return;
    }

    await this.referralsRepository.save(
      this.referralsRepository.create({
        referrerId: referrer.id,
        referredUserId: referredUser.id,
        commissionRate: '0.10',
        lifetimeCommissionCoins: 0,
      }),
    );
  }

  async creditCommissionForOffer(completion: OfferCompletion): Promise<void> {
    const referral = await this.referralsRepository.findByReferredUserId(completion.userId);
    if (!referral) {
      return;
    }

    const existing = await this.referralsRepository.findPayoutBySourceCompletionId(completion.id);
    if (existing) {
      return;
    }

    const commissionCoins = Math.floor(completion.payoutCoins * Number(referral.commissionRate));
    if (commissionCoins <= 0) {
      return;
    }

    await this.referralsRepository.savePayout(
      this.referralsRepository.createPayout({
        referralId: referral.id,
        sourceCompletionId: completion.id,
        coins: commissionCoins,
      }),
    );

    referral.lifetimeCommissionCoins += commissionCoins;
    await this.referralsRepository.save(referral);

    await this.walletService.addPendingCoins(
      referral.referrerId,
      commissionCoins,
      'REFERRAL_PAYOUT',
      completion.id,
      { referredUserId: completion.userId },
    );
  }

  getTopReferrers() {
    return this.referralsRepository.listTopReferrers();
  }

  async getOverview(userId: string) {
    const user = await this.usersService.getByIdOrFail(userId);
    const referrals = await this.referralsRepository.listByReferrerId(userId);
    const abuseFlags = referrals.filter(
      (item) =>
        (item.referredUser?.lastKnownIp &&
          item.referredUser.lastKnownIp === user.lastKnownIp) ||
        (item.referredUser?.deviceFingerprint &&
          item.referredUser.deviceFingerprint === user.deviceFingerprint),
    ).length;

    return {
      referralCode: user.referralCode,
      referredEarners: referrals.length,
      commissionEarnedCoins: referrals.reduce(
        (sum, item) => sum + item.lifetimeCommissionCoins,
        0,
      ),
      abuseFlags,
      activeReferrals: referrals.map((item) => ({
        displayName: item.referredUser?.displayName ?? 'Friend',
        lifetimeEarnedCoins: item.referredUser?.wallet?.lifetimeEarned ?? 0,
        commissionCoins: item.lifetimeCommissionCoins,
        status: item.referredUser?.isBlocked ? 'Blocked' : 'Healthy',
      })),
      invitedByDisplayName: user.referredBy?.displayName ?? null,
    };
  }
}

import { Injectable } from '@nestjs/common';
import { UsersRepository } from '../users/repositories/users.repository';
import { OfferCompletionsRepository } from '../offerwall/repositories/offer-completions.repository';
import { WithdrawalsRepository } from '../withdrawals/repositories/withdrawals.repository';
import { WalletsRepository } from '../wallet/repositories/wallets.repository';

@Injectable()
export class AnalyticsService {
  constructor(
    private readonly usersRepository: UsersRepository,
    private readonly offerCompletionsRepository: OfferCompletionsRepository,
    private readonly withdrawalsRepository: WithdrawalsRepository,
    private readonly walletsRepository: WalletsRepository,
  ) {}

  async overview() {
    const usersRepo = this.usersRepository.getRepository();
    const walletsRepo = this.walletsRepository.getRepository();
    const completionRepo = this.offerCompletionsRepository.getCompletionRepository();
    const offerRequestRepo = this.offerCompletionsRepository.getRequestLogRepository();
    const withdrawalRepo = this.withdrawalsRepository.getRepository();

    const [
      totalUsers,
      dailyActiveUsers,
      totalCompletions,
      totalOfferViews,
      totalWithdrawals,
      totalFraudUsers,
      walletRows,
    ] = await Promise.all([
      usersRepo.count(),
      usersRepo
        .createQueryBuilder('user')
        .where("user.lastLoginAt >= NOW() - INTERVAL '24 HOURS'")
        .getCount(),
      completionRepo.count(),
      offerRequestRepo.count(),
      withdrawalRepo.count(),
      usersRepo.createQueryBuilder('user').where('user.withdrawalsDisabled = true').getCount(),
      walletsRepo.find(),
    ]);

    const lifetimeCoins = walletRows.reduce((sum, wallet) => sum + wallet.lifetimeEarned, 0);
    const revenuePerUserUsd = totalUsers > 0 ? Number(((lifetimeCoins / 1000) / totalUsers).toFixed(2)) : 0;
    const averageLtvUsd = revenuePerUserUsd;

    return {
      totalUsers,
      dailyActiveUsers,
      offerConversionRate: totalOfferViews > 0 ? Number(((totalCompletions / totalOfferViews) * 100).toFixed(2)) : 0,
      withdrawalRate: totalUsers > 0 ? Number(((totalWithdrawals / totalUsers) * 100).toFixed(2)) : 0,
      fraudRate: totalUsers > 0 ? Number(((totalFraudUsers / totalUsers) * 100).toFixed(2)) : 0,
      averageLtvUsd,
      revenuePerUserUsd,
    };
  }
}

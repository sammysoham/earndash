import { Module } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { UsersModule } from '../users/users.module';
import { OfferwallModule } from '../offerwall/offerwall.module';
import { WithdrawalsModule } from '../withdrawals/withdrawals.module';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [UsersModule, OfferwallModule, WithdrawalsModule, WalletModule],
  providers: [AnalyticsService],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}

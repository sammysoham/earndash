import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Referral } from './entities/referral.entity';
import { ReferralPayout } from './entities/referral-payout.entity';
import { ReferralsRepository } from './repositories/referrals.repository';
import { ReferralsService } from './referrals.service';
import { WalletModule } from '../wallet/wallet.module';
import { UsersModule } from '../users/users.module';
import { ReferralsController } from './referrals.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Referral, ReferralPayout]), WalletModule, UsersModule],
  controllers: [ReferralsController],
  providers: [ReferralsRepository, ReferralsService],
  exports: [ReferralsRepository, ReferralsService],
})
export class ReferralsModule {}

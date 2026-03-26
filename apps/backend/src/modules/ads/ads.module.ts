import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdReward } from './entities/ad-reward.entity';
import { AdsController } from './ads.controller';
import { AdsService } from './ads.service';
import { WalletModule } from '../wallet/wallet.module';
import { AuditModule } from '../audit/audit.module';
import { FraudModule } from '../fraud/fraud.module';
import { GamificationModule } from '../gamification/gamification.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AdReward]),
    WalletModule,
    AuditModule,
    FraudModule,
    GamificationModule,
  ],
  controllers: [AdsController],
  providers: [AdsService],
})
export class AdsModule {}

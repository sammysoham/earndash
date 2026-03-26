import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { QUEUE_NAMES } from '../../config/queue.constants';
import { RewardsProcessor, RewardsService } from './rewards.service';
import { OfferwallModule } from '../offerwall/offerwall.module';
import { WalletModule } from '../wallet/wallet.module';
import { AuditModule } from '../audit/audit.module';
import { RewardsController } from './rewards.controller';

@Module({
  imports: [
    OfferwallModule,
    WalletModule,
    AuditModule,
    BullModule.registerQueue({ name: QUEUE_NAMES.rewards }),
  ],
  controllers: [RewardsController],
  providers: [RewardsService, RewardsProcessor],
  exports: [RewardsService],
})
export class RewardsModule {}

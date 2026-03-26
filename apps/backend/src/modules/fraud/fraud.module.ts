import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QUEUE_NAMES } from '../../config/queue.constants';
import { OfferCompletion } from '../offerwall/entities/offer-completion.entity';
import { FraudService } from './fraud.service';
import { FraudProcessor } from './fraud.processor';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([OfferCompletion]),
    UsersModule,
    BullModule.registerQueue({ name: QUEUE_NAMES.fraud }),
  ],
  providers: [FraudService, FraudProcessor],
  exports: [FraudService],
})
export class FraudModule {}

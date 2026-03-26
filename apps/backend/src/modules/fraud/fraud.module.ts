import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OfferCompletion } from '../offerwall/entities/offer-completion.entity';
import { FraudService } from './fraud.service';
import { FraudProcessor } from './fraud.processor';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([OfferCompletion]), UsersModule],
  providers: [FraudService, FraudProcessor],
  exports: [FraudService],
})
export class FraudModule {}

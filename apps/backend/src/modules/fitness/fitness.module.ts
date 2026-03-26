import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditModule } from '../audit/audit.module';
import { UsersModule } from '../users/users.module';
import { WalletModule } from '../wallet/wallet.module';
import { FitnessController } from './fitness.controller';
import { FitnessService } from './fitness.service';
import { UserActivityStats } from './entities/user-activity.entity';
import { UserActivityRepository } from './repositories/user-activity.repository';

@Module({
  imports: [TypeOrmModule.forFeature([UserActivityStats]), UsersModule, WalletModule, AuditModule],
  controllers: [FitnessController],
  providers: [FitnessService, UserActivityRepository],
  exports: [FitnessService],
})
export class FitnessModule {}

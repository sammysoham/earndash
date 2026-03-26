import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Withdrawal } from './entities/withdrawal.entity';
import { WithdrawalsRepository } from './repositories/withdrawals.repository';
import { WithdrawalsProcessor, WithdrawalsService } from './withdrawals.service';
import { WithdrawalsController } from './withdrawals.controller';
import { WalletModule } from '../wallet/wallet.module';
import { UsersModule } from '../users/users.module';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [TypeOrmModule.forFeature([Withdrawal]), WalletModule, UsersModule, AuditModule],
  controllers: [WithdrawalsController],
  providers: [WithdrawalsRepository, WithdrawalsService, WithdrawalsProcessor],
  exports: [WithdrawalsRepository, WithdrawalsService],
})
export class WithdrawalsModule {}

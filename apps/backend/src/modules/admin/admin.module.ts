import { Module } from '@nestjs/common';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { UsersModule } from '../users/users.module';
import { AnalyticsModule } from '../analytics/analytics.module';
import { AuditModule } from '../audit/audit.module';
import { FraudModule } from '../fraud/fraud.module';
import { WithdrawalsModule } from '../withdrawals/withdrawals.module';
import { WalletModule } from '../wallet/wallet.module';

@Module({
  imports: [UsersModule, AnalyticsModule, AuditModule, FraudModule, WithdrawalsModule, WalletModule],
  controllers: [AdminController],
  providers: [AdminService, RolesGuard],
})
export class AdminModule {}

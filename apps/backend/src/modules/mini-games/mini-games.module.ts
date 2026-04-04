import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { WalletModule } from '../wallet/wallet.module';
import { MiniGamesController } from './mini-games.controller';
import { MiniGamesService } from './mini-games.service';

@Module({
  imports: [WalletModule, AuditModule],
  controllers: [MiniGamesController],
  providers: [MiniGamesService],
  exports: [MiniGamesService],
})
export class MiniGamesModule {}

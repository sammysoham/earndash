import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Wallet } from './entities/wallet.entity';
import { WalletTransaction } from './entities/wallet-transaction.entity';
import { WalletsRepository } from './repositories/wallets.repository';
import { WalletTransactionsRepository } from './repositories/wallet-transactions.repository';
import { WalletService } from './wallet.service';
import { WalletController } from './wallet.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Wallet, WalletTransaction])],
  providers: [WalletsRepository, WalletTransactionsRepository, WalletService],
  controllers: [WalletController],
  exports: [WalletsRepository, WalletTransactionsRepository, WalletService],
})
export class WalletModule {}

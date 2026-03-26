import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { coinsToUsd } from '../../common/utils/coins.util';
import { Wallet } from './entities/wallet.entity';
import { WalletTransaction } from './entities/wallet-transaction.entity';
import { WalletTransactionsRepository } from './repositories/wallet-transactions.repository';
import { WalletsRepository } from './repositories/wallets.repository';
import {
  WalletTransactionStatus,
  WalletTransactionType,
} from './entities/wallet-transaction.entity';

@Injectable()
export class WalletService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly walletsRepository: WalletsRepository,
    private readonly transactionsRepository: WalletTransactionsRepository,
  ) {}

  async ensureWallet(userId: string) {
    const existing = await this.walletsRepository.findByUserId(userId);
    if (existing) {
      return existing;
    }

    return this.walletsRepository.save(
      this.walletsRepository.create({
        userId,
        totalCoins: 0,
        pendingCoins: 0,
        withdrawableCoins: 0,
        lifetimeEarned: 0,
      }),
    );
  }

  async getWalletSummary(userId: string) {
    const wallet = await this.ensureWallet(userId);
    const transactions = await this.transactionsRepository.findRecentByUserId(userId);

    return {
      ...wallet,
      transactionHistory: transactions,
    };
  }

  async addPendingCoins(
    userId: string,
    coins: number,
    referenceType: string,
    referenceId: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const walletRepository = manager.getRepository(Wallet);
      const transactionRepository = manager.getRepository(WalletTransaction);

      const wallet =
        (await walletRepository.findOne({ where: { userId } })) ??
        walletRepository.create({
          userId,
          totalCoins: 0,
          pendingCoins: 0,
          withdrawableCoins: 0,
          lifetimeEarned: 0,
        });

      wallet.totalCoins += coins;
      wallet.pendingCoins += coins;
      wallet.lifetimeEarned += coins;
      const savedWallet = await walletRepository.save(wallet);

      await transactionRepository.save(
        transactionRepository.create({
          walletId: savedWallet.id,
          userId,
          type: WalletTransactionType.CREDIT_PENDING,
          status: WalletTransactionStatus.PENDING,
          coins,
          usdAmount: coinsToUsd(coins).toFixed(2),
          referenceType,
          referenceId,
          metadata: metadata ?? null,
        }),
      );
    });
  }

  async releasePendingCoins(
    userId: string,
    coins: number,
    referenceType: string,
    referenceId: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const walletRepository = manager.getRepository(Wallet);
      const transactionRepository = manager.getRepository(WalletTransaction);

      const wallet = await walletRepository.findOneByOrFail({ userId });
      wallet.pendingCoins = Math.max(0, wallet.pendingCoins - coins);
      wallet.withdrawableCoins += coins;
      const savedWallet = await walletRepository.save(wallet);

      await transactionRepository.save(
        transactionRepository.create({
          walletId: savedWallet.id,
          userId,
          type: WalletTransactionType.RELEASE_PENDING,
          status: WalletTransactionStatus.COMPLETED,
          coins,
          usdAmount: coinsToUsd(coins).toFixed(2),
          referenceType,
          referenceId,
          metadata: metadata ?? null,
        }),
      );
    });
  }

  async addAvailableCoins(
    userId: string,
    coins: number,
    type: WalletTransactionType,
    referenceType: string,
    referenceId: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const walletRepository = manager.getRepository(Wallet);
      const transactionRepository = manager.getRepository(WalletTransaction);

      const wallet =
        (await walletRepository.findOne({ where: { userId } })) ??
        walletRepository.create({
          userId,
          totalCoins: 0,
          pendingCoins: 0,
          withdrawableCoins: 0,
          lifetimeEarned: 0,
        });

      wallet.totalCoins += coins;
      wallet.withdrawableCoins += coins;
      wallet.lifetimeEarned += coins;
      const savedWallet = await walletRepository.save(wallet);

      await transactionRepository.save(
        transactionRepository.create({
          walletId: savedWallet.id,
          userId,
          type,
          status: WalletTransactionStatus.COMPLETED,
          coins,
          usdAmount: coinsToUsd(coins).toFixed(2),
          referenceType,
          referenceId,
          metadata: metadata ?? null,
        }),
      );
    });
  }

  async reserveWithdrawal(userId: string, coins: number, withdrawalId: string): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const walletRepository = manager.getRepository(Wallet);
      const transactionRepository = manager.getRepository(WalletTransaction);

      const wallet = await walletRepository.findOneByOrFail({ userId });
      if (wallet.withdrawableCoins < coins) {
        throw new BadRequestException('Insufficient withdrawable balance');
      }

      wallet.withdrawableCoins -= coins;
      wallet.totalCoins -= coins;
      const savedWallet = await walletRepository.save(wallet);

      await transactionRepository.save(
        transactionRepository.create({
          walletId: savedWallet.id,
          userId,
          type: WalletTransactionType.WITHDRAWAL_REQUEST,
          status: WalletTransactionStatus.PENDING,
          coins: -coins,
          usdAmount: coinsToUsd(coins).toFixed(2),
          referenceType: 'WITHDRAWAL',
          referenceId: withdrawalId,
          metadata: null,
        }),
      );
    });
  }
}

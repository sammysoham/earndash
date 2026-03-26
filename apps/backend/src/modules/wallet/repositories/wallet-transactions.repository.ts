import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WalletTransaction } from '../entities/wallet-transaction.entity';

@Injectable()
export class WalletTransactionsRepository {
  constructor(
    @InjectRepository(WalletTransaction)
    private readonly repository: Repository<WalletTransaction>,
  ) {}

  create(partial: Partial<WalletTransaction>): WalletTransaction {
    return this.repository.create(partial);
  }

  save(transaction: WalletTransaction): Promise<WalletTransaction> {
    return this.repository.save(transaction);
  }

  findRecentByUserId(userId: string): Promise<WalletTransaction[]> {
    return this.repository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  getRepository(): Repository<WalletTransaction> {
    return this.repository;
  }
}

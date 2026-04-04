import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, Repository } from 'typeorm';
import { Withdrawal, WithdrawalStatus } from '../entities/withdrawal.entity';

@Injectable()
export class WithdrawalsRepository {
  constructor(
    @InjectRepository(Withdrawal)
    private readonly repository: Repository<Withdrawal>,
  ) {}

  create(partial: Partial<Withdrawal>): Withdrawal {
    return this.repository.create(partial);
  }

  save(withdrawal: Withdrawal): Promise<Withdrawal> {
    return this.repository.save(withdrawal);
  }

  findPendingReview(): Promise<Withdrawal[]> {
    return this.repository.find({
      where: { status: WithdrawalStatus.PENDING_ADMIN_REVIEW },
      relations: { user: true },
      order: { createdAt: 'ASC' },
      take: 100,
    });
  }

  async totalRequestedToday(userId: string, start: Date, end: Date): Promise<number> {
    const rows = await this.repository.find({
      where: {
        userId,
        createdAt: Between(start, end),
      },
    });

    return rows.reduce((sum, row) => sum + row.coins, 0);
  }

  findById(withdrawalId: string): Promise<Withdrawal | null> {
    return this.repository.findOne({ where: { id: withdrawalId }, relations: { user: true } });
  }

  findByUserId(userId: string): Promise<Withdrawal[]> {
    return this.repository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  listRecent(): Promise<Withdrawal[]> {
    return this.repository.find({
      relations: { user: true },
      order: { createdAt: 'DESC' },
      take: 100,
    });
  }

  getRepository(): Repository<Withdrawal> {
    return this.repository;
  }
}

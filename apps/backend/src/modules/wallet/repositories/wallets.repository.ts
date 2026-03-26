import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Wallet } from '../entities/wallet.entity';

@Injectable()
export class WalletsRepository {
  constructor(
    @InjectRepository(Wallet)
    private readonly repository: Repository<Wallet>,
  ) {}

  create(partial: Partial<Wallet>): Wallet {
    return this.repository.create(partial);
  }

  save(wallet: Wallet): Promise<Wallet> {
    return this.repository.save(wallet);
  }

  findByUserId(userId: string): Promise<Wallet | null> {
    return this.repository.findOne({ where: { userId } });
  }

  getRepository(): Repository<Wallet> {
    return this.repository;
  }
}

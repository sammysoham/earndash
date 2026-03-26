import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Referral } from '../entities/referral.entity';
import { ReferralPayout } from '../entities/referral-payout.entity';

@Injectable()
export class ReferralsRepository {
  constructor(
    @InjectRepository(Referral)
    private readonly referralRepository: Repository<Referral>,
    @InjectRepository(ReferralPayout)
    private readonly payoutRepository: Repository<ReferralPayout>,
  ) {}

  create(partial: Partial<Referral>): Referral {
    return this.referralRepository.create(partial);
  }

  save(referral: Referral): Promise<Referral> {
    return this.referralRepository.save(referral);
  }

  findByReferredUserId(referredUserId: string): Promise<Referral | null> {
    return this.referralRepository.findOne({
      where: { referredUserId },
      relations: { referrer: true, referredUser: true },
    });
  }

  createPayout(partial: Partial<ReferralPayout>): ReferralPayout {
    return this.payoutRepository.create(partial);
  }

  savePayout(payout: ReferralPayout): Promise<ReferralPayout> {
    return this.payoutRepository.save(payout);
  }

  findPayoutBySourceCompletionId(sourceCompletionId: string): Promise<ReferralPayout | null> {
    return this.payoutRepository.findOne({ where: { sourceCompletionId } });
  }

  listTopReferrers(): Promise<Referral[]> {
    return this.referralRepository.find({
      relations: { referrer: true },
      order: { lifetimeCommissionCoins: 'DESC' },
      take: 20,
    });
  }

  listByReferrerId(referrerId: string): Promise<Referral[]> {
    return this.referralRepository.find({
      where: { referrerId },
      relations: { referredUser: { wallet: true } },
      order: { createdAt: 'DESC' },
    });
  }
}

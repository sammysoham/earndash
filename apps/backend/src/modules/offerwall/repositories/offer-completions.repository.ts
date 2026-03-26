import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThanOrEqual, Repository } from 'typeorm';
import {
  OfferCompletion,
  OfferCompletionStatus,
} from '../entities/offer-completion.entity';
import { OfferRequestLog } from '../entities/offer-request-log.entity';

@Injectable()
export class OfferCompletionsRepository {
  constructor(
    @InjectRepository(OfferCompletion)
    private readonly completionsRepository: Repository<OfferCompletion>,
    @InjectRepository(OfferRequestLog)
    private readonly requestLogsRepository: Repository<OfferRequestLog>,
  ) {}

  create(partial: Partial<OfferCompletion>): OfferCompletion {
    return this.completionsRepository.create(partial);
  }

  save(completion: OfferCompletion): Promise<OfferCompletion> {
    return this.completionsRepository.save(completion);
  }

  findByTransactionId(transactionId: string): Promise<OfferCompletion | null> {
    return this.completionsRepository.findOne({ where: { transactionId } });
  }

  findPendingReadyForRelease(now: Date): Promise<OfferCompletion[]> {
    return this.completionsRepository.find({
      where: {
        status: OfferCompletionStatus.PENDING,
        holdUntil: LessThanOrEqual(now),
      },
      take: 200,
      order: { holdUntil: 'ASC' },
    });
  }

  listRecentByUserId(userId: string): Promise<OfferCompletion[]> {
    return this.completionsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async logOfferRequest(partial: Partial<OfferRequestLog>): Promise<void> {
    await this.requestLogsRepository.save(this.requestLogsRepository.create(partial));
  }

  getCompletionRepository(): Repository<OfferCompletion> {
    return this.completionsRepository;
  }

  getRequestLogRepository(): Repository<OfferRequestLog> {
    return this.requestLogsRepository;
  }
}

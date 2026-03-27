import { InjectQueue, Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Job, Queue } from 'bullmq';
import { LessThanOrEqual } from 'typeorm';
import { JOB_NAMES, QUEUE_NAMES } from '../../config/queue.constants';
import {
  OfferCompletion,
  OfferCompletionStatus,
} from '../offerwall/entities/offer-completion.entity';
import { OfferCompletionsRepository } from '../offerwall/repositories/offer-completions.repository';
import { WalletService } from '../wallet/wallet.service';
import { AuditService } from '../audit/audit.service';
import { WalletTransactionsRepository } from '../wallet/repositories/wallet-transactions.repository';
import {
  WalletTransactionStatus,
  WalletTransactionType,
} from '../wallet/entities/wallet-transaction.entity';
import { PENDING_REWARD_HOLD_DAYS } from '../../common/utils/coins.util';

@Injectable()
export class RewardsService {
  constructor(
    private readonly offerCompletionsRepository: OfferCompletionsRepository,
    private readonly walletTransactionsRepository: WalletTransactionsRepository,
    private readonly walletService: WalletService,
    private readonly auditService: AuditService,
    @InjectQueue(QUEUE_NAMES.rewards)
    private readonly rewardsQueue: Queue,
  ) {}

  @Cron(CronExpression.EVERY_HOUR)
  async checkPendingRewards(): Promise<void> {
    const threshold = new Date(Date.now() - PENDING_REWARD_HOLD_DAYS * 24 * 60 * 60 * 1000);
    const completions = await this.walletTransactionsRepository.getRepository().find({
      where: {
        type: WalletTransactionType.CREDIT_PENDING,
        status: WalletTransactionStatus.PENDING,
        createdAt: LessThanOrEqual(threshold),
      },
      order: { createdAt: 'ASC' },
      take: 500,
    });

    await Promise.all(
      completions.map((transaction) =>
        this.rewardsQueue.add(
          JOB_NAMES.releasePendingReward,
          { pendingTransactionId: transaction.id },
          { removeOnComplete: 1000 },
        ),
      ),
    );
  }

  async releasePendingReward(pendingTransactionId: string): Promise<void> {
    const releasedTransaction = await this.walletService.releasePendingTransaction(pendingTransactionId);
    if (!releasedTransaction) {
      return;
    }

    if (releasedTransaction.referenceType === 'OFFER_COMPLETION') {
      const completionRepository = this.offerCompletionsRepository.getCompletionRepository();
      const completion = await completionRepository.findOne({
        where: { id: releasedTransaction.referenceId },
      });
      if (completion && completion.status === OfferCompletionStatus.PENDING) {
        completion.status = OfferCompletionStatus.RELEASED;
        completion.releasedAt = new Date();
        await completionRepository.save(completion);
      }
    }

    await this.auditService.log(null, 'PENDING_REWARD_RELEASED', releasedTransaction.referenceType, releasedTransaction.referenceId, {
      userId: releasedTransaction.userId,
      payoutCoins: releasedTransaction.coins,
      sourceTransactionId: releasedTransaction.id,
    });
  }

  async settleReadyRewardsForUser(userId: string): Promise<number> {
    const threshold = new Date(Date.now() - PENDING_REWARD_HOLD_DAYS * 24 * 60 * 60 * 1000);
    const releasable = await this.walletTransactionsRepository.getRepository().find({
      where: {
        userId,
        type: WalletTransactionType.CREDIT_PENDING,
        status: WalletTransactionStatus.PENDING,
        createdAt: LessThanOrEqual(threshold),
      },
      order: { createdAt: 'ASC' },
    });

    for (const pendingTransaction of releasable) {
      await this.releasePendingReward(pendingTransaction.id);
    }
    return releasable.length;
  }
}

@Processor(QUEUE_NAMES.rewards)
export class RewardsProcessor extends WorkerHost {
  constructor(private readonly rewardsService: RewardsService) {
    super();
  }

  async process(job: Job<{ pendingTransactionId: string }>): Promise<void> {
    if (job.name === JOB_NAMES.releasePendingReward) {
      await this.rewardsService.releasePendingReward(job.data.pendingTransactionId);
    }
  }
}

import { InjectQueue, Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Job, Queue } from 'bullmq';
import { JOB_NAMES, QUEUE_NAMES } from '../../config/queue.constants';
import {
  OfferCompletion,
  OfferCompletionStatus,
} from '../offerwall/entities/offer-completion.entity';
import { OfferCompletionsRepository } from '../offerwall/repositories/offer-completions.repository';
import { WalletService } from '../wallet/wallet.service';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class RewardsService {
  constructor(
    private readonly offerCompletionsRepository: OfferCompletionsRepository,
    private readonly walletService: WalletService,
    private readonly auditService: AuditService,
    @InjectQueue(QUEUE_NAMES.rewards)
    private readonly rewardsQueue: Queue,
  ) {}

  @Cron(CronExpression.EVERY_HOUR)
  async checkPendingRewards(): Promise<void> {
    const completions = await this.offerCompletionsRepository.findPendingReadyForRelease(new Date());
    await Promise.all(
      completions.map((completion) =>
        this.rewardsQueue.add(
          JOB_NAMES.releasePendingReward,
          { completionId: completion.id },
          { removeOnComplete: 1000 },
        ),
      ),
    );
  }

  async releasePendingReward(completionId: string): Promise<void> {
    const completionRepository = this.offerCompletionsRepository.getCompletionRepository();
    const completion = await completionRepository.findOne({ where: { id: completionId } });
    if (!completion || completion.status !== OfferCompletionStatus.PENDING) {
      return;
    }

    if (completion.holdUntil.getTime() > Date.now()) {
      return;
    }

    await this.walletService.releasePendingCoins(
      completion.userId,
      completion.payoutCoins,
      'OFFER_COMPLETION_RELEASE',
      completion.id,
      { provider: completion.provider },
    );

    completion.status = OfferCompletionStatus.RELEASED;
    completion.releasedAt = new Date();
    await completionRepository.save(completion);

    await this.auditService.log(null, 'PENDING_REWARD_RELEASED', 'OFFER_COMPLETION', completion.id, {
      userId: completion.userId,
      payoutCoins: completion.payoutCoins,
    });
  }

  async settleReadyRewardsForUser(userId: string): Promise<number> {
    const completions = await this.offerCompletionsRepository
      .getCompletionRepository()
      .find({
        where: {
          userId,
          status: OfferCompletionStatus.PENDING,
        },
      });

    const releasable = completions.filter((completion) => completion.holdUntil.getTime() <= Date.now());
    for (const completion of releasable) {
      await this.releasePendingReward(completion.id);
    }
    return releasable.length;
  }
}

@Processor(QUEUE_NAMES.rewards)
export class RewardsProcessor extends WorkerHost {
  constructor(private readonly rewardsService: RewardsService) {
    super();
  }

  async process(job: Job<{ completionId: string }>): Promise<void> {
    if (job.name === JOB_NAMES.releasePendingReward) {
      await this.rewardsService.releasePendingReward(job.data.completionId);
    }
  }
}

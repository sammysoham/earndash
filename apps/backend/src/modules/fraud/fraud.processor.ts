import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { JOB_NAMES, QUEUE_NAMES } from '../../config/queue.constants';
import { FraudService } from './fraud.service';

@Processor(QUEUE_NAMES.fraud)
export class FraudProcessor extends WorkerHost {
  constructor(private readonly fraudService: FraudService) {
    super();
  }

  async process(job: Job<{ userId: string }>): Promise<void> {
    if (job.name === JOB_NAMES.analyzeUser) {
      await this.fraudService.analyzeUser(job.data.userId);
    }
  }
}

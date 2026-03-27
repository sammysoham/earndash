import { InjectQueue, Processor, WorkerHost } from '@nestjs/bullmq';
import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Job, Queue } from 'bullmq';
import { JOB_NAMES, QUEUE_NAMES } from '../../config/queue.constants';
import {
  coinsToUsd,
  MIN_WITHDRAWAL_COINS,
  NEW_USER_DAILY_WITHDRAWAL_CAP_COINS,
  usdToCoins,
} from '../../common/utils/coins.util';
import { WithdrawRequestDto } from '../wallet/dto/withdraw-request.dto';
import {
  Withdrawal,
  WithdrawalMethod,
  WithdrawalStatus,
} from './entities/withdrawal.entity';
import { WithdrawalsRepository } from './repositories/withdrawals.repository';
import { WalletService } from '../wallet/wallet.service';
import { UsersService } from '../users/users.service';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class WithdrawalsService {
  constructor(
    private readonly withdrawalsRepository: WithdrawalsRepository,
    private readonly walletService: WalletService,
    private readonly usersService: UsersService,
    private readonly auditService: AuditService,
    @InjectQueue(QUEUE_NAMES.withdrawals)
    private readonly withdrawalsQueue: Queue,
  ) {}

  async requestWithdrawal(userId: string, dto: WithdrawRequestDto): Promise<Withdrawal> {
    if (dto.coins < MIN_WITHDRAWAL_COINS) {
      throw new BadRequestException('Minimum withdrawal is $5');
    }

    const user = await this.usersService.getByIdOrFail(userId);
    if (user.withdrawalsDisabled) {
      throw new ForbiddenException('Withdrawals are disabled for this account');
    }

    const wallet = await this.walletService.getWalletSummary(userId);
    if (wallet.withdrawableCoins < dto.coins) {
      throw new BadRequestException('Not enough withdrawable coins');
    }

    const start = new Date();
    start.setUTCHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setUTCHours(23, 59, 59, 999);
    const todayRequested = await this.withdrawalsRepository.totalRequestedToday(userId, start, end);

    const isNewUser = user.createdAt.getTime() > Date.now() - 14 * 24 * 60 * 60 * 1000;
    if (isNewUser && todayRequested + dto.coins > NEW_USER_DAILY_WITHDRAWAL_CAP_COINS) {
      throw new BadRequestException('New user daily withdrawal limit is $20');
    }

    const withdrawal = await this.withdrawalsRepository.save(
      this.withdrawalsRepository.create({
        userId,
        method: dto.method,
        status: WithdrawalStatus.PENDING_ADMIN_REVIEW,
        coins: dto.coins,
        usdAmount: coinsToUsd(dto.coins).toFixed(2),
        destination: dto.destination,
        approvedBy: null,
        processedAt: null,
        metadata: null,
      }),
    );

    await this.walletService.reserveWithdrawal(userId, dto.coins, withdrawal.id);
    await this.auditService.log(userId, 'WITHDRAWAL_REQUESTED', 'WITHDRAWAL', withdrawal.id, {
      method: dto.method,
      coins: dto.coins,
    });

    return withdrawal;
  }

  pendingReview() {
    return this.withdrawalsRepository.findPendingReview();
  }

  recent() {
    return this.withdrawalsRepository.listRecent();
  }

  async reviewWithdrawal(
    actorId: string,
    withdrawalId: string,
    approve: boolean,
    note?: string,
  ): Promise<Withdrawal> {
    const withdrawal = await this.withdrawalsRepository.findById(withdrawalId);
    if (!withdrawal) {
      throw new NotFoundException('Withdrawal not found');
    }

    withdrawal.approvedBy = actorId;
    withdrawal.metadata = { ...(withdrawal.metadata ?? {}), note: note ?? null };

    if (approve) {
      withdrawal.status = WithdrawalStatus.APPROVED;
      await this.withdrawalsRepository.save(withdrawal);
    } else {
      withdrawal.status = WithdrawalStatus.REJECTED;
      await this.withdrawalsRepository.save(withdrawal);
    }

    await this.auditService.log(actorId, 'WITHDRAWAL_REVIEWED', 'WITHDRAWAL', withdrawal.id, {
      approve,
      note: note ?? null,
    });

    return withdrawal;
  }

  async setStatus(
    actorId: string,
    withdrawalId: string,
    status: WithdrawalStatus,
    note?: string,
  ): Promise<Withdrawal> {
    const withdrawal = await this.withdrawalsRepository.findById(withdrawalId);
    if (!withdrawal) {
      throw new NotFoundException('Withdrawal not found');
    }

    withdrawal.approvedBy = actorId;
    withdrawal.status = status;
    withdrawal.metadata = { ...(withdrawal.metadata ?? {}), note: note ?? null };
    if (status === WithdrawalStatus.PAID) {
      withdrawal.processedAt = new Date();
    }

    await this.withdrawalsRepository.save(withdrawal);
    await this.auditService.log(actorId, 'WITHDRAWAL_STATUS_UPDATED', 'WITHDRAWAL', withdrawal.id, {
      status,
      note: note ?? null,
    });
    return withdrawal;
  }

  async processWithdrawal(withdrawalId: string): Promise<void> {
    const withdrawal = await this.withdrawalsRepository.findById(withdrawalId);
    if (!withdrawal || withdrawal.status !== WithdrawalStatus.APPROVED) {
      return;
    }

    withdrawal.status = WithdrawalStatus.QUEUED;
    await this.withdrawalsRepository.save(withdrawal);

    withdrawal.status = WithdrawalStatus.PAID;
    withdrawal.processedAt = new Date();
    await this.withdrawalsRepository.save(withdrawal);

    await this.auditService.log(
      withdrawal.approvedBy,
      'WITHDRAWAL_PAID',
      'WITHDRAWAL',
      withdrawal.id,
      { method: withdrawal.method },
    );
  }
}

@Processor(QUEUE_NAMES.withdrawals)
export class WithdrawalsProcessor extends WorkerHost {
  constructor(private readonly withdrawalsService: WithdrawalsService) {
    super();
  }

  async process(job: Job<{ withdrawalId: string }>): Promise<void> {
    if (job.name === JOB_NAMES.processWithdrawal) {
      await this.withdrawalsService.processWithdrawal(job.data.withdrawalId);
    }
  }
}

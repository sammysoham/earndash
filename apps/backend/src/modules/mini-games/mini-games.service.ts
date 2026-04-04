import { BadRequestException, Injectable } from '@nestjs/common';
import { MoreThanOrEqual } from 'typeorm';
import { PENDING_REWARD_HOLD_DAYS } from '../../common/utils/coins.util';
import { AuditService } from '../audit/audit.service';
import { WalletService } from '../wallet/wallet.service';
import { WalletTransactionsRepository } from '../wallet/repositories/wallet-transactions.repository';
import { ClaimMiniGameDto, MiniGameId } from './dto/claim-mini-game.dto';

const MINI_GAME_REFERENCE_TYPE = 'MINI_GAME';
const MINI_GAME_DAILY_CAP = 12;

const MINI_GAME_CONFIG: Record<
  MiniGameId,
  { scorePerCoin: number; maxCoins: number; cooldownSeconds: number; title: string }
> = {
  CARROM: {
    title: 'Carrom Flick',
    scorePerCoin: 35,
    maxCoins: 3,
    cooldownSeconds: 30,
  },
  POOL: {
    title: 'Pocket Pool',
    scorePerCoin: 28,
    maxCoins: 3,
    cooldownSeconds: 30,
  },
  TABLE_TENNIS: {
    title: 'Table Tennis Rally',
    scorePerCoin: 8,
    maxCoins: 3,
    cooldownSeconds: 30,
  },
};

@Injectable()
export class MiniGamesService {
  constructor(
    private readonly walletService: WalletService,
    private readonly walletTransactionsRepository: WalletTransactionsRepository,
    private readonly auditService: AuditService,
  ) {}

  async claimReward(userId: string, dto: ClaimMiniGameDto) {
    const config = MINI_GAME_CONFIG[dto.gameId];
    if (!config) {
      throw new BadRequestException('Unknown mini game');
    }

    if (dto.score <= 0) {
      throw new BadRequestException('Finish a game with a score before claiming coins');
    }

    const repository = this.walletTransactionsRepository.getRepository();
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const todaysTransactions = await repository.find({
      where: {
        userId,
        referenceType: MINI_GAME_REFERENCE_TYPE,
        coins: MoreThanOrEqual(1),
        createdAt: MoreThanOrEqual(startOfDay),
      },
    });

    const dailyAwardedCoins = todaysTransactions.reduce((sum, item) => sum + Math.max(0, item.coins), 0);
    if (dailyAwardedCoins >= MINI_GAME_DAILY_CAP) {
      throw new BadRequestException('Mini game daily cap reached. Come back tomorrow for more rounds.');
    }

    const lastGameTransaction = await repository
      .createQueryBuilder('transaction')
      .where('transaction.userId = :userId', { userId })
      .andWhere('transaction.referenceType = :referenceType', { referenceType: MINI_GAME_REFERENCE_TYPE })
      .andWhere('transaction.referenceId LIKE :gamePrefix', { gamePrefix: `${dto.gameId}:%` })
      .orderBy('transaction.createdAt', 'DESC')
      .getOne();

    if (lastGameTransaction) {
      const nextEligibleAt = new Date(lastGameTransaction.createdAt.getTime() + config.cooldownSeconds * 1000);
      if (nextEligibleAt > new Date()) {
        const waitSeconds = Math.ceil((nextEligibleAt.getTime() - Date.now()) / 1000);
        throw new BadRequestException(`Please wait ${waitSeconds}s before claiming this mini game again.`);
      }
    }

    const rawCoins = Math.max(1, Math.ceil(dto.score / config.scorePerCoin));
    const coinsAwarded = Math.min(config.maxCoins, MINI_GAME_DAILY_CAP - dailyAwardedCoins, rawCoins);

    if (coinsAwarded <= 0) {
      throw new BadRequestException('No mini game reward is available right now.');
    }

    const referenceId = `${dto.gameId}:${Date.now()}`;
    await this.walletService.addPendingCoins(userId, coinsAwarded, MINI_GAME_REFERENCE_TYPE, referenceId, {
      gameId: dto.gameId,
      gameTitle: config.title,
      score: dto.score,
      cooldownSeconds: config.cooldownSeconds,
    });
    await this.auditService.log(userId, 'MINI_GAME_REWARD_CLAIMED', 'MINI_GAME', referenceId, {
      gameId: dto.gameId,
      gameTitle: config.title,
      score: dto.score,
      coinsAwarded,
      dailyAwardedCoins: dailyAwardedCoins + coinsAwarded,
      dailyCap: MINI_GAME_DAILY_CAP,
    });

    return {
      gameId: dto.gameId,
      coinsAwarded,
      dailyAwardedCoins: dailyAwardedCoins + coinsAwarded,
      dailyCap: MINI_GAME_DAILY_CAP,
      pendingForDays: PENDING_REWARD_HOLD_DAYS,
    };
  }
}

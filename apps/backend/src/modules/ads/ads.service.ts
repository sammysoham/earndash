import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfirmAdRewardDto } from './dto/confirm-ad-reward.dto';
import { AdReward } from './entities/ad-reward.entity';
import { WalletService } from '../wallet/wallet.service';
import { AuditService } from '../audit/audit.service';
import { FraudService } from '../fraud/fraud.service';
import { GamificationService } from '../gamification/gamification.service';

@Injectable()
export class AdsService {
  constructor(
    @InjectRepository(AdReward)
    private readonly adRewardsRepository: Repository<AdReward>,
    private readonly walletService: WalletService,
    private readonly auditService: AuditService,
    private readonly fraudService: FraudService,
    private readonly gamificationService: GamificationService,
  ) {}

  async confirmReward(userId: string, dto: ConfirmAdRewardDto) {
    if (dto.coins < 5 || dto.coins > 20) {
      throw new BadRequestException('Ad reward amount is outside the allowed range');
    }

    const existing = await this.adRewardsRepository.findOne({ where: { sessionId: dto.sessionId } });
    if (existing) {
      throw new BadRequestException('Ad reward session already processed');
    }

    const reward = await this.adRewardsRepository.save(
      this.adRewardsRepository.create({
        userId,
        adUnitId: dto.adUnitId,
        sessionId: dto.sessionId,
        coins: dto.coins,
        verified: true,
        metadata: { placement: dto.placement ?? null },
      }),
    );

    await this.walletService.addPendingCoins(
      userId,
      dto.coins,
      'AD_REWARD',
      reward.id,
      { adUnitId: dto.adUnitId, placement: dto.placement ?? null },
    );
    await this.gamificationService.onAdReward(userId);
    await this.auditService.log(userId, 'AD_REWARD_CONFIRMED', 'AD_REWARD', reward.id, {
      coins: dto.coins,
      adUnitId: dto.adUnitId,
    });
    await this.fraudService.enqueueUserAnalysis(userId);

    return reward;
  }
}

import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'crypto';
import { GetOffersDto } from './dto/get-offers.dto';
import { OfferwallPostbackDto } from './dto/postback.dto';
import {
  OfferCompletion,
  OfferCompletionStatus,
  OfferProvider,
} from './entities/offer-completion.entity';
import { OfferCompletionsRepository } from './repositories/offer-completions.repository';
import {
  OfferDto,
  OfferFetchContext,
  OfferwallProviderAdapter,
} from './providers/offer-provider.interface';
import { UsersService } from '../users/users.service';
import { WalletService } from '../wallet/wallet.service';
import { FraudService } from '../fraud/fraud.service';
import { ReferralsService } from '../referrals/referrals.service';
import { AuditService } from '../audit/audit.service';
import { GamificationService } from '../gamification/gamification.service';
import { PENDING_REWARD_HOLD_DAYS } from '../../common/utils/coins.util';

@Injectable()
export class OfferwallService {
  constructor(
    private readonly usersService: UsersService,
    private readonly walletService: WalletService,
    private readonly fraudService: FraudService,
    private readonly referralsService: ReferralsService,
    private readonly auditService: AuditService,
    private readonly gamificationService: GamificationService,
    private readonly offerCompletionsRepository: OfferCompletionsRepository,
    private readonly configService: ConfigService,
    @Inject('OFFERWALL_PROVIDERS')
    private readonly providers: OfferwallProviderAdapter[],
  ) {}

  async getOffers(dto: GetOffersDto, ipAddress: string): Promise<OfferDto[]> {
    const user = await this.usersService.getByIdOrFail(dto.userId);
    const context: OfferFetchContext = {
      userId: user.id,
      country: dto.country,
      device: dto.device,
      ipAddress,
      gaid: dto.gaid,
      idfa: dto.idfa,
    };

    const offerGroups = await Promise.all(
      this.providers.map(async (provider) => {
        await this.offerCompletionsRepository.logOfferRequest({
          userId: user.id,
          provider: provider.provider,
          countryCode: dto.country,
          deviceType: dto.device,
          ipAddress,
        });
        return provider.fetchOffers(context);
      }),
    );

    return offerGroups.flat().sort((a, b) => b.payoutCoins - a.payoutCoins);
  }

  async handlePostback(
    dto: OfferwallPostbackDto,
    signature: string | undefined,
    ipAddress: string,
  ): Promise<{ success: boolean; completionId?: string }> {
    this.verifySignature(dto.provider, dto, signature);

    return this.processCompletion(dto, ipAddress);
  }

  async handleMyLeadPostback(
    payload: Record<string, string | number | undefined>,
    ipAddress: string,
  ): Promise<{ success: boolean; completionId?: string }> {
    const configuredSecret = this.configService.get<string>('webhooks.mylead') ?? '';
    if (configuredSecret) {
      const incomingSecret = this.firstString(payload.secret, payload.token, payload.auth);
      if (!incomingSecret || incomingSecret !== configuredSecret) {
        throw new ForbiddenException('Invalid MyLead postback secret');
      }
    }

    const dto: OfferwallPostbackDto = {
      provider: OfferProvider.MYLEAD,
      user_id: this.requiredString(
        payload.player_id,
        payload.user_id,
        payload.userid,
        payload.subid,
      ),
      payout: this.requiredPositiveInt(
        payload.payout,
        payload.payout_decimal,
        payload.amount,
        payload.reward,
      ),
      transaction_id: this.requiredString(
        payload.transaction_id,
        payload.transactionId,
        payload.tid,
        payload.id,
      ),
      offer_id:
        this.firstString(
          payload.offer_id,
          payload.offerId,
          payload.campaign_id,
          payload.campaignId,
          payload.ml_offer_id,
        ) ?? 'mylead-offer',
      status:
        this.firstString(payload.status, payload.event, payload.conversion_status) ??
        'approved',
    };

    return this.processCompletion(dto, ipAddress);
  }

  private async processCompletion(
    dto: OfferwallPostbackDto,
    ipAddress: string,
  ): Promise<{ success: boolean; completionId?: string }> {

    const existing = await this.offerCompletionsRepository.findByTransactionId(dto.transaction_id);
    if (existing) {
      return { success: true, completionId: existing.id };
    }

    const user = await this.usersService.getByIdOrFail(dto.user_id);
    const isSuccessful = ['approved', 'completed', 'complete'].includes(dto.status.toLowerCase());
    const holdUntil = new Date(Date.now() + PENDING_REWARD_HOLD_DAYS * 24 * 60 * 60 * 1000);

    const completion = await this.offerCompletionsRepository.save(
      this.offerCompletionsRepository.create({
        userId: user.id,
        provider: dto.provider,
        offerId: dto.offer_id,
        transactionId: dto.transaction_id,
        payoutCoins: dto.payout,
        status: isSuccessful ? OfferCompletionStatus.PENDING : OfferCompletionStatus.REJECTED,
        holdUntil,
        releasedAt: null,
        deviceType: user.deviceFingerprint ? 'known' : 'unknown',
        ipAddress,
        metadata: { rawStatus: dto.status },
      }),
    );

    await this.auditService.log(null, 'OFFER_POSTBACK', 'OFFER_COMPLETION', completion.id, {
      provider: dto.provider,
      transactionId: dto.transaction_id,
      payout: dto.payout,
      status: dto.status,
    });

    if (!isSuccessful) {
      return { success: true, completionId: completion.id };
    }

    await this.walletService.addPendingCoins(user.id, dto.payout, 'OFFER_COMPLETION', completion.id, {
      provider: dto.provider,
      offerId: dto.offer_id,
      transactionId: dto.transaction_id,
    });
    await this.referralsService.creditCommissionForOffer(completion);
    await this.gamificationService.onOfferCompleted(user.id, dto.payout);
    await this.fraudService.enqueueUserAnalysis(user.id);

    return { success: true, completionId: completion.id };
  }

  private firstString(
    ...values: Array<string | number | undefined>
  ): string | undefined {
    for (const value of values) {
      if (value === undefined || value === null) {
        continue;
      }

      const normalized = String(value).trim();
      if (normalized) {
        return normalized;
      }
    }

    return undefined;
  }

  private requiredString(
    ...values: Array<string | number | undefined>
  ): string {
    const resolved = this.firstString(...values);
    if (!resolved) {
      throw new BadRequestException('Missing required MyLead postback field');
    }

    return resolved;
  }

  private requiredPositiveInt(
    ...values: Array<string | number | undefined>
  ): number {
    for (const value of values) {
      if (value === undefined || value === null || value === '') {
        continue;
      }

      const numeric = Number(value);
      if (Number.isFinite(numeric) && numeric > 0) {
        return Math.round(numeric);
      }
    }

    throw new BadRequestException('Missing payout value in MyLead postback');
  }

  private verifySignature(
    provider: OfferProvider,
    dto: OfferwallPostbackDto,
    signature?: string,
  ): void {
    const secret = this.getWebhookSecret(provider);
    if (!secret) {
      return;
    }

    if (!signature) {
      throw new ForbiddenException('Missing webhook signature');
    }

    const payload = `${dto.user_id}:${dto.transaction_id}:${dto.payout}:${dto.offer_id}:${dto.status}`;
    const expected = createHmac('sha256', secret).update(payload).digest('hex');
    if (expected !== signature) {
      throw new BadRequestException('Invalid webhook signature');
    }
  }

  private getWebhookSecret(provider: OfferProvider): string {
    switch (provider) {
      case OfferProvider.ADGEM:
        return this.configService.get<string>('webhooks.adgem') ?? '';
      case OfferProvider.AYET:
        return this.configService.get<string>('webhooks.ayet') ?? '';
      case OfferProvider.LOOTABLY:
        return this.configService.get<string>('webhooks.lootably') ?? '';
      case OfferProvider.OFFERTORO:
        return this.configService.get<string>('webhooks.offertoro') ?? '';
      case OfferProvider.MYLEAD:
        return this.configService.get<string>('webhooks.mylead') ?? '';
      default:
        return '';
    }
  }
}

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'crypto';
import { OfferProvider } from '../entities/offer-completion.entity';
import {
  OfferDto,
  OfferFetchContext,
  OfferwallProviderAdapter,
} from './offer-provider.interface';

@Injectable()
export class MyLeadProvider implements OfferwallProviderAdapter {
  readonly provider = OfferProvider.MYLEAD;

  constructor(private readonly configService: ConfigService) {}

  async fetchOffers(context: OfferFetchContext): Promise<OfferDto[]> {
    const offerwallUrl = this.configService.get<string>('offerwall.mylead.offerwallUrl') ?? '';
    if (!offerwallUrl) {
      return [];
    }

    const launchUrl = new URL(offerwallUrl);
    const clickId = randomUUID();

    // MyLead supports player_id for user identity and ml_sub* fields for tracking.
    launchUrl.searchParams.set('player_id', context.userId);
    launchUrl.searchParams.set('ml_sub1', clickId);
    launchUrl.searchParams.set('ml_sub2', context.country);
    launchUrl.searchParams.set('ml_sub3', context.device);
    launchUrl.searchParams.set('ml_sub4', context.ipAddress);
    if (context.gaid) {
      launchUrl.searchParams.set('gaid', context.gaid);
    }
    if (context.idfa) {
      launchUrl.searchParams.set('idfa', context.idfa);
    }

    return [
      {
        provider: this.provider,
        externalOfferId: `mylead-launch-${context.device}-${context.country.toLowerCase()}`,
        title:
          this.configService.get<string>('offerwall.mylead.defaultTitle') ??
          'MyLead Offerwall',
        description:
          this.configService.get<string>('offerwall.mylead.defaultDescription') ??
          'Open the MyLead offerwall to browse surveys, installs, and payout tasks.',
        payoutCoins:
          this.configService.get<number>('offerwall.mylead.launchPayoutCoins') ??
          1200,
        ctaUrl: launchUrl.toString(),
        iconUrl:
          this.configService.get<string>('offerwall.mylead.defaultIconUrl') ??
          'https://images.unsplash.com/photo-1556740749-887f6717d7e4?w=200',
        estimatedMinutes:
          this.configService.get<number>('offerwall.mylead.defaultEstimatedMinutes') ??
          12,
      },
    ];
  }
}

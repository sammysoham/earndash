import { Injectable } from '@nestjs/common';
import { OfferProvider } from '../entities/offer-completion.entity';
import {
  OfferDto,
  OfferFetchContext,
  OfferwallProviderAdapter,
} from './offer-provider.interface';

@Injectable()
export class OfferToroProvider implements OfferwallProviderAdapter {
  readonly provider = OfferProvider.OFFERTORO;

  async fetchOffers(context: OfferFetchContext): Promise<OfferDto[]> {
    return [
      {
        provider: this.provider,
        externalOfferId: `offertoro-${context.device}-shop`,
        title: 'Install and shop with Daily Deals',
        description: 'Complete the first purchase milestone to unlock coins.',
        payoutCoins: 2600,
        ctaUrl: 'https://example.com/offers/offertoro/daily-deals',
        iconUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=200',
        estimatedMinutes: 30,
      },
    ];
  }
}

import { Injectable } from '@nestjs/common';
import { OfferProvider } from '../entities/offer-completion.entity';
import {
  OfferDto,
  OfferFetchContext,
  OfferwallProviderAdapter,
} from './offer-provider.interface';

@Injectable()
export class AdGemProvider implements OfferwallProviderAdapter {
  readonly provider = OfferProvider.ADGEM;

  async fetchOffers(context: OfferFetchContext): Promise<OfferDto[]> {
    return [
      {
        provider: this.provider,
        externalOfferId: `adgem-${context.country.toLowerCase()}-1`,
        title: 'Play Merge Empire',
        description: 'Reach level 12 to earn a starter payout.',
        payoutCoins: 1800,
        ctaUrl: 'https://example.com/offers/adgem/merge-empire',
        iconUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=200',
        estimatedMinutes: 20,
      },
    ];
  }
}

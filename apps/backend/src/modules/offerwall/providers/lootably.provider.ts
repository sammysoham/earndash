import { Injectable } from '@nestjs/common';
import { OfferProvider } from '../entities/offer-completion.entity';
import {
  OfferDto,
  OfferFetchContext,
  OfferwallProviderAdapter,
} from './offer-provider.interface';

@Injectable()
export class LootablyProvider implements OfferwallProviderAdapter {
  readonly provider = OfferProvider.LOOTABLY;

  async fetchOffers(context: OfferFetchContext): Promise<OfferDto[]> {
    return [
      {
        provider: this.provider,
        externalOfferId: `lootably-${context.country.toLowerCase()}-stream`,
        title: 'Stream a sponsored creator clip',
        description: 'Watch the full featured stream for instant credit.',
        payoutCoins: 450,
        ctaUrl: 'https://example.com/offers/lootably/stream',
        iconUrl: 'https://images.unsplash.com/photo-1542751110-97427bbecf20?w=200',
        estimatedMinutes: 6,
      },
    ];
  }
}

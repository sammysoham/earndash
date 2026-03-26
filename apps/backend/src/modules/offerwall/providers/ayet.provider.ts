import { Injectable } from '@nestjs/common';
import { OfferProvider } from '../entities/offer-completion.entity';
import {
  OfferDto,
  OfferFetchContext,
  OfferwallProviderAdapter,
} from './offer-provider.interface';

@Injectable()
export class AyetProvider implements OfferwallProviderAdapter {
  readonly provider = OfferProvider.AYET;

  async fetchOffers(context: OfferFetchContext): Promise<OfferDto[]> {
    return [
      {
        provider: this.provider,
        externalOfferId: `ayet-${context.device}-survey`,
        title: 'Complete a premium survey',
        description: 'Finish a verified survey session to earn coins.',
        payoutCoins: 950,
        ctaUrl: 'https://example.com/offers/ayet/survey',
        iconUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=200',
        estimatedMinutes: 12,
      },
    ];
  }
}

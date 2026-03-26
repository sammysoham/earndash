import { OfferProvider } from '../entities/offer-completion.entity';

export interface OfferFetchContext {
  userId: string;
  country: string;
  device: string;
  ipAddress: string;
  gaid?: string;
  idfa?: string;
}

export interface OfferDto {
  provider: OfferProvider;
  externalOfferId: string;
  title: string;
  description: string;
  payoutCoins: number;
  ctaUrl: string;
  iconUrl: string;
  estimatedMinutes: number;
}

export interface OfferwallProviderAdapter {
  readonly provider: OfferProvider;
  fetchOffers(context: OfferFetchContext): Promise<OfferDto[]>;
}

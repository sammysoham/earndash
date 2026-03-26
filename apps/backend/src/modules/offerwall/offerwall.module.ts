import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OfferCompletion } from './entities/offer-completion.entity';
import { OfferRequestLog } from './entities/offer-request-log.entity';
import { OfferwallController } from './offerwall.controller';
import { OfferwallService } from './offerwall.service';
import { OfferCompletionsRepository } from './repositories/offer-completions.repository';
import { AdGemProvider } from './providers/adgem.provider';
import { AyetProvider } from './providers/ayet.provider';
import { LootablyProvider } from './providers/lootably.provider';
import { OfferToroProvider } from './providers/offertoro.provider';
import { MyLeadProvider } from './providers/mylead.provider';
import { UsersModule } from '../users/users.module';
import { WalletModule } from '../wallet/wallet.module';
import { ReferralsModule } from '../referrals/referrals.module';
import { AuditModule } from '../audit/audit.module';
import { GamificationModule } from '../gamification/gamification.module';
import { FraudModule } from '../fraud/fraud.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([OfferCompletion, OfferRequestLog]),
    UsersModule,
    WalletModule,
    ReferralsModule,
    AuditModule,
    GamificationModule,
    FraudModule,
  ],
  controllers: [OfferwallController],
  providers: [
    OfferCompletionsRepository,
    AdGemProvider,
    AyetProvider,
    LootablyProvider,
    OfferToroProvider,
    MyLeadProvider,
    {
      provide: 'OFFERWALL_PROVIDERS',
      useFactory: (
        adGem: AdGemProvider,
        ayet: AyetProvider,
        lootably: LootablyProvider,
        offerToro: OfferToroProvider,
        myLead: MyLeadProvider,
      ) => [adGem, ayet, lootably, offerToro, myLead],
      inject: [AdGemProvider, AyetProvider, LootablyProvider, OfferToroProvider, MyLeadProvider],
    },
    OfferwallService,
  ],
  exports: [OfferCompletionsRepository, OfferwallService],
})
export class OfferwallModule {}

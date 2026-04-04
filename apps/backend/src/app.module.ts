import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bullmq';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule } from '@nestjs/throttler';
import appConfig from './config/app.config';
import { QUEUE_NAMES } from './config/queue.constants';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { WalletModule } from './modules/wallet/wallet.module';
import { OfferwallModule } from './modules/offerwall/offerwall.module';
import { AdsModule } from './modules/ads/ads.module';
import { RewardsModule } from './modules/rewards/rewards.module';
import { WithdrawalsModule } from './modules/withdrawals/withdrawals.module';
import { FraudModule } from './modules/fraud/fraud.module';
import { ReferralsModule } from './modules/referrals/referrals.module';
import { GamificationModule } from './modules/gamification/gamification.module';
import { AnalyticsModule } from './modules/analytics/analytics.module';
import { AdminModule } from './modules/admin/admin.module';
import { AuditModule } from './modules/audit/audit.module';
import { FitnessModule } from './modules/fitness/fitness.module';
import { MiniGamesModule } from './modules/mini-games/mini-games.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [appConfig] }),
    ScheduleModule.forRoot(),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('postgres.host'),
        port: configService.get<number>('postgres.port'),
        database: configService.get<string>('postgres.database'),
        username: configService.get<string>('postgres.username'),
        password: configService.get<string>('postgres.password'),
        autoLoadEntities: true,
        synchronize: configService.get<boolean>('postgres.synchronize'),
      }),
    }),
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        connection: {
          host: configService.get<string>('redis.host'),
          port: configService.get<number>('redis.port'),
        },
      }),
    }),
    BullModule.registerQueue(
      { name: QUEUE_NAMES.rewards },
      { name: QUEUE_NAMES.withdrawals },
      { name: QUEUE_NAMES.fraud },
    ),
    UsersModule,
    WalletModule,
    AuditModule,
    ReferralsModule,
    GamificationModule,
    OfferwallModule,
    FraudModule,
    AuthModule,
    AdsModule,
    RewardsModule,
    FitnessModule,
    MiniGamesModule,
    WithdrawalsModule,
    AnalyticsModule,
    AdminModule,
  ],
})
export class AppModule {}

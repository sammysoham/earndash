import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { GoogleStrategy } from './strategies/google.strategy';
import { GoogleAuthGuard } from '../../common/guards/google-auth.guard';
import { FirebaseAdminService } from '../../common/firebase/firebase-admin.service';
import { UsersModule } from '../users/users.module';
import { WalletModule } from '../wallet/wallet.module';
import { FraudModule } from '../fraud/fraud.module';
import { ReferralsModule } from '../referrals/referrals.module';
import { AuditModule } from '../audit/audit.module';
import { GamificationModule } from '../gamification/gamification.module';

@Module({
  imports: [
    ConfigModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('jwtSecret') ?? 'super-secret',
        signOptions: {
          expiresIn: ((configService.get<string>('jwtExpiresIn') ?? '7d') as never),
        },
      }),
    }),
    UsersModule,
    WalletModule,
    FraudModule,
    ReferralsModule,
    AuditModule,
    GamificationModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, GoogleStrategy, GoogleAuthGuard, FirebaseAdminService],
  exports: [AuthService],
})
export class AuthModule {}

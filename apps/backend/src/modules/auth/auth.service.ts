import {
  BadRequestException,
  Injectable,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import * as bcrypt from 'bcrypt';
import * as geoip from 'geoip-lite';
import { randomUUID } from 'crypto';
import { LoginDto } from './dto/login.dto';
import { SignupDto } from './dto/signup.dto';
import { GoogleMobileLoginDto } from './dto/google-mobile-login.dto';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { FirebaseAdminService } from '../../common/firebase/firebase-admin.service';
import { UsersService } from '../users/users.service';
import { WalletService } from '../wallet/wallet.service';
import { FraudService } from '../fraud/fraud.service';
import { ReferralsService } from '../referrals/referrals.service';
import { AuditService } from '../audit/audit.service';
import { GamificationService } from '../gamification/gamification.service';
import { User, UserRole } from '../users/entities/user.entity';

export interface AuthContext {
  ipAddress: string;
  deviceFingerprint?: string;
  deviceType?: string;
  advertisingId?: string;
}

@Injectable()
export class AuthService {
  private readonly googleClient: OAuth2Client;

  constructor(
    private readonly usersService: UsersService,
    private readonly walletService: WalletService,
    private readonly fraudService: FraudService,
    private readonly referralsService: ReferralsService,
    private readonly auditService: AuditService,
    private readonly gamificationService: GamificationService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly firebaseAdminService: FirebaseAdminService,
  ) {
    this.googleClient = new OAuth2Client(configService.get<string>('googleClientId'));
  }

  async signup(dto: SignupDto, context: AuthContext) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new BadRequestException('Email already registered');
    }

    const existingAdmins = await this.usersService.listAdmins();
    const role = existingAdmins.length === 0 ? UserRole.ADMIN : UserRole.USER;

    const referrer = dto.referralCode
      ? await this.usersService.findByReferralCode(dto.referralCode)
      : null;

    const countryCode = this.lookupCountry(context.ipAddress);
    const antiVpnFlag = await this.fraudService.detectVpn(context.ipAddress);

    const user = await this.usersService.createUser({
      email: dto.email.toLowerCase(),
      passwordHash: await bcrypt.hash(dto.password, 10),
      displayName: dto.displayName,
      role,
      countryCode,
      lastKnownIp: context.ipAddress,
      deviceFingerprint: context.deviceFingerprint ?? null,
      antiVpnFlag,
      referralCode: this.generateReferralCode(dto.displayName),
      referredById: referrer?.id ?? null,
      lastLoginAt: new Date(),
    });

    await this.walletService.ensureWallet(user.id);
    await this.usersService.updateSignals(user, {
      ipAddress: context.ipAddress,
      deviceFingerprint: context.deviceFingerprint,
      deviceType: context.deviceType,
      advertisingId: context.advertisingId,
      countryCode,
      antiVpnFlag,
    });

    if (referrer) {
      await this.referralsService.createReferralRelationship(referrer, user);
    }

    await this.gamificationService.onLogin(user.id);
    await this.auditService.log(user.id, 'AUTH_SIGNUP', 'USER', user.id, {
      countryCode,
      antiVpnFlag,
      role,
    });
    await this.fraudService.enqueueUserAnalysis(user.id);

    return this.buildAuthResponse(await this.usersService.getByIdOrFail(user.id));
  }

  async login(dto: LoginDto, context: AuthContext) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }
    if (user.isBlocked) {
      throw new ForbiddenException('This account has been blocked by admin review');
    }

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const countryCode = this.lookupCountry(context.ipAddress);
    const antiVpnFlag = await this.fraudService.detectVpn(context.ipAddress);

    await this.usersService.updateSignals(user, {
      ipAddress: context.ipAddress,
      deviceFingerprint: dto.deviceFingerprint,
      deviceType: dto.deviceType,
      advertisingId: dto.advertisingId,
      countryCode,
      antiVpnFlag,
    });

    await this.gamificationService.onLogin(user.id);
    await this.auditService.log(user.id, 'AUTH_LOGIN', 'USER', user.id, { countryCode, antiVpnFlag });
    await this.fraudService.enqueueUserAnalysis(user.id);

    const resolvedUser = await this.ensureBootstrapAdmin(user);
    return this.buildAuthResponse(await this.usersService.getByIdOrFail(resolvedUser.id));
  }

  async loginWithGoogleToken(dto: GoogleMobileLoginDto, context: AuthContext) {
    if (dto.idToken) {
      if (this.firebaseAdminService.isConfigured) {
        try {
          const decoded = await this.firebaseAdminService.verifyIdToken(dto.idToken);
          const email = decoded.email ?? dto.email;
          const googleId = decoded.uid || decoded.sub;
          const displayName = decoded.name ?? dto.displayName ?? email?.split('@')[0];
          if (!email || !googleId || !displayName) {
            throw new UnauthorizedException('Firebase token missing profile details');
          }

          return this.loginOrProvisionGoogleUser(
            {
              email,
              googleId,
              displayName,
            },
            {
              ...context,
              deviceFingerprint: dto.deviceFingerprint,
              deviceType: dto.deviceType,
              advertisingId: dto.advertisingId,
            },
          );
        } catch (error) {
          if (!this.configService.get<string>('googleClientId')) {
            throw new UnauthorizedException('Firebase token could not be verified');
          }
        }
      }

      const ticket = await this.googleClient.verifyIdToken({
        idToken: dto.idToken,
        audience: this.configService.get<string>('googleClientId'),
      });
      const payload = ticket.getPayload();
      if (!payload?.email) {
        throw new UnauthorizedException('Google token missing email');
      }

      return this.loginOrProvisionGoogleUser(
        {
          email: payload.email,
          googleId: payload.sub,
          displayName: payload.name ?? payload.email.split('@')[0],
        },
        {
          ...context,
          deviceFingerprint: dto.deviceFingerprint,
          deviceType: dto.deviceType,
          advertisingId: dto.advertisingId,
        },
      );
    }

    if (!dto.email || !dto.googleId) {
      throw new UnauthorizedException('Google login payload is incomplete');
    }

    return this.loginOrProvisionGoogleUser(
      {
        email: dto.email,
        googleId: dto.googleId,
        displayName: dto.displayName ?? dto.email.split('@')[0],
      },
      {
        ...context,
        deviceFingerprint: dto.deviceFingerprint,
        deviceType: dto.deviceType,
        advertisingId: dto.advertisingId,
      },
    );
  }

  async loginWithGoogleProfile(
    profile: { email: string; googleId: string; displayName: string },
    context: AuthContext,
  ) {
    return this.loginOrProvisionGoogleUser(profile, context);
  }

  private async loginOrProvisionGoogleUser(
    profile: { email: string; googleId: string; displayName: string },
    context: AuthContext,
  ) {
    const countryCode = this.lookupCountry(context.ipAddress);
    const antiVpnFlag = await this.fraudService.detectVpn(context.ipAddress);
    let user = await this.usersService.findByGoogleId(profile.googleId);

    if (!user) {
      user =
        (await this.usersService.findByEmail(profile.email)) ??
        (await this.usersService.createUser({
          email: profile.email.toLowerCase(),
          displayName: profile.displayName,
          googleId: profile.googleId,
          passwordHash: null,
          role: UserRole.USER,
          countryCode,
          lastKnownIp: context.ipAddress,
          deviceFingerprint: context.deviceFingerprint ?? null,
          antiVpnFlag,
          referralCode: this.generateReferralCode(profile.displayName),
          referredById: null,
          lastLoginAt: new Date(),
        }));
      await this.walletService.ensureWallet(user.id);
    }

    if (user.isBlocked) {
      throw new ForbiddenException('This account has been blocked by admin review');
    }

    user.googleId = profile.googleId;
    await this.usersService.save(user);
    await this.usersService.updateSignals(user, {
      ipAddress: context.ipAddress,
      deviceFingerprint: context.deviceFingerprint,
      deviceType: context.deviceType,
      advertisingId: context.advertisingId,
      countryCode,
      antiVpnFlag,
    });

    await this.gamificationService.onLogin(user.id);
    await this.auditService.log(user.id, 'AUTH_GOOGLE_LOGIN', 'USER', user.id, { countryCode, antiVpnFlag });
    await this.fraudService.enqueueUserAnalysis(user.id);

    const resolvedUser = await this.ensureBootstrapAdmin(user);
    return this.buildAuthResponse(await this.usersService.getByIdOrFail(resolvedUser.id));
  }

  private async ensureBootstrapAdmin(user: User): Promise<User> {
    if (user.role === UserRole.ADMIN) {
      return user;
    }

    const existingAdmins = await this.usersService.listAdmins();
    if (existingAdmins.length > 0) {
      return user;
    }

    user.role = UserRole.ADMIN;
    const promotedUser = await this.usersService.save(user);
    await this.auditService.log(promotedUser.id, 'AUTH_BOOTSTRAP_ADMIN', 'USER', promotedUser.id, {
      promotedFrom: UserRole.USER,
      promotedTo: UserRole.ADMIN,
    });
    return promotedUser;
  }

  private buildAuthResponse(user: User) {
    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.role,
    });

    return {
      accessToken: token,
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        countryCode: user.countryCode,
        fraudScore: user.fraudScore,
        referralCode: user.referralCode,
        showInLeaderboard: user.showInLeaderboard,
      },
    };
  }

  async me(userId: string) {
    const user = await this.usersService.getByIdOrFail(userId);
    return {
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
        countryCode: user.countryCode,
        fraudScore: user.fraudScore,
        referralCode: user.referralCode,
        showInLeaderboard: user.showInLeaderboard,
      },
    };
  }

  async updatePreferences(userId: string, dto: UpdatePreferencesDto) {
    const user = await this.usersService.getByIdOrFail(userId);
    if (typeof dto.showInLeaderboard === 'boolean') {
      user.showInLeaderboard = dto.showInLeaderboard;
    }
    const savedUser = await this.usersService.save(user);
    await this.auditService.log(userId, 'USER_PREFERENCES_UPDATED', 'USER', userId, {
      showInLeaderboard: savedUser.showInLeaderboard,
    });

    return {
      user: {
        id: savedUser.id,
        email: savedUser.email,
        displayName: savedUser.displayName,
        role: savedUser.role,
        countryCode: savedUser.countryCode,
        fraudScore: savedUser.fraudScore,
        referralCode: savedUser.referralCode,
        showInLeaderboard: savedUser.showInLeaderboard,
      },
    };
  }

  private lookupCountry(ipAddress: string): string | null {
    const result = geoip.lookup(ipAddress);
    return result?.country ?? null;
  }

  private generateReferralCode(displayName: string): string {
    const safeName = displayName.replace(/[^a-zA-Z0-9]/g, '').slice(0, 6).toUpperCase();
    return `${safeName || 'USER'}${randomUUID().slice(0, 6).toUpperCase()}`;
  }
}

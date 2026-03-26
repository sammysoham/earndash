import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { Profile, Strategy } from 'passport-google-oauth20';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(configService: ConfigService) {
    super({
      clientID: configService.get<string>('googleClientId') ?? '',
      clientSecret: configService.get<string>('googleClientSecret') ?? '',
      callbackURL: configService.get<string>('googleCallbackUrl') ?? '',
      scope: ['email', 'profile'],
    });
  }

  validate(
    _accessToken: string,
    _refreshToken: string,
    profile: Profile,
    done: (error: Error | null, user?: Record<string, string>) => void,
  ) {
    const email = profile.emails?.[0]?.value ?? '';
    done(null, {
      googleId: profile.id,
      email,
      displayName: profile.displayName || email.split('@')[0],
    });
  }
}

import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { Profile, Strategy } from 'passport-google-oauth20';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(configService: ConfigService) {
    const clientID = configService.get<string>('googleClientId') ?? '';
    const clientSecret = configService.get<string>('googleClientSecret') ?? '';
    const callbackURL = configService.get<string>('googleCallbackUrl') ?? '';
    const configured = !!(clientID && clientSecret && callbackURL);

    super({
      clientID: configured ? clientID : 'google-oauth-disabled',
      clientSecret: configured ? clientSecret : 'google-oauth-disabled',
      callbackURL: configured ? callbackURL : 'http://localhost/google-oauth-disabled',
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

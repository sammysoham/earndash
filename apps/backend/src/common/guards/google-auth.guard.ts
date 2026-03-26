import {
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class GoogleAuthGuard extends AuthGuard('google') {
  constructor(private readonly configService: ConfigService) {
    super();
  }

  override canActivate(context: ExecutionContext) {
    const clientId = this.configService.get<string>('googleClientId') ?? '';
    const clientSecret = this.configService.get<string>('googleClientSecret') ?? '';
    const callbackUrl = this.configService.get<string>('googleCallbackUrl') ?? '';

    if (!clientId || !clientSecret || !callbackUrl) {
      throw new ServiceUnavailableException('Google OAuth is not configured for this environment');
    }

    return super.canActivate(context);
  }
}

import {
  Body,
  Controller,
  Get,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Request, Response } from 'express';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { SignupDto } from './dto/signup.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleMobileLoginDto } from './dto/google-mobile-login.dto';
import { UpdatePreferencesDto } from './dto/update-preferences.dto';
import { GoogleAuthGuard } from '../../common/guards/google-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { getClientIp } from '../../common/utils/request.util';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly configService: ConfigService,
  ) {}

  @Post('signup')
  signup(@Body() dto: SignupDto, @Req() request: Request) {
    return this.authService.signup(dto, {
      ipAddress: getClientIp(request),
      deviceFingerprint: dto.deviceFingerprint,
      deviceType: dto.deviceType,
      advertisingId: dto.advertisingId,
    });
  }

  @Post('login')
  login(@Body() dto: LoginDto, @Req() request: Request) {
    return this.authService.login(dto, {
      ipAddress: getClientIp(request),
      deviceFingerprint: dto.deviceFingerprint,
      deviceType: dto.deviceType,
      advertisingId: dto.advertisingId,
    });
  }

  @Post('google/mobile')
  googleMobile(@Body() dto: GoogleMobileLoginDto, @Req() request: Request) {
    return this.authService.loginWithGoogleToken(dto, {
      ipAddress: getClientIp(request),
      deviceFingerprint: dto.deviceFingerprint,
      deviceType: dto.deviceType,
      advertisingId: dto.advertisingId,
    });
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: { id: string }) {
    return this.authService.me(user.id);
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('preferences')
  updatePreferences(@CurrentUser() user: { id: string }, @Body() dto: UpdatePreferencesDto) {
    return this.authService.updatePreferences(user.id, dto);
  }

  @Get('google')
  @UseGuards(GoogleAuthGuard)
  googleAuth() {
    return { message: 'Redirecting to Google' };
  }

  @Get('google/callback')
  @UseGuards(GoogleAuthGuard)
  async googleCallback(@Req() request: Request, @Res() response: Response) {
    const authenticatedRequest = request as Request & {
      user: { email: string; googleId: string; displayName: string };
    };
    const authResult = await this.authService.loginWithGoogleProfile(
      authenticatedRequest.user,
      { ipAddress: getClientIp(request) },
    );

    const frontendUrl = this.configService.get<string>('frontendUrl') ?? 'http://localhost:8080';
    return response.redirect(`${frontendUrl}/auth/callback?token=${authResult.accessToken}`);
  }
}

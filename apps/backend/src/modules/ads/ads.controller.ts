import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ConfirmAdRewardDto } from './dto/confirm-ad-reward.dto';
import { AdsService } from './ads.service';

@ApiTags('ads')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('ads')
export class AdsController {
  constructor(private readonly adsService: AdsService) {}

  @Post('reward')
  confirmReward(@CurrentUser() user: { id: string }, @Body() dto: ConfirmAdRewardDto) {
    return this.adsService.confirmReward(user.id, dto);
  }
}

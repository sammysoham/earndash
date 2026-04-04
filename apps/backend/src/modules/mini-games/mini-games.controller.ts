import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { ClaimMiniGameDto } from './dto/claim-mini-game.dto';
import { MiniGamesService } from './mini-games.service';

@ApiTags('mini-games')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('mini-games')
export class MiniGamesController {
  constructor(private readonly miniGamesService: MiniGamesService) {}

  @Post('claim')
  claim(@CurrentUser() user: { id: string }, @Body() dto: ClaimMiniGameDto) {
    return this.miniGamesService.claimReward(user.id, dto);
  }
}

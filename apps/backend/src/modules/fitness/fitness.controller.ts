import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { SyncActivityDto } from './dto/sync-activity.dto';
import { FitnessService } from './fitness.service';

@ApiTags('fitness')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('fitness')
export class FitnessController {
  constructor(private readonly fitnessService: FitnessService) {}

  @Get('move')
  overview(@CurrentUser() user: { id: string }) {
    return this.fitnessService.getOverview(user.id);
  }

  @Post('move/sync')
  sync(@CurrentUser() user: { id: string }, @Body() dto: SyncActivityDto) {
    return this.fitnessService.syncActivity(user.id, dto);
  }

  @Post('move/boost')
  boost(@CurrentUser() user: { id: string }) {
    return this.fitnessService.activateBoost(user.id);
  }
}

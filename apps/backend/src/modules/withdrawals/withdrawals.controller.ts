import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { WithdrawRequestDto } from '../wallet/dto/withdraw-request.dto';
import { WithdrawalsService } from './withdrawals.service';

@ApiTags('withdrawals')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('withdrawals')
export class WithdrawalsController {
  constructor(private readonly withdrawalsService: WithdrawalsService) {}

  @Post()
  requestWithdrawal(@CurrentUser() user: { id: string }, @Body() dto: WithdrawRequestDto) {
    return this.withdrawalsService.requestWithdrawal(user.id, dto);
  }

  @Get()
  recent(@CurrentUser() user: { id: string }) {
    return this.withdrawalsService.userRecent(user.id);
  }
}

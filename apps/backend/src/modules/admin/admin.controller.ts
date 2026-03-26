import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminService } from './admin.service';
import { WithdrawalsService } from '../withdrawals/withdrawals.service';
import { ReviewWithdrawalDto } from './dto/review-withdrawal.dto';
import { GiftCoinsDto } from './dto/gift-coins.dto';
import { UpdateUserBlockDto } from './dto/update-user-block.dto';
import { UpdateWithdrawalStatusDto } from './dto/update-withdrawal-status.dto';
import { UserRole } from '../users/entities/user.entity';

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
    private readonly withdrawalsService: WithdrawalsService,
  ) {}

  @Get('users')
  users() {
    return this.adminService.listUsers();
  }

  @Post('users/:targetUserId/gift')
  giftCoins(
    @CurrentUser() user: { id: string },
    @Param('targetUserId') targetUserId: string,
    @Body() dto: GiftCoinsDto,
  ) {
    return this.adminService.giftCoins(user.id, targetUserId, dto.coins, dto.note, dto.referenceId);
  }

  @Patch('users/:targetUserId/block')
  updateBlock(
    @CurrentUser() user: { id: string },
    @Param('targetUserId') targetUserId: string,
    @Body() dto: UpdateUserBlockDto,
  ) {
    return this.adminService.setUserBlocked(user.id, targetUserId, dto.blocked);
  }

  @Get('fraud')
  fraud() {
    return this.adminService.fraudPanel();
  }

  @Get('withdrawals')
  withdrawals() {
    return this.adminService.withdrawals();
  }

  @Post('withdrawals/:withdrawalId/review')
  reviewWithdrawal(
    @CurrentUser() user: { id: string },
    @Param('withdrawalId') withdrawalId: string,
    @Body() dto: ReviewWithdrawalDto,
  ) {
    return this.withdrawalsService.reviewWithdrawal(user.id, withdrawalId, dto.approve, dto.note);
  }

  @Patch('withdrawals/:withdrawalId/status')
  updateWithdrawalStatus(
    @CurrentUser() user: { id: string },
    @Param('withdrawalId') withdrawalId: string,
    @Body() dto: UpdateWithdrawalStatusDto,
  ) {
    return this.withdrawalsService.setStatus(user.id, withdrawalId, dto.status, dto.note);
  }

  @Get('analytics')
  analytics() {
    return this.adminService.analytics();
  }

  @Get('audit-logs')
  auditLogs() {
    return this.adminService.auditLogs();
  }
}

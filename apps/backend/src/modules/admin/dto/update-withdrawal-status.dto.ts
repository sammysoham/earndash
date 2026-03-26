import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { WithdrawalStatus } from '../../withdrawals/entities/withdrawal.entity';

export class UpdateWithdrawalStatusDto {
  @ApiProperty({ enum: WithdrawalStatus })
  @IsEnum(WithdrawalStatus)
  status!: WithdrawalStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;
}

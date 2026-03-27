import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsInt, IsString, Min } from 'class-validator';
import { MIN_WITHDRAWAL_COINS } from '../../../common/utils/coins.util';
import { WithdrawalMethod } from '../../withdrawals/entities/withdrawal.entity';

export class WithdrawRequestDto {
  @ApiProperty({ enum: WithdrawalMethod })
  @IsEnum(WithdrawalMethod)
  method!: WithdrawalMethod;

  @ApiProperty({ description: 'Destination email, wallet address, or gift card target' })
  @IsString()
  destination!: string;

  @ApiProperty({ description: 'Coin amount' })
  @IsInt()
  @Min(MIN_WITHDRAWAL_COINS)
  coins!: number;
}

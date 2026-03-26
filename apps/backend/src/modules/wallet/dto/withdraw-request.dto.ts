import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsInt, IsString, Min } from 'class-validator';
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
  @Min(5000)
  coins!: number;
}

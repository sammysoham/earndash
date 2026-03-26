import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class ConfirmAdRewardDto {
  @ApiProperty()
  @IsString()
  adUnitId!: string;

  @ApiProperty()
  @IsString()
  sessionId!: string;

  @ApiProperty({ minimum: 5, maximum: 30 })
  @IsInt()
  @Min(5)
  @Max(30)
  coins!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  placement?: string;
}

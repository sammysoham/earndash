import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class GiftCoinsDto {
  @ApiProperty({ minimum: 1 })
  @IsInt()
  @Min(1)
  coins!: number;

  @ApiProperty()
  @IsString()
  note!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  referenceId?: string;
}

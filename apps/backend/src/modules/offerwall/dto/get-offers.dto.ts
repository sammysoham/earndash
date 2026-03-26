import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class GetOffersDto {
  @ApiProperty()
  @IsString()
  userId!: string;

  @ApiProperty()
  @IsString()
  country!: string;

  @ApiProperty()
  @IsString()
  device!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  gaid?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  idfa?: string;
}

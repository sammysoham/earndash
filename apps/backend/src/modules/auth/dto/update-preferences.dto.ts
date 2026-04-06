import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class UpdatePreferencesDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  showInLeaderboard?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(24)
  displayName?: string;
}

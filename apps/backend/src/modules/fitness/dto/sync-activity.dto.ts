import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class ActivityDayDto {
  @ApiProperty()
  @IsString()
  dateKey!: string;

  @ApiProperty()
  @IsString()
  label!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  steps!: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  distanceKm!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  activeMinutes!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  walkMinutes!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  runMinutes!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  calories!: number;
}

export class SyncActivityDto {
  @ApiProperty()
  @IsBoolean()
  supported!: boolean;

  @ApiProperty()
  @IsBoolean()
  permissionGranted!: boolean;

  @ApiProperty()
  @IsString()
  status!: string;

  @ApiProperty()
  @IsString()
  source!: string;

  @ApiProperty()
  @IsString()
  todayDateKey!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  todaySteps!: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  distanceKm!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  activeMinutes!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  walkMinutes!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  runMinutes!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  calories!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  message?: string;

  @ApiProperty({ type: [ActivityDayDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ActivityDayDto)
  weeklyHistory!: ActivityDayDto[];
}

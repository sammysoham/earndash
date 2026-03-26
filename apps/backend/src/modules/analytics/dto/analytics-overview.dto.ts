import { ApiProperty } from '@nestjs/swagger';

export class AnalyticsOverviewDto {
  @ApiProperty()
  totalUsers!: number;

  @ApiProperty()
  dailyActiveUsers!: number;

  @ApiProperty()
  offerConversionRate!: number;

  @ApiProperty()
  withdrawalRate!: number;

  @ApiProperty()
  fraudRate!: number;

  @ApiProperty()
  averageLtvUsd!: number;

  @ApiProperty()
  revenuePerUserUsd!: number;
}

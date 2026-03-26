import { ApiProperty } from '@nestjs/swagger';

export class LeaderboardEntryDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty()
  displayName!: string;

  @ApiProperty()
  level!: number;

  @ApiProperty()
  xp!: number;

  @ApiProperty()
  lifetimeEarned!: number;
}

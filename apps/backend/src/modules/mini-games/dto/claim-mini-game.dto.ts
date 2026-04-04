import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsInt, Max, Min } from 'class-validator';

export const MINI_GAME_IDS = ['CARROM', 'POOL', 'TABLE_TENNIS'] as const;
export type MiniGameId = (typeof MINI_GAME_IDS)[number];

export class ClaimMiniGameDto {
  @ApiProperty({ enum: MINI_GAME_IDS })
  @IsIn(MINI_GAME_IDS)
  gameId!: MiniGameId;

  @ApiProperty({ minimum: 0, maximum: 9999 })
  @IsInt()
  @Min(0)
  @Max(9999)
  score!: number;
}

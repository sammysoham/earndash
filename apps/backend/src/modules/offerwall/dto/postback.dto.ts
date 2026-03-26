import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsInt, IsString, Min } from 'class-validator';
import { OfferProvider } from '../entities/offer-completion.entity';

export class OfferwallPostbackDto {
  @ApiProperty()
  @IsString()
  user_id!: string;

  @ApiProperty()
  @IsInt()
  @Min(1)
  payout!: number;

  @ApiProperty()
  @IsString()
  transaction_id!: string;

  @ApiProperty()
  @IsString()
  offer_id!: string;

  @ApiProperty({ enum: OfferProvider })
  @IsEnum(OfferProvider)
  provider!: OfferProvider;

  @ApiProperty()
  @IsString()
  status!: string;
}

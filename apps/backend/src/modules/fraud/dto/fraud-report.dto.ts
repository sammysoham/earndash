import { ApiProperty } from '@nestjs/swagger';

export class FraudReportDto {
  @ApiProperty()
  userId!: string;

  @ApiProperty()
  fraudScore!: number;

  @ApiProperty({ type: [String] })
  reasons!: string[];

  @ApiProperty()
  withdrawalsDisabled!: boolean;
}

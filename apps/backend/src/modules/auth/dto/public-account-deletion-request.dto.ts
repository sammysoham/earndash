import { IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class PublicAccountDeletionRequestDto {
  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

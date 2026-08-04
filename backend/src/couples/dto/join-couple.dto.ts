import { IsString, Length } from 'class-validator';

export class JoinCoupleDto {
  @IsString()
  @Length(6, 6)
  inviteCode: string;
}

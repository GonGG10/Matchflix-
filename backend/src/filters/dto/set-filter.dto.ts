import { IsArray, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class SetFilterDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  maxDuration?: number;

  @IsOptional()
  @Min(0)
  @Max(10)
  minRating?: number;

  @IsOptional()
  @IsString()
  language?: string;

  @IsOptional()
  @IsInt()
  year?: number;

  @IsOptional()
  @IsString()
  country?: string;

  @IsOptional()
  @IsIn(['MOVIE', 'SERIES'])
  mediaType?: 'MOVIE' | 'SERIES';

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  platformIds?: string[];
}

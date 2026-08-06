import { Type } from 'class-transformer';
import { IsArray, IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class MovieFilterDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  maxDuration?: number;

  @IsOptional()
  @Type(() => Number)
  @Min(0)
  @Max(10)
  minRating?: number;

  @IsOptional()
  @IsString()
  language?: string;

  @IsOptional()
  @Type(() => Number)
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

  @IsOptional()
  @IsString()
  excludeIds?: string;
}

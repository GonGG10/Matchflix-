import { IsIn, IsUUID } from 'class-validator';

export class CreateSwipeDto {
  @IsUUID()
  movieId: string;

  @IsIn(['LIKE', 'DISLIKE'])
  direction: 'LIKE' | 'DISLIKE';
}

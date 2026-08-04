import { Module } from '@nestjs/common';
import { SwipesService } from './swipes.service';
import { SwipesController } from './swipes.controller';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [RealtimeModule],
  controllers: [SwipesController],
  providers: [SwipesService],
})
export class SwipesModule {}

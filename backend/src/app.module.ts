import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import configuration from './config/configuration';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CouplesModule } from './couples/couples.module';
import { CategoriesModule } from './categories/categories.module';
import { PlatformsModule } from './platforms/platforms.module';
import { MoviesModule } from './movies/movies.module';
import { SwipesModule } from './swipes/swipes.module';
import { MatchesModule } from './matches/matches.module';
import { RealtimeModule } from './realtime/realtime.module';
import { CatalogModule } from './catalog/catalog.module';
import { FiltersModule } from './filters/filters.module';

@Module({
  controllers: [AppController],
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    ScheduleModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    CouplesModule,
    CategoriesModule,
    PlatformsModule,
    MoviesModule,
    SwipesModule,
    MatchesModule,
    RealtimeModule,
    CatalogModule,
    FiltersModule,
  ],
})
export class AppModule {}

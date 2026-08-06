import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { RoomsController } from './rooms.controller';
import { RoomsService } from './rooms.service';
import { RoomsScheduler } from './rooms.scheduler';
import { CatalogModule } from '../catalog/catalog.module';

@Module({
  imports: [
    CatalogModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.secret'),
        signOptions: { expiresIn: '1h' },
      }),
    }),
  ],
  controllers: [RoomsController],
  providers: [RoomsService, RoomsScheduler],
  exports: [RoomsService],
})
export class RoomsModule {}

import { Injectable, Logger, UseGuards } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';

// Sala por pareja: "couple:<coupleId>". Cada socket se une a la sala de su
// pareja tras autenticarse enviando su JWT, así ambos móviles reciben el
// evento "match:new" en tiempo real cuando ambos dan LIKE a la misma película.
@Injectable()
@WebSocketGateway({ cors: { origin: '*' }, namespace: '/realtime' })
export class MatchesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(MatchesGateway.name);

  constructor(private readonly jwtService: JwtService) {}

  handleConnection(client: Socket) {
    this.logger.log(`Cliente conectado: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Cliente desconectado: ${client.id}`);
  }

  @SubscribeMessage('join')
  handleJoin(
    @MessageBody() data: { token: string; coupleId: string },
    @ConnectedSocket() client: Socket,
  ) {
    try {
      this.jwtService.verify(data.token); // valida que el token sea legítimo
      client.join(`couple:${data.coupleId}`);
      client.emit('joined', { coupleId: data.coupleId });
    } catch {
      client.emit('error', { message: 'Token inválido' });
      client.disconnect();
    }
  }

  notifyMatch(coupleId: string, match: unknown) {
    this.server.to(`couple:${coupleId}`).emit('match:new', match);
  }
}

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuditLog } from './entities/audit-log.entity';
import { AuditLogsRepository } from './repositories/audit-logs.repository';
import { AuditService } from './audit.service';

@Module({
  imports: [TypeOrmModule.forFeature([AuditLog])],
  providers: [AuditLogsRepository, AuditService],
  exports: [AuditLogsRepository, AuditService],
})
export class AuditModule {}

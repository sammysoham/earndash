import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from '../entities/audit-log.entity';

@Injectable()
export class AuditLogsRepository {
  constructor(
    @InjectRepository(AuditLog)
    private readonly repository: Repository<AuditLog>,
  ) {}

  create(partial: Partial<AuditLog>): AuditLog {
    return this.repository.create(partial);
  }

  save(log: AuditLog): Promise<AuditLog> {
    return this.repository.save(log);
  }

  listRecent(): Promise<AuditLog[]> {
    return this.repository.find({ order: { createdAt: 'DESC' }, take: 100 });
  }
}

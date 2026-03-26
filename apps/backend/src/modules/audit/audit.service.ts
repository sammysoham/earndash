import { Injectable } from '@nestjs/common';
import { AuditLogsRepository } from './repositories/audit-logs.repository';

@Injectable()
export class AuditService {
  constructor(private readonly auditLogsRepository: AuditLogsRepository) {}

  async log(
    actorId: string | null,
    action: string,
    entityType: string,
    entityId: string,
    metadata?: Record<string, unknown>,
  ): Promise<void> {
    await this.auditLogsRepository.save(
      this.auditLogsRepository.create({
        actorId,
        action,
        entityType,
        entityId,
        metadata: metadata ?? null,
      }),
    );
  }

  listRecent() {
    return this.auditLogsRepository.listRecent();
  }
}

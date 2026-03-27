import { Column, Entity, Index } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';

@Entity('audit_logs')
export class AuditLog extends AppBaseEntity {
  @Column({ name: 'actor_id', type: 'varchar', nullable: true })
  actorId!: string | null;

  @Column()
  @Index()
  action!: string;

  @Column({ name: 'entity_type' })
  entityType!: string;

  @Column({ name: 'entity_id' })
  entityId!: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;
}

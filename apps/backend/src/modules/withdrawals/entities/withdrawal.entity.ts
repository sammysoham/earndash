import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

export enum WithdrawalMethod {
  PAYPAL = 'PAYPAL',
  USDT = 'USDT',
  GIFT_CARD = 'GIFT_CARD',
}

export enum WithdrawalStatus {
  PENDING_ADMIN_REVIEW = 'PENDING_ADMIN_REVIEW',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  QUEUED = 'QUEUED',
  PAID = 'PAID',
}

@Entity('withdrawals')
export class Withdrawal extends AppBaseEntity {
  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: WithdrawalMethod })
  method!: WithdrawalMethod;

  @Column({ type: 'enum', enum: WithdrawalStatus, default: WithdrawalStatus.PENDING_ADMIN_REVIEW })
  status!: WithdrawalStatus;

  @Column({ type: 'int' })
  coins!: number;

  @Column({ name: 'usd_amount', type: 'decimal', precision: 10, scale: 2 })
  usdAmount!: string;

  @Column()
  destination!: string;

  @Column({ name: 'approved_by', nullable: true })
  approvedBy!: string | null;

  @Column({ name: 'processed_at', type: 'timestamptz', nullable: true })
  processedAt!: Date | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;
}

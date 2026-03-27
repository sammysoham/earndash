import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

export enum OfferProvider {
  ADGEM = 'AdGem',
  AYET = 'Ayet Studios',
  LOOTABLY = 'Lootably',
  OFFERTORO = 'OfferToro',
  MYLEAD = 'MyLead',
}

export enum OfferCompletionStatus {
  PENDING = 'PENDING',
  RELEASED = 'RELEASED',
  REJECTED = 'REJECTED',
}

@Entity('offer_completions')
export class OfferCompletion extends AppBaseEntity {
  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: OfferProvider })
  provider!: OfferProvider;

  @Column({ name: 'provider_offer_id' })
  offerId!: string;

  @Column({ name: 'transaction_id', unique: true })
  @Index({ unique: true })
  transactionId!: string;

  @Column({ type: 'enum', enum: OfferCompletionStatus, default: OfferCompletionStatus.PENDING })
  status!: OfferCompletionStatus;

  @Column({ name: 'payout_coins', type: 'int' })
  payoutCoins!: number;

  @Column({ name: 'hold_until', type: 'timestamptz' })
  holdUntil!: Date;

  @Column({ name: 'released_at', type: 'timestamptz', nullable: true })
  releasedAt!: Date | null;

  @Column({ name: 'device_type', type: 'varchar', nullable: true })
  deviceType!: string | null;

  @Column({ name: 'ip_address', type: 'varchar', nullable: true })
  ipAddress!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;
}

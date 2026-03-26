import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { Referral } from './referral.entity';

@Entity('referral_payouts')
export class ReferralPayout extends AppBaseEntity {
  @Column({ name: 'referral_id' })
  referralId!: string;

  @ManyToOne(() => Referral, (referral) => referral.payouts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referral_id' })
  referral!: Referral;

  @Column({ name: 'source_completion_id' })
  @Index({ unique: true })
  sourceCompletionId!: string;

  @Column({ type: 'int' })
  coins!: number;
}

import { Column, Entity, JoinColumn, ManyToOne, OneToMany, OneToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';
import { ReferralPayout } from './referral-payout.entity';

@Entity('referrals')
export class Referral extends AppBaseEntity {
  @Column({ name: 'referrer_id' })
  referrerId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referrer_id' })
  referrer!: User;

  @Column({ name: 'referred_user_id', unique: true })
  referredUserId!: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'referred_user_id' })
  referredUser!: User;

  @Column({ name: 'commission_rate', type: 'decimal', precision: 4, scale: 2, default: 0.1 })
  commissionRate!: string;

  @Column({ name: 'lifetime_commission_coins', type: 'int', default: 0 })
  lifetimeCommissionCoins!: number;

  @OneToMany(() => ReferralPayout, (payout) => payout.referral)
  payouts!: ReferralPayout[];
}

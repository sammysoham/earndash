import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

@Entity('ad_rewards')
export class AdReward extends AppBaseEntity {
  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ default: 'AdMob' })
  provider!: string;

  @Column({ name: 'ad_unit_id' })
  adUnitId!: string;

  @Column({ name: 'session_id', unique: true })
  @Index({ unique: true })
  sessionId!: string;

  @Column({ type: 'int' })
  coins!: number;

  @Column({ default: true })
  verified!: boolean;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;
}

import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

@Entity('user_achievements')
export class UserAchievement extends AppBaseEntity {
  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'achievement_key' })
  @Index()
  achievementKey!: string;

  @Column()
  title!: string;

  @Column()
  description!: string;

  @Column({ name: 'xp_reward', type: 'int', default: 0 })
  xpReward!: number;

  @Column({ name: 'coins_reward', type: 'int', default: 0 })
  coinsReward!: number;
}

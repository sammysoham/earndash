import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';

export interface ActivityDayRecord {
  dateKey: string;
  label: string;
  steps: number;
  distanceKm: number;
  activeMinutes: number;
  walkMinutes: number;
  runMinutes: number;
  calories: number;
}

@Entity('user_activity_stats')
export class UserActivityStats extends AppBaseEntity {
  @Column({ name: 'user_id', unique: true })
  userId!: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'today_date_key', default: '' })
  todayDateKey!: string;

  @Column({ name: 'today_steps', type: 'int', default: 0 })
  todaySteps!: number;

  @Column({ name: 'distance_km', type: 'decimal', precision: 10, scale: 2, default: 0 })
  distanceKm!: string;

  @Column({ name: 'active_minutes', type: 'int', default: 0 })
  activeMinutes!: number;

  @Column({ name: 'walk_minutes', type: 'int', default: 0 })
  walkMinutes!: number;

  @Column({ name: 'run_minutes', type: 'int', default: 0 })
  runMinutes!: number;

  @Column({ type: 'int', default: 0 })
  calories!: number;

  @Column({ name: 'rewarded_coins_today', type: 'int', default: 0 })
  rewardedCoinsToday!: number;

  @Column({ name: 'rewarded_steps_today', type: 'int', default: 0 })
  rewardedStepsToday!: number;

  @Column({ name: 'daily_goal_steps', type: 'int', default: 5000 })
  dailyGoalSteps!: number;

  @Column({ name: 'goal_streak_days', type: 'int', default: 0 })
  goalStreakDays!: number;

  @Column({ name: 'weekly_history', type: 'jsonb', nullable: true })
  weeklyHistory!: ActivityDayRecord[] | null;

  @Column({ name: 'step_boost_ends_at', type: 'timestamptz', nullable: true })
  stepBoostEndsAt!: Date | null;

  @Column({ name: 'suspicious_activity_blocked', default: false })
  suspiciousActivityBlocked!: boolean;

  @Column({ name: 'anti_cheat_message', type: 'varchar', nullable: true })
  antiCheatMessage!: string | null;

  @Column({ name: 'tracking_available', default: false })
  trackingAvailable!: boolean;

  @Column({ name: 'tracking_permission_granted', default: false })
  trackingPermissionGranted!: boolean;

  @Column({ name: 'tracking_status', default: 'unknown' })
  trackingStatus!: string;

  @Column({ name: 'tracking_source', default: 'unknown' })
  trackingSource!: string;

  @Column({ name: 'tracking_message', type: 'varchar', nullable: true })
  trackingMessage!: string | null;
}

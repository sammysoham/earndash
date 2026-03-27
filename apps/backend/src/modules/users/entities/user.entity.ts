import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  OneToOne,
} from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { Wallet } from '../../wallet/entities/wallet.entity';
import { UserDevice } from './user-device.entity';

export enum UserRole {
  USER = 'USER',
  ADMIN = 'ADMIN',
}

@Entity('users')
export class User extends AppBaseEntity {
  @Column({ unique: true })
  @Index()
  email!: string;

  @Column({ name: 'password_hash', type: 'varchar', nullable: true })
  passwordHash!: string | null;

  @Column({ name: 'google_id', type: 'varchar', nullable: true, unique: true })
  googleId!: string | null;

  @Column({ name: 'display_name' })
  displayName!: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.USER })
  role!: UserRole;

  @Column({ name: 'country_code', type: 'varchar', nullable: true })
  countryCode!: string | null;

  @Column({ name: 'last_known_ip', type: 'varchar', nullable: true })
  @Index()
  lastKnownIp!: string | null;

  @Column({ name: 'device_fingerprint', type: 'varchar', nullable: true })
  @Index()
  deviceFingerprint!: string | null;

  @Column({ name: 'anti_vpn_flag', default: false })
  antiVpnFlag!: boolean;

  @Column({ name: 'fraud_score', type: 'int', default: 0 })
  fraudScore!: number;

  @Column({ name: 'withdrawals_disabled', default: false })
  withdrawalsDisabled!: boolean;

  @Column({ name: 'is_blocked', default: false })
  isBlocked!: boolean;

  @Column({ name: 'referral_code', unique: true })
  referralCode!: string;

  @Column({ name: 'referred_by_id', type: 'varchar', nullable: true })
  referredById!: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'referred_by_id' })
  referredBy!: User | null;

  @OneToOne(() => Wallet, (wallet) => wallet.user, { cascade: true })
  wallet!: Wallet;

  @OneToMany(() => UserDevice, (device) => device.user)
  devices!: UserDevice[];

  @Column({ default: 1 })
  level!: number;

  @Column({ type: 'int', default: 0 })
  xp!: number;

  @Column({ name: 'daily_streak', type: 'int', default: 0 })
  dailyStreak!: number;

  @Column({ name: 'last_login_at', type: 'timestamptz', nullable: true })
  lastLoginAt!: Date | null;
}

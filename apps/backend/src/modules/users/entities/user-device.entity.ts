import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from './user.entity';

@Entity('user_devices')
export class UserDevice extends AppBaseEntity {
  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, (user) => user.devices, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'device_fingerprint' })
  @Index()
  deviceFingerprint!: string;

  @Column({ name: 'device_type' })
  deviceType!: string;

  @Column({ name: 'advertising_id', nullable: true })
  advertisingId!: string | null;

  @Column({ name: 'ip_address' })
  @Index()
  ipAddress!: string;

  @Column({ name: 'country_code', nullable: true })
  countryCode!: string | null;

  @Column({ name: 'vpn_flag', default: false })
  vpnFlag!: boolean;

  @Column({ name: 'last_seen_at', type: 'timestamptz', default: () => 'CURRENT_TIMESTAMP' })
  lastSeenAt!: Date;
}

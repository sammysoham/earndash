import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';
import { OfferProvider } from './offer-completion.entity';

@Entity('offer_request_logs')
export class OfferRequestLog extends AppBaseEntity {
  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: OfferProvider })
  provider!: OfferProvider;

  @Column({ name: 'country_code' })
  countryCode!: string;

  @Column({ name: 'device_type' })
  deviceType!: string;

  @Column({ name: 'ip_address' })
  ipAddress!: string;
}

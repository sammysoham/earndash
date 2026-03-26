import { Column, Entity, JoinColumn, OneToMany, OneToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { User } from '../../users/entities/user.entity';
import { WalletTransaction } from './wallet-transaction.entity';

@Entity('wallets')
export class Wallet extends AppBaseEntity {
  @Column({ name: 'user_id', unique: true })
  userId!: string;

  @OneToOne(() => User, (user) => user.wallet, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'total_coins', type: 'int', default: 0 })
  totalCoins!: number;

  @Column({ name: 'pending_coins', type: 'int', default: 0 })
  pendingCoins!: number;

  @Column({ name: 'withdrawable_coins', type: 'int', default: 0 })
  withdrawableCoins!: number;

  @Column({ name: 'lifetime_earned', type: 'int', default: 0 })
  lifetimeEarned!: number;

  @OneToMany(() => WalletTransaction, (transaction) => transaction.wallet)
  transactionHistory!: WalletTransaction[];
}

import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';
import { AppBaseEntity } from '../../../common/entities/base.entity';
import { Wallet } from './wallet.entity';
import { User } from '../../users/entities/user.entity';

export enum WalletTransactionType {
  CREDIT_PENDING = 'CREDIT_PENDING',
  RELEASE_PENDING = 'RELEASE_PENDING',
  AD_REWARD = 'AD_REWARD',
  REFERRAL_BONUS = 'REFERRAL_BONUS',
  WITHDRAWAL_REQUEST = 'WITHDRAWAL_REQUEST',
  WITHDRAWAL_PAYOUT = 'WITHDRAWAL_PAYOUT',
  ADJUSTMENT = 'ADJUSTMENT',
}

export enum WalletTransactionStatus {
  PENDING = 'PENDING',
  COMPLETED = 'COMPLETED',
  REVERSED = 'REVERSED',
}

@Entity('wallet_transactions')
export class WalletTransaction extends AppBaseEntity {
  @Column({ name: 'wallet_id' })
  walletId!: string;

  @ManyToOne(() => Wallet, (wallet) => wallet.transactionHistory, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wallet_id' })
  wallet!: Wallet;

  @Column({ name: 'user_id' })
  userId!: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: WalletTransactionType })
  type!: WalletTransactionType;

  @Column({ type: 'enum', enum: WalletTransactionStatus, default: WalletTransactionStatus.COMPLETED })
  status!: WalletTransactionStatus;

  @Column({ type: 'int' })
  coins!: number;

  @Column({ name: 'usd_amount', type: 'decimal', precision: 10, scale: 2 })
  usdAmount!: string;

  @Column({ name: 'reference_type' })
  referenceType!: string;

  @Column({ name: 'reference_id' })
  referenceId!: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;
}

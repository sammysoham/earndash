import { Injectable, NotFoundException } from '@nestjs/common';
import { UsersRepository } from './repositories/users.repository';
import { User } from './entities/user.entity';

export interface UserSignalInput {
  deviceFingerprint?: string;
  deviceType?: string;
  advertisingId?: string;
  ipAddress: string;
  countryCode?: string | null;
  antiVpnFlag?: boolean;
}

@Injectable()
export class UsersService {
  constructor(private readonly usersRepository: UsersRepository) {}

  async createUser(partial: Partial<User>): Promise<User> {
    const entity = this.usersRepository.create(partial);
    return this.usersRepository.save(entity);
  }

  findById(id: string): Promise<User | null> {
    return this.usersRepository.findById(id);
  }

  async getByIdOrFail(id: string): Promise<User> {
    const user = await this.usersRepository.findById(id);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findByEmail(email.toLowerCase());
  }

  findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findByGoogleId(googleId);
  }

  findByReferralCode(referralCode: string): Promise<User | null> {
    return this.usersRepository.findByReferralCode(referralCode);
  }

  listFlaggedUsers(): Promise<User[]> {
    return this.usersRepository.findFlaggedUsers();
  }

  listAllWithWallet(): Promise<User[]> {
    return this.usersRepository.findAllWithWallet();
  }

  listAdmins(): Promise<User[]> {
    return this.usersRepository.listAdmins();
  }

  async updateSignals(user: User, signals: UserSignalInput): Promise<User> {
    user.deviceFingerprint = signals.deviceFingerprint ?? user.deviceFingerprint;
    user.lastKnownIp = signals.ipAddress;
    user.countryCode = signals.countryCode ?? user.countryCode;
    user.antiVpnFlag = signals.antiVpnFlag ?? user.antiVpnFlag;
    user.lastLoginAt = new Date();

    const saved = await this.usersRepository.save(user);

    if (signals.deviceFingerprint) {
      await this.usersRepository.upsertDevice({
        userId: user.id,
        deviceFingerprint: signals.deviceFingerprint,
        deviceType: signals.deviceType ?? 'unknown',
        advertisingId: signals.advertisingId ?? null,
        ipAddress: signals.ipAddress,
        countryCode: signals.countryCode ?? null,
        vpnFlag: signals.antiVpnFlag ?? false,
        lastSeenAt: new Date(),
      });
    }

    return saved;
  }

  save(user: User): Promise<User> {
    return this.usersRepository.save(user);
  }

  async countDuplicateIp(ipAddress: string, excludeUserId?: string): Promise<number> {
    return this.usersRepository.countDuplicateIp(ipAddress, excludeUserId);
  }

  async countDuplicateFingerprint(fingerprint: string, excludeUserId?: string): Promise<number> {
    return this.usersRepository.countDuplicateFingerprint(fingerprint, excludeUserId);
  }

  async leaderboardUsers(): Promise<User[]> {
    return this.usersRepository
      .getRepository()
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.wallet', 'wallet')
      .orderBy('wallet.lifetimeEarned', 'DESC')
      .addOrderBy('user.xp', 'DESC')
      .take(20)
      .getMany();
  }
}

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from '../entities/user.entity';
import { UserDevice } from '../entities/user-device.entity';

@Injectable()
export class UsersRepository {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(UserDevice)
    private readonly devicesRepository: Repository<UserDevice>,
  ) {}

  create(partial: Partial<User>): User {
    return this.usersRepository.create(partial);
  }

  save(user: User): Promise<User> {
    return this.usersRepository.save(user);
  }

  findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id },
      relations: { wallet: true, referredBy: true },
    });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email },
      relations: { wallet: true, referredBy: true },
    });
  }

  findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { googleId },
      relations: { wallet: true, referredBy: true },
    });
  }

  findByReferralCode(referralCode: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { referralCode },
      relations: { wallet: true, referredBy: true },
    });
  }

  findFlaggedUsers(): Promise<User[]> {
    return this.usersRepository.find({
      where: [{ withdrawalsDisabled: true }, { fraudScore: 70 }],
      order: { fraudScore: 'DESC', createdAt: 'DESC' },
      take: 100,
      relations: { wallet: true },
    });
  }

  findAllWithWallet(): Promise<User[]> {
    return this.usersRepository.find({
      order: { createdAt: 'DESC' },
      take: 500,
      relations: { wallet: true, referredBy: true },
    });
  }

  async countDuplicateIp(ipAddress: string, excludeUserId?: string): Promise<number> {
    const qb = this.usersRepository.createQueryBuilder('user').where('user.lastKnownIp = :ipAddress', {
      ipAddress,
    });

    if (excludeUserId) {
      qb.andWhere('user.id != :excludeUserId', { excludeUserId });
    }

    return qb.getCount();
  }

  async countDuplicateFingerprint(fingerprint: string, excludeUserId?: string): Promise<number> {
    const qb = this.usersRepository
      .createQueryBuilder('user')
      .where('user.deviceFingerprint = :fingerprint', { fingerprint });

    if (excludeUserId) {
      qb.andWhere('user.id != :excludeUserId', { excludeUserId });
    }

    return qb.getCount();
  }

  async upsertDevice(partial: Partial<UserDevice>): Promise<UserDevice> {
    const existing = await this.devicesRepository.findOne({
      where: {
        userId: partial.userId,
        deviceFingerprint: partial.deviceFingerprint,
      },
    });

    const entity = this.devicesRepository.create({
      ...existing,
      ...partial,
    });

    return this.devicesRepository.save(entity);
  }

  listAdmins(): Promise<User[]> {
    return this.usersRepository.find({ where: { role: UserRole.ADMIN } });
  }

  getRepository(): Repository<User> {
    return this.usersRepository;
  }
}

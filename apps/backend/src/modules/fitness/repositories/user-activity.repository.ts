import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserActivityStats } from '../entities/user-activity.entity';

@Injectable()
export class UserActivityRepository {
  constructor(
    @InjectRepository(UserActivityStats)
    private readonly repository: Repository<UserActivityStats>,
  ) {}

  create(partial: Partial<UserActivityStats>): UserActivityStats {
    return this.repository.create(partial);
  }

  save(entity: UserActivityStats): Promise<UserActivityStats> {
    return this.repository.save(entity);
  }

  findByUserId(userId: string): Promise<UserActivityStats | null> {
    return this.repository.findOne({ where: { userId } });
  }

  topWeekly(limit = 20): Promise<UserActivityStats[]> {
    return this.repository.find({
      relations: { user: true },
      order: { updatedAt: 'DESC' },
      take: limit,
    });
  }
}

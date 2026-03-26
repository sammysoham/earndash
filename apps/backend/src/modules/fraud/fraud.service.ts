import { InjectQueue } from '@nestjs/bullmq';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Queue } from 'bullmq';
import { Repository } from 'typeorm';
import { JOB_NAMES, QUEUE_NAMES } from '../../config/queue.constants';
import { OfferCompletion } from '../offerwall/entities/offer-completion.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class FraudService {
  constructor(
    private readonly usersService: UsersService,
    private readonly configService: ConfigService,
    @InjectRepository(OfferCompletion)
    private readonly offerCompletionsRepository: Repository<OfferCompletion>,
    @InjectQueue(QUEUE_NAMES.fraud)
    private readonly fraudQueue: Queue,
  ) {}

  async detectVpn(ipAddress: string): Promise<boolean> {
    const apiUrl = this.configService.get<string>('fraud.vpnApiUrl');
    const apiKey = this.configService.get<string>('fraud.vpnApiKey');

    if (!apiUrl || !apiKey || ipAddress.startsWith('127.') || ipAddress === '::1') {
      return false;
    }

    try {
      const endpoint = `${apiUrl.replace(/\/$/, '')}/${encodeURIComponent(
        ipAddress,
      )}?apikey=${encodeURIComponent(apiKey)}&include=privacy`;
      const response = await fetch(endpoint);
      if (!response.ok) {
        return false;
      }

      const payload = (await response.json()) as {
        privacy?: {
          is_vpn?: boolean;
          is_proxy?: boolean;
          is_tor?: boolean;
          is_relay?: boolean;
          is_hosting?: boolean;
          is_cloud_provider?: boolean;
          is_anonymous?: boolean;
        };
      };
      const privacy = payload.privacy;
      return !!(
        privacy?.is_vpn ||
        privacy?.is_proxy ||
        privacy?.is_tor ||
        privacy?.is_relay ||
        privacy?.is_hosting ||
        privacy?.is_cloud_provider ||
        privacy?.is_anonymous
      );
    } catch {
      return false;
    }
  }

  async enqueueUserAnalysis(userId: string): Promise<void> {
    await this.fraudQueue.add(JOB_NAMES.analyzeUser, { userId }, { removeOnComplete: 1000 });
  }

  async analyzeUser(userId: string) {
    const user = await this.usersService.getByIdOrFail(userId);
    const reasons: string[] = [];
    let score = 0;

    if (user.lastKnownIp) {
      const duplicateIpCount = await this.usersService.countDuplicateIp(user.lastKnownIp, user.id);
      if (duplicateIpCount > 0) {
        score += 20;
        reasons.push('Duplicate IP detected');
      }
    }

    if (user.deviceFingerprint) {
      const duplicateDeviceCount = await this.usersService.countDuplicateFingerprint(
        user.deviceFingerprint,
        user.id,
      );
      if (duplicateDeviceCount > 0) {
        score += 25;
        reasons.push('Duplicate device fingerprint detected');
      }
    }

    if (user.antiVpnFlag) {
      score += 25;
      reasons.push('VPN or proxy suspected');
    }

    const suspiciousCompletionCount = await this.offerCompletionsRepository
      .createQueryBuilder('completion')
      .where('completion.userId = :userId', { userId })
      .andWhere("completion.createdAt >= NOW() - INTERVAL '24 HOURS'")
      .getCount();

    if (suspiciousCompletionCount >= 15) {
      score += 20;
      reasons.push('High offer completion rate in the last 24 hours');
    }

    if (user.referredById) {
      const referrer = await this.usersService.findById(user.referredById);
      if (
        referrer &&
        ((referrer.lastKnownIp && referrer.lastKnownIp === user.lastKnownIp) ||
          (referrer.deviceFingerprint && referrer.deviceFingerprint === user.deviceFingerprint))
      ) {
        score += 20;
        reasons.push('Potential referral abuse');
      }
    }

    const threshold = this.configService.get<number>('fraud.withdrawalThreshold', 70);
    user.fraudScore = score;
    user.withdrawalsDisabled = score > threshold;
    await this.usersService.save(user);

    return {
      userId: user.id,
      fraudScore: score,
      reasons,
      withdrawalsDisabled: user.withdrawalsDisabled,
    };
  }
}

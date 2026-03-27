import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DecodedIdToken, getAuth } from 'firebase-admin/auth';
import { App, cert, getApps, initializeApp } from 'firebase-admin/app';
import { readFileSync } from 'fs';

interface ServiceAccountShape {
  project_id?: string;
  client_email?: string;
  private_key?: string;
}

@Injectable()
export class FirebaseAdminService {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private readonly app: App | null;

  constructor(private readonly configService: ConfigService) {
    this.app = this.initialize();
  }

  get isConfigured(): boolean {
    return this.app != null;
  }

  async verifyIdToken(idToken: string): Promise<DecodedIdToken> {
    if (!this.app) {
      throw new Error('Firebase Admin is not configured');
    }

    return getAuth(this.app).verifyIdToken(idToken);
  }

  private initialize(): App | null {
    const existing = getApps()[0];
    if (existing) {
      return existing;
    }

    const credentials = this.readCredentials();
    if (!credentials?.project_id || !credentials.client_email || !credentials.private_key) {
      return null;
    }

    try {
      return initializeApp({
        credential: cert({
          projectId: credentials.project_id,
          clientEmail: credentials.client_email,
          privateKey: credentials.private_key.replace(/\\n/g, '\n'),
        }),
      });
    } catch (error) {
      this.logger.warn(`Firebase Admin failed to initialize: ${String(error)}`);
      return null;
    }
  }

  private readCredentials(): ServiceAccountShape | null {
    const rawJson = this.configService.get<string>('firebase.serviceAccountJson') ?? '';
    if (rawJson.trim()) {
      return this.tryParse(rawJson);
    }

    const path = this.configService.get<string>('firebase.serviceAccountPath') ?? '';
    if (path.trim()) {
      try {
        return this.tryParse(readFileSync(path, 'utf8'));
      } catch (error) {
        this.logger.warn(`Could not read Firebase service account file: ${String(error)}`);
      }
    }

    const projectId = this.configService.get<string>('firebase.projectId') ?? '';
    const clientEmail = this.configService.get<string>('firebase.clientEmail') ?? '';
    const privateKey = this.configService.get<string>('firebase.privateKey') ?? '';
    if (projectId && clientEmail && privateKey) {
      return {
        project_id: projectId,
        client_email: clientEmail,
        private_key: privateKey,
      };
    }

    return null;
  }

  private tryParse(raw: string): ServiceAccountShape | null {
    try {
      return JSON.parse(raw) as ServiceAccountShape;
    } catch (error) {
      this.logger.warn(`Could not parse Firebase service account JSON: ${String(error)}`);
      return null;
    }
  }
}

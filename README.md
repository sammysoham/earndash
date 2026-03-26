# EarnDash

EarnDash is a scalable cross-platform rewards platform scaffold inspired by Freecash. The repo includes:

- `apps/backend`: NestJS API with PostgreSQL, Redis queues, JWT/OAuth auth, webhook ingestion, analytics, fraud tooling, and Swagger docs.
- `apps/flutter_app`: Flutter app scaffold for Android, iOS, and Web with modular features for auth, offerwalls, wallet, withdrawals, gamification, and admin operations.
- `docker-compose.yml`: Local development stack for API, PostgreSQL, Redis, and the Flutter web shell.

## Architecture overview

### Backend

- Domain-oriented NestJS modules with explicit services and repository classes.
- PostgreSQL persistence via TypeORM entities.
- Redis-backed BullMQ queues for reward settlement, withdrawal processing, and fraud analysis.
- REST APIs for client traffic and signed webhooks for offerwall callbacks.
- Cron-based pending reward settlement.
- Swagger docs at `/docs`.

### Frontend

- Flutter app using `go_router`, `hooks_riverpod`, and `dio`.
- Shared design system, typed models, and feature-first folders.
- Mobile/web ready screens for dashboard, offerwalls, wallet, referrals, ads, and admin review.

## Key backend flows

1. Auth captures device fingerprint, IP, country, and VPN suspicion flags.
2. Offerwalls are served through provider adapters that normalize payloads.
3. Offer postbacks are de-duplicated by `transaction_id`, stored, and routed into pending rewards.
4. Reward settlement runs asynchronously with Redis queues and a cron sweep.
5. Withdrawals are policy checked, placed in admin review, and queued for payout.
6. Fraud checks continuously update `fraud_score`; high-risk users are blocked from withdrawals.
7. Referral commissions credit uplines when referred users earn.

## Local setup

### Backend

```bash
npm install
cp apps/backend/.env.example apps/backend/.env
npm run backend:dev
```

### Flutter app

Install Flutter locally, then run:

```bash
cd apps/flutter_app
flutter pub get
flutter run -d chrome
```

### Docker

```bash
docker compose up --build
```

## Notes

- External provider API calls are wrapped behind adapters and fall back to mock offers until provider credentials are configured.
- Google OAuth and VPN intelligence use environment variables for secrets and optional upstream services.
- The scaffold is production-oriented, but you should still add migrations, integration tests, and real provider credentials before launch.

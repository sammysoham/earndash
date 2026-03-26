# EarnDash Architecture

## Backend modules

- `auth`: email auth, Google OAuth, JWT issuance, IP + country + device signals.
- `users`: user profile, fraud flags, referral code, device fingerprints.
- `wallet`: total, pending, withdrawable, lifetime balances and transaction history.
- `offerwall`: provider adapters, normalized offers API, webhook postbacks, signature checks.
- `ads`: rewarded ad confirmation and wallet crediting.
- `rewards`: pending reward sweep and queued settlement after the 7-day hold.
- `withdrawals`: payout requests, limits, admin approval, payout queue.
- `fraud`: duplicate IP/device checks, VPN signals, abnormal velocity scoring.
- `referrals`: referral graph and 10% lifetime commission payouts.
- `gamification`: XP, levels, streaks, achievements, leaderboard.
- `analytics`: DAU, conversion, withdrawal rate, fraud rate, revenue per user, LTV.
- `admin`: review and operations APIs.
- `audit`: immutable event logs.

## Scalability decisions

- Stateless NestJS services behind queues for reward, withdrawal, and fraud workloads.
- Redis-backed BullMQ workers for async processing.
- PostgreSQL for transactional integrity and deduplication constraints.
- Modular provider adapters so offerwalls can be added without changing the public API.
- REST for client traffic and webhooks for server-to-server reward callbacks.

## Core invariants

- `transaction_id` is unique for offer completions.
- Offer completions always credit `pending_coins` first and settle after the hold window.
- Referral payouts are de-duplicated per source completion.
- Fraud score above threshold disables withdrawals.
- All sensitive admin and payout actions emit audit logs.

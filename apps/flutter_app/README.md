# EarnDash Flutter App

Visual thesis: a calm dark workspace with a neon-mint action accent, dense but readable data, and a rewards-first hierarchy that feels premium instead of noisy.

Content plan:
- Hero/workspace: wallet balance, pending rewards, streak, and quick earn actions.
- Support: live offerwall feed and rewarded ads entry point.
- Detail: withdrawals, referrals, achievements, and leaderboard context.
- Final CTA: admin review tools for fraud, payouts, and revenue health.

Interaction thesis:
- Progress bars and section headers fade/slide in with short motion.
- Navigation swaps keep content anchored while the active rail item glows.
- Reward actions pulse subtly when balances update or pending rewards clear.

## Stack

- `flutter_riverpod` for state
- `go_router` for navigation
- `dio` for API access
- `google_sign_in` for Google auth
- `google_mobile_ads` for rewarded ads on mobile

## Notes

- Device identity is generated client-side and forwarded to the backend during auth and offer requests.
- The same Flutter app supports user routes and admin routes; the backend controls role-based access.
- Until backend credentials are configured, the UI can render mock offers from the provider adapters.

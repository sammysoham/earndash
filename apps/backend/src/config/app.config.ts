export default () => ({
  port: Number(process.env.PORT ?? 3000),
  appUrl: process.env.APP_URL ?? 'http://localhost:3000',
  frontendUrl: process.env.FRONTEND_URL ?? 'http://localhost:8080',
  jwtSecret: process.env.JWT_SECRET ?? 'super-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  googleClientId: process.env.GOOGLE_CLIENT_ID ?? '',
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET ?? '',
  googleCallbackUrl:
    process.env.GOOGLE_CALLBACK_URL ?? 'http://localhost:3000/auth/google/callback',
  firebase: {
    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH ?? '',
    serviceAccountJson: process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '',
    projectId: process.env.FIREBASE_PROJECT_ID ?? '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL ?? '',
    privateKey: process.env.FIREBASE_PRIVATE_KEY ?? '',
  },
  postgres: {
    host: process.env.POSTGRES_HOST ?? 'localhost',
    port: Number(process.env.POSTGRES_PORT ?? 5432),
    database: process.env.POSTGRES_DB ?? 'earndash',
    username: process.env.POSTGRES_USER ?? 'postgres',
    password: process.env.POSTGRES_PASSWORD ?? 'postgres',
    synchronize: process.env.DB_SYNC === 'true',
  },
  redis: {
    host: process.env.REDIS_HOST ?? 'localhost',
    port: Number(process.env.REDIS_PORT ?? 6379),
  },
  fraud: {
    withdrawalThreshold: Number(process.env.FRAUD_WITHDRAWAL_THRESHOLD ?? 70),
    vpnApiKey: process.env.IPLOCATE_API_KEY ?? process.env.VPN_API_KEY ?? '',
    vpnApiUrl: process.env.IPLOCATE_API_URL ?? process.env.VPN_API_URL ?? 'https://iplocate.io/api/lookup',
  },
  webhooks: {
    adgem: process.env.WEBHOOK_SECRET_ADGEM ?? '',
    ayet: process.env.WEBHOOK_SECRET_AYET ?? '',
    lootably: process.env.WEBHOOK_SECRET_LOOTABLY ?? '',
    offertoro: process.env.WEBHOOK_SECRET_OFFERTORO ?? '',
    mylead: process.env.WEBHOOK_SECRET_MYLEAD ?? '',
  },
  offerwall: {
    mylead: {
      offerwallUrl: process.env.MYLEAD_OFFERWALL_URL ?? '',
      defaultTitle: process.env.MYLEAD_DEFAULT_TITLE ?? 'MyLead Offerwall',
      defaultDescription:
        process.env.MYLEAD_DEFAULT_DESCRIPTION ??
        'Open the MyLead offerwall to browse surveys, installs, and payout tasks.',
      defaultIconUrl:
        process.env.MYLEAD_DEFAULT_ICON_URL ??
        'https://images.unsplash.com/photo-1556740749-887f6717d7e4?w=200',
      defaultEstimatedMinutes: Number(process.env.MYLEAD_DEFAULT_ESTIMATED_MINUTES ?? 12),
      launchPayoutCoins: Number(process.env.MYLEAD_LAUNCH_PAYOUT_COINS ?? 1200),
    },
  },
});

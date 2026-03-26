export const QUEUE_NAMES = {
  rewards: 'reward-processing',
  withdrawals: 'withdrawal-processing',
  fraud: 'fraud-analysis',
} as const;

export const JOB_NAMES = {
  releasePendingReward: 'release-pending-reward',
  processWithdrawal: 'process-withdrawal',
  analyzeUser: 'analyze-user',
} as const;

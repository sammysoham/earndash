export const COINS_PER_USD = 10000;
export const PENDING_REWARD_HOLD_DAYS = 14;
export const MIN_WITHDRAWAL_COINS = 50000;
export const NEW_USER_DAILY_WITHDRAWAL_CAP_COINS = 200000;

export function coinsToUsd(coins: number): number {
  return Number((coins / COINS_PER_USD).toFixed(2));
}

export function usdToCoins(usd: number): number {
  return Math.round(usd * COINS_PER_USD);
}

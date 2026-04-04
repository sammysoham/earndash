export const COINS_PER_USD = 1000;
export const PENDING_REWARD_HOLD_DAYS = 14;
export const MIN_WITHDRAWAL_COINS = 5000;
export const NEW_USER_DAILY_WITHDRAWAL_CAP_COINS = 20000;

export function coinsToUsd(coins: number): number {
  return Number((coins / COINS_PER_USD).toFixed(2));
}

export function usdToCoins(usd: number): number {
  return Math.round(usd * COINS_PER_USD);
}

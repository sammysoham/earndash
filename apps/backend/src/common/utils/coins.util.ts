export const COINS_PER_USD = 1000;

export function coinsToUsd(coins: number): number {
  return Number((coins / COINS_PER_USD).toFixed(2));
}

export function usdToCoins(usd: number): number {
  return Math.round(usd * COINS_PER_USD);
}

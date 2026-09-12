# Current Strategy Public Standardized Replay Report

[简体中文](./BACKTEST.md) | **English**

[All reports](./REPORTS_EN.md) · [Dynamic sizing replay](./BACKTEST_CAPITAL_EN.md) · [Product overview](./README_EN.md)

> This report replays the signal and state logic from the current production code in chronological order. It evaluates directional quality and historical risk paths; it is not a live account statement, a return promise, or a forecast.

## 1. Report information

| Item | Value |
| --- | --- |
| Report ID | `CURRENT-20260912` |
| Target market | Polymarket BTC 5-minute Up or Down |
| Strategy scope | `Stability Expansion` |
| Period | September 9, 2021 17:50 UTC to September 11, 2026 16:10 UTC |
| Replay method | Causal, chronological replay of each market window |
| Report date | September 12, 2026 |

## 2. Scoring convention

- Correct direction: `+4`.
- Incorrect direction: `-5`.
- No participation or unavailable data: `0`.
- Win rate includes executed selections only.
- Score, drawdown, and daily/weekly/monthly results all use this same standardized unit; they are not pUSD or percentage returns.

The theoretical break-even win rate under `+4/-5` scoring is approximately `55.56%`. Uniform scoring separates signal quality from position size and makes different market periods easier to compare.

## 3. Full-history result

| Metric | Result |
| --- | ---: |
| Market windows replayed | 526,400 |
| Resolved events | 526,399 |
| Executed selections | 146,846 |
| No participation | 379,553 |
| Participation rate | 27.90% |
| Wins / losses | 93,790 / 53,056 |
| Win rate | 63.87% |
| Standardized Score | +109,880 |
| Mean Score per order | +0.748 |
| Maximum drawdown | -88 |
| Longest losing streak | 9 orders |

The observed win rate is about 8.31 percentage points above the theoretical break-even level for this scoring model. This indicates positive historical expectancy under uniform scoring, not that live orders will necessarily settle at exactly `+4/-5`.

## 4. Annual performance

2021 and 2026 are partial years.

| Year | Orders | Win rate | Score | Max drawdown | Longest loss streak |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2021 | 9,262 | 63.33% | +6,484 | -77 | 9 |
| 2022 | 26,817 | 63.21% | +18,465 | -79 | 9 |
| 2023 | 25,614 | 63.65% | +18,666 | -85 | 9 |
| 2024 | 30,915 | 63.89% | +23,184 | -79 | 9 |
| 2025 | 30,707 | 64.21% | +23,927 | -88 | 9 |
| 2026 to date | 23,531 | 64.60% | +19,154 | -76 | 9 |

Every annual segment has a positive Score, with win rates between 63.21% and 64.60%.

## 5. Daily, weekly, and monthly stability

For complete China Standard Time trading days through September 11, 2026:

| Metric | Result |
| --- | ---: |
| Complete trading days | 1,828 |
| Positive days | 1,691 |
| Negative days | 129 |
| Flat days | 8 |
| Positive-day rate | 92.51% |
| Mean / median daily Score | +60.11 / +59 |
| Best / worst day | +194 / -66 |
| Longest run of negative days | 2 days |

No three consecutive negative days occurred in the full period. All 59 complete calendar months had a positive Score; the incomplete September 2026 period was also positive at the cutoff.

## 6. Recent performance

The table ends at September 11, 2026 16:00 UTC and uses only completed trading days for daily stability.

| Window | Orders | Win rate | Score | Max drawdown | Longest loss streak | Positive / negative days |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 365 days | 32,672 | 64.54% | +26,432 | -76 | 9 | 348 / 16 |
| 180 days | 16,958 | 64.99% | +14,417 | -76 | 9 | 174 / 6 |
| 90 days | 8,190 | 65.55% | +7,362 | -64 | 9 | 88 / 2 |
| 30 days | 2,458 | 65.01% | +2,092 | -64 | 7 | 29 / 1 |
| 14 days | 1,300 | 65.69% | +1,186 | -42 | 7 | 14 / 0 |
| 7 complete days | 680 | 65.44% | +605 | -42 | 7 | 7 / 0 |

The latest 30 complete days contained 29 positive and one negative day. All of the latest 14 days and seven complete days were positive. Short windows remain sensitive to market regime and sample size and should not be used alone to infer future results.

## 7. Recent months

| Month | Orders | Win rate | Score | Max drawdown | Longest loss streak |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2026-01 | 2,462 | 63.57% | +1,775 | -55 | 6 |
| 2026-02 | 2,637 | 62.91% | +1,746 | -73 | 9 |
| 2026-03 | 3,121 | 65.27% | +2,728 | -58 | 9 |
| 2026-04 | 2,993 | 64.55% | +2,423 | -76 | 6 |
| 2026-05 | 2,967 | 64.85% | +2,481 | -60 | 7 |
| 2026-06 | 2,899 | 62.81% | +1,894 | -61 | 9 |
| 2026-07 | 3,034 | 65.92% | +2,830 | -54 | 5 |
| 2026-08 | 2,345 | 66.27% | +2,261 | -64 | 6 |
| 2026-09, incomplete | 1,073 | 66.08% | +1,016 | -42 | 7 |

## 8. Maximum drawdown path

The maximum standardized drawdown was `-88`, occurring between July 14 and July 17, 2025. The curve reached its trough after about two days and recovered its previous high roughly one day later. This is a standardized Score drawdown, not a live account percentage drawdown.

## 9. Causality and implementation consistency

- Each decision uses only market data and state available at that point.
- The unresolved outcome of the target market cannot enter the current decision.
- State advances chronologically using completed events and confirmable outcomes.
- The replay calls the production signal and state implementation instead of copying strategy formulas into a separate model.
- Validation compares timestamps, target windows, directions, actions, and outcomes trade by trade, rather than checking only the final total.

These internal checks reduce the risk of future-data leakage, time misalignment, state contamination, and research/implementation drift. They are not a third-party audit.

## 10. Relationship to the capital replay

This report uses fixed scoring to answer how the signal direction and historical risk path behaved. The [dynamic sizing and risk replay](./BACKTEST_CAPITAL_EN.md) adds capital and position state to the same 146,846 signals to illustrate an idealized capital curve. Score and pUSD are different units and must not be combined.

## 11. Live factors not modeled

The standardized replay does not fully model actual entry prices, order-book depth, fillable quantity, unfilled or partial orders, slippage, fees, network and API latency, order-maintenance failures, downtime, or differences between the reference market feed and the market's designated resolution source.

## 12. Disclosure boundary

To protect strategy intellectual property, this report omits complete per-trade data, internal signal branches, feature definitions, historical windows, formulas, thresholds, weights, direction maps, and internal priority rules. The public data demonstrates aggregate behavior, historical risk, and validation methods; it is not sufficient to reproduce the strategy.

## 13. Risk notice

Historical results do not predict future performance. Prediction-market trading can lose some or all capital because of incorrect direction, losing streaks, liquidity, slippage, fees, network failures, and third-party service outages.

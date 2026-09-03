# V16 Public Backtest Report

[简体中文](./BACKTEST.md) | **English**

[Return to product documentation](./README_EN.md)

> This report is a historical code-replay snapshot for the current strategy version. It documents methodology, historical behavior, and risk characteristics. It is not a live account statement, a return promise, or a forecast of future results.

## 1. Report information

| Item | Value |
| --- | --- |
| Report ID | `V16-20260901-1135` |
| Strategy version | Current V16 production-side logic |
| Target market | Polymarket BTC 5-minute Up or Down |
| Primary market-data source | Binance BTCUSDT 5-minute candles |
| Strict reporting interval | Beijing time 2021-09-01 11:35 to 2026-09-01 11:35 |
| Data cutoff | Beijing time 2026-09-01 11:35, latest closed candle at collection time |
| Replay mode | Chronological causal code replay |
| Report date | 2026-09-01 |

## 2. Scoring methodology

To compare different historical periods on one consistent scale, this report uses a fixed standardized scoring model:

- Every executed order uses the same nominal size;
- Correct direction: `+4` points;
- Incorrect direction: `-5` points;
- Strategy STOP/no execution: `0` points;
- Win rate includes executed orders only and excludes STOPs;
- Maximum drawdown and cumulative result are measured in standardized points, not percentages or pUSD.

Under a `+4/-5` payoff structure, the theoretical break-even win rate is approximately `55.56%`. Standardized scoring compares directional quality and historical path stability; it does not represent realized trading profit.

## 3. Strict five-year aggregate

| Metric | Result |
| --- | ---: |
| Total signals | 18,633 |
| Executed orders | 18,285 |
| Strategy STOPs | 348 |
| Wins / losses | 11,656 / 6,629 |
| Executed win rate | 63.75% |
| Standardized net score | +13,479 |
| Maximum drawdown | -72 |
| Longest loss streak | 8 |

STOPs represent approximately `1.87%` of all signals. A STOP means that a candidate was rejected by the complete decision chain; it does not indicate a software fault.

## 4. Calendar-year results

2021 and 2026 are partial calendar years and should not be compared directly with complete years.

| Year | Coverage | Executed orders | Win rate | Standardized score | Maximum drawdown | Longest loss streak |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 2021 | From September 1 | 1,248 | 63.06% | +843 | -57 | 7 |
| 2022 | Full year | 3,164 | 63.50% | +2,261 | -53 | 8 |
| 2023 | Full year | 3,091 | 65.64% | +2,806 | -72 | 7 |
| 2024 | Full year | 3,933 | 61.78% | +2,205 | -70 | 7 |
| 2025 | Full year | 3,836 | 63.48% | +2,735 | -63 | 8 |
| 2026 | Through September 1 | 3,013 | 65.25% | +2,629 | -57 | 7 |

These yearly results describe directional quality and risk paths under the standardized model. They are not realized account returns for those calendar years.

## 5. Recent rolling snapshot

Every interval below ends at Beijing time 2026-09-01 11:35. Recent windows change quickly as new market data arrives.

| Window | Executed orders | Wins / losses | Win rate | Standardized score | Maximum drawdown | Longest loss streak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 days | 68 | 46 / 22 | 67.65% | +74 | -20 | 4 |
| 14 days | 111 | 72 / 39 | 64.86% | +93 | -36 | 4 |
| 30 days | 218 | 153 / 65 | 70.18% | +287 | -42 | 4 |
| 90 days | 1,003 | 671 / 332 | 66.90% | +1,024 | -54 | 6 |

Short windows are sensitive to order count, regime changes, and sparse signals. Seven- or fourteen-day results should not be used alone to judge long-term validity.

## 6. Monthly stability

Aggregated by Beijing calendar month, the strict five-year interval covers 61 complete or partial months:

- Positive standardized score: 61 months;
- Zero standardized score: 0 months;
- Negative standardized score: 0 months.

These are standardized monthly scores, not 61 months of verified live-account profit. September 2021 and September 2026 are partial months, and historical data were used during strategy research and rule selection.

## 7. Causal and equivalence validation

Code replay follows these principles:

- Advance candle by candle in historical time order;
- A decision may read only data that existed at that time;
- The unresolved result of the target market cannot enter the current decision;
- Shadow state may update only from completed events whose results could already be confirmed;
- STOPs, direction adjustments, and final direction follow production-side priority order;
- Acceptance compares per-event time, target window, source, action, direction, and result, not only total score.

During the latest incremental refresh, all 4,098 previously accepted signals from 2025-10-01 through the prior cutoff matched the existing result in time index and every key decision field. The maximum difference in long-control numeric values was limited to floating-point precision and caused no per-event decision change.

These checks reduce the risks of future-data use, timing errors, state contamination, and research/implementation drift. They are internal acceptance checks, not an independent third-party audit.

## 8. Historical research and overfitting boundary

Historical market data were used during strategy research and rule selection. The full five-year interval is therefore not a completely untouched independent sample. It should be interpreted as:

- The behavior of the current rules under chronological historical replay;
- A stability reference across different years and market environments;
- A sample of drawdown, loss-streak, and STOP behavior;
- Evidence used to check consistency between research logic and production code.

It is not a pure out-of-sample forecast and does not demonstrate that future win rate, score, or drawdown will repeat.

“No future outcome is used in an individual replay decision” and “historical data were never used during research” are different claims. This report documents the former design and internal validation; it does not claim the latter.

## 9. Live factors not modeled by the replay

The standardized replay does not fully model:

- The actual entry price of every Polymarket order;
- Available order-book depth and executable quantity;
- Slippage, all fees, and price improvement;
- Network, server, and API latency;
- Partial fills, rejected orders, timeouts, and maintenance-failure probability;
- Credential, balance, allowance, and geographic-restriction faults;
- Differences between Binance data and the designated Polymarket resolution source;
- Application downtime or missed entry windows.

The standardized score cannot be converted directly into pUSD, US-dollar profit, or rate of return. Replay and live results may differ materially.

## 10. Public disclosure boundary

To protect strategy intellectual property, this report does not publish:

- The complete per-event replay CSV;
- Internal sub-branches or per-branch results;
- Exact trigger times and directional mappings;
- Feature fields, indicator combinations, historical windows, thresholds, or weights;
- Internal ORIGINAL, FLIP, and STOP conditions;
- Priority rules or datasets that could be used to reconstruct the strategy.

The public report is intended to explain aggregate behavior, risk paths, validation methodology, and real-world limitations—not to reproduce the strategy.

## 11. Risk notice

Historical results do not represent future performance. Prediction-market trading may cause partial or total capital loss because of directional errors, loss streaks, liquidity, slippage, fees, failed orders, external API changes, network outages, software faults, resolution differences, and regulatory changes.

Commit only funds you can afford to lose completely and remain fully responsible for all trading decisions and results.

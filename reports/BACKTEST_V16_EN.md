# V4 Final + L2 Opt — Standard Strategy Public Backtest Report

[简体中文](./BACKTEST_V16.md) | **English**

[Stability Expansion replay](./BACKTEST_EN.md) · [All reports](./REPORTS_EN.md) · [Product overview](../README_EN.md)

> This report presents the V4 Final + L2 Opt standard strategy replay through October 11, 2026. It is the recommended standard strategy for live trading; `V16` is an internal branch code, not a separate strategy. Historical replay is not a live-account statement or return guarantee.

## 1. Report information

| Item | Value |
| --- | --- |
| Report ID | `V16-20261011-1845` |
| Strategy name | V4 Final + L2 Opt (standard strategy) |
| Internal branch code | `V16` (not a separate strategy) |
| Target market | Polymarket BTC 5-minute Up or Down |
| Primary market-data source | Binance BTCUSDT 5-minute candles |
| Strict reporting interval | Beijing time 2021-07-24 19:30 to 2026-10-11 12:55 |
| Data cutoff | Beijing time 2026-10-11 18:45, latest closed candle at collection time |
| Historical settlement convention | Direction of the target candle's 60-second OHLC4 TWAP; `FLAT` is classified as `UP` |
| Replay mode | Chronological causal code replay |
| Report date | 2026-10-11 |

## 2. Scoring methodology

To compare different historical periods on one consistent scale, this report uses a fixed standardized scoring model:

- Every executed order uses the same nominal size;
- Correct direction: `+4` points;
- Incorrect direction: `-5` points;
- Strategy STOP/no execution: `0` points;
- Win rate includes executed orders only and excludes STOPs;
- Maximum drawdown and cumulative result are measured in standardized points, not percentages or pUSD.

Under a `+4/-5` payoff structure, the theoretical break-even win rate is approximately `55.56%`. Standardized scoring compares directional quality and historical path stability; it does not represent realized trading profit.

## 3. Full-history aggregate

| Metric | Result |
| --- | ---: |
| Total signals | 18,920 |
| Executed orders | 15,361 |
| Strategy STOPs | 3,559 |
| Wins / losses | 10,340 / 5,021 |
| Executed win rate | 67.31% |
| Standardized net score | +16,255 |
| Maximum drawdown | -52 |
| Longest loss streak | 8 |

STOPs represent approximately `18.81%` of all signals. A STOP means that a candidate was rejected by the complete decision chain; it does not indicate a software fault.

## 4. Calendar-year results

2021 and 2026 are partial calendar years and should not be compared directly with complete years.

| Year | Coverage | Executed orders | Win rate | Standardized score | Maximum drawdown | Longest loss streak |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| 2021 | From July 24 | 1,288 | 63.51% | +922 | -42 | 6 |
| 2022 | Full year | 2,522 | 65.50% | +2,258 | -50 | 6 |
| 2023 | Full year | 2,527 | 67.79% | +2,782 | -52 | 7 |
| 2024 | Full year | 3,163 | 66.96% | +3,247 | -51 | 8 |
| 2025 | Full year | 3,065 | 68.74% | +3,638 | -42 | 6 |
| 2026 | Through October 11 | 2,796 | 69.10% | +3,408 | -47 | 8 |

These yearly results describe directional quality and risk paths under the standardized model. They are not realized account returns for those calendar years.

## 5. Recent rolling snapshot

Every interval below ends at the last scored target, Beijing time 2026-10-11 12:55. Market data extend through Beijing time 2026-10-11 18:45; no additional strategy signal occurred in between. Recent windows change quickly as new market data arrives.

| Window | Executed orders | Wins / losses | Win rate | Standardized score | Maximum drawdown | Longest loss streak |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 7 days | 59 | 33 / 26 | 55.93% | +2 | -45 | 8 |
| 14 days | 105 | 65 / 40 | 61.90% | +60 | -45 | 8 |
| 30 days | 211 | 134 / 77 | 63.51% | +151 | -45 | 8 |
| 90 days | 594 | 391 / 203 | 65.82% | +549 | -45 | 8 |

Short windows are sensitive to order count, regime changes, and sparse signals. Seven- or fourteen-day results should not be used alone to judge long-term validity.

## 6. Monthly stability

Aggregated by Beijing calendar month, the full-history interval covers 64 complete or partial months:

- Positive standardized score: 64 months;
- Zero standardized score: 0 months;
- Negative standardized score: 0 months.

These are standardized monthly scores, not 64 months of verified live-account profit. July 2021 and October 2026 are partial months, and historical data were used during strategy research and rule selection.

## 7. Causal and equivalence validation

Code replay follows these principles:

- Advance candle by candle in historical time order;
- A decision may read only data that existed at that time;
- The unresolved result of the target market cannot enter the current decision;
- Shadow state may update only from completed events whose results could already be confirmed;
- STOPs, direction adjustments, and final direction follow production-side priority order;
- Acceptance compares per-event time, target window, source, action, direction, and result, not only total score.

This full replay directly invokes the current production strategy implementation. All 18,920 post-initialization strategy contexts were valid, with zero invalid contexts; the v2.0 parent action and rule-identity comparison produced zero mismatches; and an independent per-event rescore from final direction and target TWAP direction produced zero settlement mismatches. The replay contained no duplicate target candle and used no synthetic data.

These checks reduce the risks of future-data use, timing errors, state contamination, and research/implementation drift. They are internal acceptance checks, not an independent third-party audit.

## 8. Historical research and overfitting boundary

Historical market data were used during strategy research and rule selection. The full-history interval is therefore not a completely untouched independent sample. It should be interpreted as:

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

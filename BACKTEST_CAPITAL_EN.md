# Public Dynamic Sizing and Risk Replay Report

[简体中文](./BACKTEST_CAPITAL.md) | **English**

[Current standardized replay](./BACKTEST_EN.md) · [All reports](./REPORTS_EN.md) · [Product overview](./README_EN.md)

> This report applies production dynamic-sizing and risk logic to the same historical signals used by the current strategy replay. It illustrates an idealized capital path; it is not a live trading record or a return promise.

## 1. Replay setup

| Item | Setting |
| --- | ---: |
| Initial capital | 400 pUSD |
| Minimum position | 5 pUSD |
| Per-trade payoff | Win `+0.8 × position`; loss `-1 × position` |
| Position cap | 1,000 pUSD |
| Daily count/notional caps | Set high enough not to trigger in this experiment |
| Reporting timezone | China Standard Time |

Every position uses only capital and resolved historical state available at that point. Size grows gradually with capital and contracts when resolved performance weakens. Exact formulas and thresholds are not disclosed.

## 2. Overall result

| Metric | Result |
| --- | ---: |
| Executed orders | 146,846 |
| Wins / losses | 93,790 / 53,056 |
| Win rate | 63.87% |
| Risk rejections | 0 |
| Ending capital | 21,273,734.6 pUSD |
| Cumulative PnL | +21,273,334.6 pUSD |
| Minimum / peak capital | 395 / 21,274,934.6 pUSD |
| Maximum absolute drawdown | -17,600 pUSD |
| Maximum percentage drawdown | -9.66% |
| Longest losing streak | 9 orders |
| Min / median / mean / max position | 5 / 1,000 / 964.34 / 1,000 pUSD |

With a fixed 5 pUSD position, the same signals end at 110,280 pUSD (PnL +109,880). Most later dynamic orders reached the configured 1,000 pUSD cap, so the long-run result is highly sensitive to that cap and must not be read as unlimited compounding.

## 3. Annual performance

2021 and 2026 are partial years.

| Year | Orders | Win rate | PnL | Ending capital | Max absolute drawdown |
| --- | ---: | ---: | ---: | ---: | ---: |
| 2021 | 9,262 | 63.33% | +613,846.6 | 614,246.6 | -15,400 |
| 2022 | 26,817 | 63.21% | +3,687,484 | 4,301,730.6 | -15,800 |
| 2023 | 25,614 | 63.65% | +3,729,560 | 8,031,290.6 | -17,000 |
| 2024 | 30,915 | 63.89% | +4,633,328 | 12,664,618.6 | -15,800 |
| 2025 | 30,707 | 64.21% | +4,780,052 | 17,444,670.6 | -17,600 |
| 2026 to date | 23,531 | 64.60% | +3,829,064 | 21,273,734.6 | -15,200 |

## 4. Recent performance

| Window | Orders | Wins / losses | Win rate | PnL | Negative days |
| --- | ---: | ---: | ---: | ---: | ---: |
| 365 days | 32,592 | 21,036 / 11,556 | 64.54% | +5,270,616 | 16 |
| 90 days | 8,067 | 5,297 / 2,770 | 65.66% | +1,467,264 | 2 |
| 30 days | 2,381 | 1,551 / 830 | 65.14% | +410,800 | 1 |
| 14 days | 1,232 | 809 / 423 | 65.67% | +224,200 | 0 |
| 7 days | 593 | 387 / 206 | 65.26% | +103,600 | 0 |

These are rolling windows measured backward from the report cutoff. Their boundaries differ from the complete-day windows in the standardized report, so order counts should not be aligned directly.

## 5. Daily, weekly, and monthly stability

| Statistic | Result |
| --- | ---: |
| Trading days / negative days | 1,829 / 130 |
| Trading weeks / negative weeks | 262 / 0 |
| Trading months / negative months | 61 / 0 |
| Longest run of negative days | 2 days |
| Best / worst day | +38,800 / -13,200 pUSD |

These results use the idealized sizing path and are affected by the position cap, sample size, and partial first and last periods.

## 6. Drawdown and capital safety

- The maximum percentage drawdown, `-9.66%`, occurred during the early low-capital stage.
- The maximum absolute drawdown, `-17,600 pUSD`, occurred in July 2025 and represented about `0.12%` of the peak at that time.
- Capital never fell below 395 pUSD, below the 5 pUSD minimum order, or to zero in this replay.

The absence of capital depletion applies only to this replay setup and does not mean extreme live losses are impossible.

## 7. Consistency checks

- Both current replays contain 146,846 orders with identical win/loss outcomes.
- Reducing the capital replay to a fixed 5 pUSD position reproduces standardized Score +109,880.
- Each position uses only state resolved at that time, not future outcomes.
- Payoff arithmetic, balance continuity, and year/month/day attribution were checked trade by trade.

## 8. Live factors not modeled

This report does not fully simulate actual limit prices, order-book depth, fillable size, unfilled or partial orders, slippage, fees, redemption delays, temporary balance locking, network failures, or third-party API failures. Live results can differ materially.

## 9. Disclosure boundary and risk notice

To protect strategy intellectual property, this report omits sizing formulas, thresholds, internal control names, signal-branch details, and per-trade data. Historical results do not predict future performance. Prediction-market trading can result in partial or total loss of capital.

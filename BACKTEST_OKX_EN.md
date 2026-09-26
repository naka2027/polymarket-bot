# OKX BTCUSDT Perpetual Public Backtest Report

[简体中文](./BACKTEST_OKX.md) | **English**

[Strategy overview](./STRATEGY_OKX_EN.md) · [All reports](./REPORTS_EN.md) · [Product overview](./README_EN.md)

> This report replays the current futures signal and execution logic in chronological order to examine direction, execution paths, leverage state, and historical risk. Its capital curves are high-risk, idealized research models—not live account statements, realizable returns, return promises, or forecasts.

## 1. Report information

| Item | Value |
| --- | --- |
| Report ID | `OKX-BTC-V1.1-20260923` |
| Target market | OKX BTC-USDT perpetual swap |
| Signal interval | Closed BTCUSDT 5-minute market data |
| Execution validation | OKX BTC-USDT-SWAP 1-minute historical data |
| Historical period | July 1, 2020 00:00 UTC to September 23, 2026 13:54 UTC |
| Replay method | Causal code replay in chronological order |
| Report date | September 23, 2026 |

Both 2020 and 2026 are partial years. Every decision uses only data that was closed and available at that point in time.

## 2. Data and validation scope

| Data | Count | Period and status |
| --- | ---: | --- |
| Binance BTCUSDT 5m | 655,084 bars | July 2020 to September 2026; historical gaps restart warm-up by contiguous segment |
| OKX BTC-USDT-SWAP 1m | 3,276,835 bars | July 2020 to September 2026; strictly continuous over the execution range |
| Complete signal events | 141 | All mapped to an OKX execution timestamp |
| Completed trades | 135 | Six additional signals were skipped while a position was already open |

The implementation was checked event by event against a frozen research reference: 141/141 events matched in timestamp, direction, and public classification. OKX execution mapping, protective exits, and leverage sequences also matched their corresponding research reference. This is an internal mechanical acceptance test, not a third-party audit.

## 3. Backtest convention

- Closed Binance 5-minute data generates candidate signals.
- Entry uses the opening price of the corresponding next OKX 1-minute bar as a historical proxy.
- Only one directional position is maintained at a time; new signals do not stack exposure while a position is open.
- Initial protection and profit-responsive dynamic protection are replayed causally from OKX 1-minute OHLC.
- The baseline round-trip trading cost is `8 bp`.
- The model is an isolated-margin research abstraction starting with `100 USDT` of strategy equity.
- Each trade compounds 100% of the then-current strategy equity, with leverage determined only from previously completed state.
- The report compares leverage caps of `5x`, `10x`, and `20x`.
- No unfinished candle, future price, or future trade result enters a decision.

The 100% compounding model is used to amplify and inspect long-run path and drawdown. It is not a sizing recommendation. Live operation remains constrained by balance, margin, notional caps, contract lots, exchange rules, and user configuration.

## 4. Full-history results

All three leverage variants use the same 135 completed trades: 78 wins and 57 losses, a `57.78%` win rate, and a longest losing streak of six trades.

| Leverage cap | Average leverage | Profit Factor | Theoretical ending equity | Theoretical multiple | Max realized drawdown | Max intratrade drawdown |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5x | 4.91x | 4.60 | 98,375.71 USDT | 983.76x | -22.86% | -23.61% |
| 10x | 7.32x | 5.70 | 7,855,368.80 USDT | 78,553.69x | -32.17% | -32.83% |
| 20x | 10.36x | 7.01 | 926,901,132.50 USDT | 9,269,011.32x | -41.60% | -42.16% |

> **20x leverage is high risk and should be used with particular caution.** In this historical replay, the 20x model reached a `-41.60%` maximum realized drawdown and a `-42.16%` maximum intratrade drawdown. Live slippage, mark-price movement, funding, and liquidation rules can increase losses further. A higher theoretical ending value does not necessarily imply a better risk-adjusted choice.

Ending equity is the mathematical path created by starting with 100 USDT and theoretically compounding 100% trade by trade. Exponential compounding makes these figures very large. They do not show that the same size could be filled in a live market and must not be used as product marketing claims or investment expectations.

## 5. Exit structure

| Exit type | Trades | Share |
| --- | ---: | ---: |
| Initial protective exit | 53 | 39.26% |
| Dynamic protective exit | 82 | 60.74% |
| Total | 135 | 100.00% |

This public report discloses exit types and aggregate results, but intentionally omits formulas, thresholds, features, internal priorities, and event-level records that could reproduce the strategy.

## 6. Annual path

The table shows theoretical compounded return within each calendar year. Capital continues compounding across years; 2020 and 2026 are partial years.

| Year | Trades | 5x | 10x | 20x |
| --- | ---: | ---: | ---: | ---: |
| 2020 partial | 16 | +287.76% | +548.48% | +883.13% |
| 2021 | 10 | +95.78% | +212.11% | +250.00% |
| 2022 | 17 | +283.42% | +1,124.27% | +7,227.88% |
| 2023 | 25 | +204.33% | +527.41% | +1,789.21% |
| 2024 | 26 | +88.06% | +143.92% | +124.10% |
| 2025 | 19 | +209.15% | +584.66% | +1,237.05% |
| 2026 through report cutoff | 22 | +91.02% | +202.56% | +549.39% |

Every annual segment was positive in all three models, but each year contains only 10 to 26 trades. A small number of large winning trades can dominate annual results, so the table cannot establish that future years will remain positive.

## 7. Trading-cost pressure

The same historical trades were recalculated with higher total round-trip cost assumptions. The table shows theoretical ending equity:

| Round-trip cost | 5x | 10x | 20x |
| ---: | ---: | ---: | ---: |
| 8 bp baseline | 98,375.71 | 7,855,368.80 | 926,901,132.50 |
| 12 bp | 76,345.26 | 5,323,366.13 | 339,970,797.19 |
| 16 bp | 59,219.38 | 3,202,995.67 | 177,490,259.93 |
| 20 bp | 45,912.67 | 1,811,803.25 | 109,640,470.38 |

Higher static costs materially reduce compounded ending equity and increase drawdown. This stress test still cannot substitute for an order-book, market-capacity, or extreme-market simulation.

## 8. Live factors this public model cannot capture

- One-minute OHLC cannot reconstruct intraminute tick order, queue position, partial fills, or actual FAK slippage.
- A historical proxy cannot fully reproduce mark-price versus last-price trigger differences.
- Funding, maintenance-margin tiers, real liquidation fees, ADL, and temporary exchange-rule changes are excluded.
- The 100% compounding abstraction ignores fixed margin, notional caps, contract-lot rounding, and market capacity.
- Latency, disconnections, rejected requests, risk limits, and failed protective-order submissions can make live results diverge from the replay.
- The sample contains only 135 completed trades, far fewer than a high-frequency strategy; a small number of trades has a large impact on compounded ending equity.
- The replay passed internal consistency checks but has not been independently audited.

## 9. How to interpret this report

This report is best used to answer three questions: whether the implementation matches its research convention, whether historical signals can be executed causally on an OKX price path, and how drawdown expands under different leverage caps. It should not be used to prove future returns, infer deployable capital, or replace paper trading and small-scale live validation.

Run the system in paper mode first and observe signals, protective orders, logs, and recovery behavior. Configure live margin and leverage only according to your own risk tolerance. Leverage magnifies profit, loss, slippage, and liquidation risk at the same time.

## 10. Risk disclosure

Historical backtests do not predict future performance. Digital-asset perpetual swaps involve high volatility, leverage, and the risk of rapid loss, including loss of all posted margin. This document is not investment advice, a return guarantee, or a suitability assessment. Users must verify applicable law, regulation, and platform rules and independently accept all account, capital, network, software, and trading risks.

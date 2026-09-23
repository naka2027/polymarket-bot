# Public Replay Report Center

[简体中文](./REPORTS.md) | **English**

[Back to product overview](./README_EN.md)

This directory preserves public replay reports for both Polymarket and OKX BTC futures. Different markets, payoff structures, and capital models answer different questions, and their figures must not be combined directly.

## OKX BTC futures

| Report | Purpose | Read first |
| --- | --- | ---: |
| [OKX BTCUSDT perpetual public backtest](./BACKTEST_OKX_EN.md) | Uses the current futures signal and execution logic to compare historical performance, drawdown, and cost pressure under 5x, 10x, and 20x isolated-margin research models | 1 |

## Polymarket BTC 5-minute markets

| Report | Purpose | Read first |
| --- | --- | ---: |
| [Stability Expansion Current strategy standardized replay](./BACKTEST_EN.md) | Evaluates directional quality, stability, and historical risk using uniform `+4/-5` scoring | 1 |
| [Stability Expansion Dynamic sizing and risk replay](./BACKTEST_CAPITAL_EN.md) | Applies production sizing and risk logic to the same signals to illustrate an idealized capital path | 2 |
| [V4 Final + L2 Opt V16 replay](./BACKTEST_V16_EN.md) | Preserves traceable results for the previous strategy release; it is not the current recommendation | 3 |

## How to read these reports

- The standardized replay gives every executed signal the same payoff, isolating signal quality from position size.
- The capital replay lets position size change with capital and previously resolved state, illustrating amplification and drawdown under dynamic sizing.
- The OKX report uses futures price paths and an isolated-margin compounding research model. It cannot be combined with Polymarket `+4/-5` scoring or pUSD capital curves.
- The capital replay is an idealized model, not a live fill simulation. Its ending balance must not be interpreted as a return promise.

Public reports disclose aggregate statistics, annual and recent performance, daily stability, drawdown, and validation methods. They intentionally omit formulas, thresholds, features, internal branches, and per-trade data that could reproduce the strategy.

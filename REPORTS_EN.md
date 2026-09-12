# Public Replay Report Center

[简体中文](./REPORTS.md) | **English**

[Back to product overview](./README_EN.md)

This directory preserves two replay views for the current strategy and one historical report for the previous release. They answer different questions and their figures should not be combined directly.

| Report | Purpose | Read first |
| --- | --- | ---: |
| [Current strategy standardized replay](./BACKTEST_EN.md) | Evaluates directional quality, stability, and historical risk using uniform `+4/-5` scoring | 1 |
| [Dynamic sizing and risk replay](./BACKTEST_CAPITAL_EN.md) | Applies production sizing and risk logic to the same signals to illustrate an idealized capital path | 2 |
| [Historical V16 replay](./BACKTEST_V16_EN.md) | Preserves traceable results for the previous strategy release; it is not the current recommendation | 3 |

## How to read the two current reports

- The standardized replay gives every executed signal the same payoff, isolating signal quality from position size.
- The capital replay lets position size change with capital and previously resolved state, illustrating amplification and drawdown under dynamic sizing.
- The capital replay is an idealized model, not a live fill simulation. Its ending balance must not be interpreted as a return promise.

Public reports disclose aggregate statistics, annual and recent performance, daily stability, drawdown, and validation methods. They intentionally omit formulas, thresholds, features, internal branches, and per-trade data that could reproduce the strategy.

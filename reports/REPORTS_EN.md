# Public Replay Report Center

[简体中文](./REPORTS.md) | **English**

[Back to product overview](../README_EN.md)

This directory preserves dated public research snapshots for Polymarket and OKX BTC futures. Figures from different markets and models must not be combined. **A report date is not a live performance update or proof of the currently deployed release.**

## Polymarket BTC 5-minute markets

### V4 Final + L2 Opt · Standard strategy (recommended for live trading)

The recommended standard strategy for live trading. `V16` is an internal branch code, not the name of a separate strategy.

| Report | Purpose |
| --- | --- |
| [V4 Final + L2 Opt · Standardized replay (2026-09-01)](./BACKTEST_V16_EN.md) | Uniform `+4/-5` scoring, year-by-year stability, and historical drawdown |

### Stability Expansion · Latest strategy

Historical replays are available, but the strategy has not yet undergone long-term live validation. Use with caution.

| Report | Purpose |
| --- | --- |
| [Stability Expansion · Standardized replay (2026-09-12)](./BACKTEST_EN.md) | Directional quality and historical risk under uniform `+4/-5` scoring |
| [Stability Expansion · Dynamic sizing & risk replay (2026-09-12)](./BACKTEST_CAPITAL_EN.md) | Idealized capital path, position controls, and model limitations |

## OKX BTC futures

| Report | Purpose |
| --- | --- |
| [OKX BTCUSDT perpetual strategy · Public backtest (2026-09-23)](./BACKTEST_OKX_EN.md) | Signal and execution paths, drawdown, and cost pressure under 5x/10x/20x research models |

## How to read these reports

- The standardized replay gives every executed signal the same payoff, isolating signal quality from position size.
- The capital replay lets position size change with capital and previously resolved state, illustrating amplification and drawdown under dynamic sizing.
- The OKX report uses futures price paths and an isolated-margin compounding research model. It cannot be combined with Polymarket `+4/-5` scoring or pUSD capital curves.
- The capital replay is an idealized model, not a live fill simulation. Its ending balance must not be interpreted as a return promise.

Public reports disclose aggregate statistics, annual and recent performance, daily stability, drawdown, and validation methods. They intentionally omit formulas, thresholds, features, internal branches, and per-trade data that could reproduce the strategy.

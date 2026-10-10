# OKX BTC Perpetual Strategy Overview (Public Edition)

[简体中文](../zh-CN/okx-strategy.md) | **English**

[Back to product overview](../../README_EN.md) · [View the public backtest](../../reports/BACKTEST_OKX_EN.md) · [Download the latest release](https://github.com/naka2027/polymarket-bot/releases/latest)

> An overview of the OKX BTC futures quantitative strategy, its automated trading workflow, and risk management.

## 1. Purpose and market

The current futures strategy targets the OKX `BTC-USDT-SWAP` perpetual contract. It uses confirmed, closed BTCUSDT five-minute market data to generate candidate signals. A separate OKX automation path then performs account checks, sizing, execution, protection, reconciliation, and recovery.

Signal generation and order execution are separate stages. A detected market pattern creates only a candidate; it does not guarantee an order. Market regime, position, account, order, feed-health, and authorization checks must still pass.

## 2. Not a single-indicator strategy

The strategy does not open a position merely because one indicator crosses a line. It looks for candidates from four broad market structures:

- **Trend pullbacks:** the medium-term direction remains intact while a short-term pullback begins to recover;
- **Range breakouts:** a closed candle confirms that price has left a recent structure and volume conditions support the move;
- **Momentum continuation:** directional movement is supported by aggressive trading and the closing structure;
- **Mean reversion:** price becomes unusually extended, directional efficiency fades, and recovery begins.

These families are reviewed with direction, volatility, trade activity, price efficiency, and candle structure. A valid individual pattern may still be skipped.

## 3. Three final entry branches

After filtering, candidates mainly enter through three final branches.

### Base recovery branch

While the medium-term direction remains valid, the strategy waits for a meaningful short-term deviation and then looks for recovery. Conceptually, it follows the broader direction after temporary overextension instead of chasing a move that is already accelerating.

### Multi-family consensus branch

Confidence increases when several relatively independent families—including trend, breakout, momentum, and mean-reversion structures—agree without a meaningful opposite conflict. The system also checks whether price has already traveled too far in that direction to reduce late chasing.

### Strong mean-reversion branch

This branch requires price extension, overbought or oversold behavior, volatility, path efficiency, and reversal confirmation to agree. It does not rely on one oscillator in isolation.

The formulas, windows, thresholds, and internal priorities of these branches are not public.

## 4. Confirmed market data and event-based signals

Signals are evaluated on formally closed five-minute candles. Intrabar contact with a condition does not confirm an entry. This sacrifices some speed but reduces signal drift caused by an unfinished candle.

Signals are event-based. If the same state remains active across several candles, only its first appearance creates an event. A new event requires the condition to clear and form again.

Only one BTC futures direction is maintained at a time. While a position is open, later signals do not add to the position or immediately reverse it.

## 5. From signal to live order

A candidate can become an order only after the execution path verifies conditions such as:

- automation is allowed to run;
- the signal uses the latest confirmed closed data;
- OKX market data and prices are healthy;
- exchange and local position state agree;
- available balance meets margin and exchange minimum-size requirements;
- no unresolved regular or conditional orders remain;
- target leverage and account mode have been confirmed;
- the signal has not already been consumed;
- live authorization and safety checks pass.

Recoverable network or API problems may be retried within a bounded signal window. Once that window expires, the strategy does not chase the stale signal into later market conditions.

## 6. Signal quality and dynamic de-risking

After direction is determined, the system assesses quality using current range, relative volatility, and closing structure. Quality mainly controls permitted leverage; it does not rewrite signal direction.

- Higher-quality signals may use the configured leverage cap;
- Ordinary signals remain subject to a more conservative leverage limit;
- Risk exposure is reduced after a loss streak;
- A deeper strategy-equity drawdown activates a protective leverage mode;
- Limits are relaxed only after performance recovers.

> **20x leverage is a high-risk setting and should be used with extreme caution.** Even if only some signals can use the configured cap, leverage magnifies price movement, slippage, funding, protection-order differences, and liquidation risk. High theoretical backtest returns do not offset the possibility of rapid margin loss in a live account.

## 7. Protection after entry

Once a position is established, the system maintains initial protection and may advance dynamic protection after internal profit conditions are met. The objective is to limit single-trade exposure and retain part of a favorable move, not to promise a fixed return.

Live operation attempts to place essential protection at the exchange so basic protection does not depend on the dashboard remaining online. If a position exists but protection cannot be established reliably, the system enters an emergency handling path designed to avoid leaving the position unprotected.

Background workers continue to reconcile the position, regular orders, conditional orders, and local records, and resume maintenance after a network or process recovery.

## 8. Exclusive control of BTC-USDT-SWAP

When live automation is enabled, the system assumes full control of `BTC-USDT-SWAP` state in the current account, including its position, regular orders, conditional orders, and protective orders. During recovery and reconciliation it may cancel orders that conflict with the current position, rebuild protection, or handle legacy state that cannot be attributed to the current automation flow.

Therefore:

- do not trade the same contract manually in the same account;
- do not let another bot manage the same instrument;
- use a dedicated account or sub-account whenever possible;
- before startup, confirm that any existing position and orders for the instrument may be handed over to the system.

Exclusive control prevents multiple operators from duplicating entries, canceling each other's protection, or creating unrecoverable order state. It does not mean the system controls unrelated instruments in the account.

## 9. Historical research and risk

Historical backtests are used to evaluate signal behavior, trading costs, and risk characteristics across market conditions. Results depend on the data and assumptions used; **they are not realized account returns or guarantees of future performance**.

Live results are also affected by market volatility, execution conditions, trading costs, and system availability. Starting in paper mode is recommended to understand signal generation, order handling, and position protection before considering live trading.

See the [public OKX BTC futures backtest report](../../reports/BACKTEST_OKX_EN.md) for methodology and historical results. Perpetual futures involve substantial risk, including the potential loss of all posted margin.

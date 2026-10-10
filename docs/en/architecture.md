# System Architecture & Trading Flow (Public Overview)

[← Overview](../../README_EN.md) · [Documentation](./README.md)

> This is a public-level architecture and sequencing overview; strategy formulas, parameters, triggers, and internal priorities are not disclosed.

## Signal strategy, risk, and dynamic-sizing architecture

The full decision path can be summarized as:

```text
Closed market data and currently available state
                    ↓
         Continuity and freshness checks
                    ↓
 Continuation     Exhaustion/reversal     Structure/regime
        └─── multiple native signal families create candidates ───┘
                    ↓
           Each family's independent shadow state
                    ↓
      Volatility, local structure, and repeat-trigger review
                    ↓
        Arbitration: one direction or no participation
                    ↓
              Fixed or dynamic sizing
                    ↓
      Account, balance, limit, duplicate, and execution risk
                    ↓
                Place or block the order
```

The order matters. Signals answer "which direction?" State and regime checks ask "is this instance still trustworthy?" Sizing decides "how much exposure is allowed?" Final execution checks decide "can the order be placed safely now?"

### How signals are formed

Each target market receives one final result: keep the candidate direction, adjust it, or skip the window. The decision uses only market data and strategy state that already exist at that point in time.

The native signal first answers: "what kind of tradable structure is present now?" It proposes a base direction but does not directly become the final order.

- **Trend and continuation candidates** look for persistent and efficient movement and ask whether close and trade structure still support continuation;
- **Exhaustion and reversal candidates** look for overextended movement, falling efficiency, and disagreement between the original direction and the close, wick, or trade structure;
- **Structure and regime candidates** separate directional breakouts from isolated wicks, failed breakouts, persistent low-volatility noise, and sudden volatility transitions.

Candidates combine directional persistence, price efficiency, volatility regime, candle and close structure, momentum exhaustion, trade structure, and recent trigger density. No single input determines the final direction on its own.

### Market regime and candidate arbitration

The same price move means something different after a long low-volatility base, inside persistent high volatility, or during noisy consolidation.

The regime layer decides whether continuation, reversal, or temporary avoidance fits the current environment, and whether a native candidate should be kept, downgraded, adjusted, or stopped.

Continuation and reversal candidates may appear in the same market window. Each candidate retains its source, base direction, dependent shadow state, and post-signal rules before deterministic conflict and priority relationships produce one result. An adjustment applies only to the current candidate; if no unique trustworthy result remains, the bot does not trade that window.

### Shadow states: a separate record for each signal family

Think of a shadow as a separate performance state for one signal family. If that family weakens in the current market, only the rules that depend on it are affected; other ready signal families can still be evaluated normally.

A shadow does not simply look at whether the live account just won or lost and reverse the whole strategy. It advances chronologically through completed events for the relevant signal whose results could already be confirmed at that time.

- Shadows advance chronologically;
- A shadow affects only strategy components that depend on it and should not unconditionally block unrelated families;
- It may keep, adjust, pause, or retain conditional candidates;
- It is not an additional live order and does not increase size to chase account losses;
- It does not download and replay the full history before every order.

### Post-signal rules handle "the signal exists, but this is not the right moment to trade it unchanged"

Passing a native signal and shadow state does not guarantee an order. Post-signal rules handle sudden local-structure changes, extremely low or high volatility, volatility transitions, crowded triggers, and structural changes that occur after the original candidate first appears.

They modify only the matching candidate rather than rewriting unrelated signals. The result can be to keep the base direction, adjust that candidate, or STOP it.

### Dynamic sizing scales order size with account capital

Fixed sizing uses the configured amount for every order while remaining subject to platform minimums, available balance, daily count, and daily-notional limits.

Dynamic sizing is calculated independently after final direction is settled. It uses the latest available balance together with recent strategy performance. As account capital grows and performance remains stable, the target order amount increases gradually so profitable phases can make fuller use of the larger capital base.

When changing market conditions move the strategy into drawdown or a loss streak, order size is reduced to limit erosion of accumulated gains. As performance recovers, size is restored progressively and can return to its growth phase.

This process remains bounded by the base target, per-order cap, safety reserve, platform minimums, and actual available funds. Dynamic sizing changes order amount rather than signal direction and never increases size simply to chase losses.

### Layered risk controls

| Risk layer | Main checks |
| --- | --- |
| Signal | Valid direction, shadow state, market regime, conflict arbitration |
| Position size | Fixed/dynamic size, per-order cap, safety reserve, rolling performance |
| Account | Mode, live switch, credentials, balance, allowance, and daily limits |
| Execution | Target market, entry window, duplicate prevention, order mode, and book conditions |
| Runtime | Feed fallback, data repair, retry, logs, supervisor, and watchdog |

These mechanisms can limit exposure but cannot eliminate directional losses, loss streaks, slippage, liquidity, network, or third-party API risk.

### How we check replay against production logic

A strategy decision may use only information that existed at its decision time. Historical replay and runtime state advance chronologically. The unresolved result of the current target market cannot be inserted into the current decision, and a shadow can be updated only by completed events whose results can already be confirmed.

Internal acceptance after an update examines per-event timing, target windows, source, base direction, post-signal action, final direction, STOP outcomes, annual/monthly/weekly behavior, drawdown, loss streaks, data continuity, and per-event equivalence across unchanged periods. These checks are designed to reduce future-data use, timing errors, state contamination, and drift between research and production code, but they are not an independent third-party audit.

Public documentation does not disclose indicator formulas, historical windows, thresholds, weights, directional mappings, branch triggers, or internal priority parameters.

## How automation turns the strategy into a closed loop

The automation layer applies the strategy's data timing, signal arbitration, sizing, risk, and order rules, and handles order tracking, recovery, result records, and optional position redemption.

### From startup to the next target window

```text
Start the application and restore persisted state
          ↓
Discover and validate the target market and window
          ↓
Maintain Binance and Polymarket market data
          ↓
Check candle continuity, data freshness, and shadow readiness
          ↓
Native signal → relevant shadow state → regime and post-signal rules
          ↓
Merge into one final direction, or skip the current window
          ↓
Calculate fixed/dynamic size and apply layered risk controls
          ↓
Execute GTD, FAK, or a configured combination
          ↓
Track submission, resting, fill, partial fill, and failure states
          ↓
Confirm the trade state and wait for the target-market result
          ↓
Record outcome, PnL, triggering branch, and decision reason
          ↓
Optionally redeem eligible positions and maintain usable balance
          ↓
Persist state, watermarks, and logs
          ↓
Continue into the next target market
```

When no valid signal exists, required state is not ready, or risk and execution conditions are not met, the bot skips the current window and records the reason in status or logs.

# Operations, Credential Security & FAQ

[← Overview](../../README_EN.md) · [Documentation](./README.md)

> Account security, open-order reconciliation, and regional requirements take priority over automation convenience.

## What to watch while it runs

### What to monitor during operation

- Whether automation is Running, Stopped, or in Error;
- Whether the target market and window are correct;
- Whether market data is fresh and continuous or a fallback is active;
- Whether required shadows are ready;
- Current order size, daily count, and daily notional;
- Whether each order is submitting, resting, partially filled, filled, cancelled, or failed;
- Whether the market result is confirmed and positions are redeemable;
- Whether logs contain persistent network, data, account, or disk faults.

You do not need to operate every trade, but the status details, order history, and logs should make it clear why the bot traded or skipped a window.

### Faults and recovery

- A fallback path is used when the real-time feed is unhealthy;
- Historical discontinuities trigger targeted repair;
- Shadow-maintenance faults are recorded and retried;
- Linux supervisor, watchdog, and external guard provide process-level recovery;
- Order-maintenance and redemption faults do not create new trading signals.

A restarted process does not imply that every external open order disappeared. After abnormal restart, inspect both application order history and the Polymarket account.

### Software updates & migration

Windows upgrades, cloud updates, and legacy migration steps are documented in [Installation, Cloud Deployment & Updates](./deployment.md). This guide focuses on monitoring, troubleshooting, and credential security.

## Credentials, security, and privacy

The software does not custody funds. Trading signatures are created on your own computer or server, assets remain in your wallet and Polymarket account, and live private keys and Relayer API Keys are protected by local encryption.

### Live credentials

The Polymarket live configuration requires only three fields in the dashboard:

- Wallet private key;
- Relayer API Key;
- Relayer API Key Address.

The wallet private key and Relayer API Key are encrypted on the Windows device or Linux server. The Relayer API Key Address is not a private key, but should still be hidden in public screenshots.

## FAQ and support

### Why should automation not start immediately after first launch?

Some strategies must prepare historical shadow state. Start only after no required item shows Preparing or Error. A shadow showing Off can be valid and does not need to become On.

### Why did the bot place no order?

The strategy may have skipped the window, preparation may be incomplete, risk controls may have blocked the order, or an external condition may have failed. Inspect the current status, order history, and logs together.

### Does closing the application cancel every order?

Not necessarily. Closing a page, stopping automation, or killing the process does not guarantee that every external order or position has been cancelled or completed. Inspect the application and Polymarket account afterward.

### Why can actual fills differ from replay results?

Live orders are affected by the order book, fill price, latency, slippage, partial fills, fees, and API state. Pre-close estimation may also differ from the final closed structure. The strategy primarily references Binance market data, while the final Polymarket result follows the rules and designated source shown on the corresponding market page.

### Can the application bypass geographic restrictions?

No. It is not designed to bypass platform geographic restrictions, account restrictions, compliance obligations, or applicable law.

### How to request support

Use GitHub Issues or [Telegram @polymarket_b](https://t.me/polymarket_b). Include the software version, operating system, current run mode, occurrence time, redacted logs, reproduction steps, and screenshots.

Before submitting, remove or obscure private keys, seed phrases, Relayer API Keys and addresses, server and administrator passwords, cookies, and tokens.

## Activation and licensing

The issued authorization defines activation scope and duration. This repository publishes deployment entry points, docs, and research, not the complete proprietary strategy source. See [`LICENSE`](../../LICENSE).

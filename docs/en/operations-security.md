# Operations, Credential Security & Quick Troubleshooting

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

## Operational quick checks and support

Detailed answers live in the [**full FAQ (26 questions)**](./faq.md). This section keeps only an operational triage guide so the same answers need not be maintained in two places.

| Observed situation | Check first |
| --- | --- |
| Preparing on first launch | Required state, historical-data continuity, connectivity, and disk; see [state preparation](./quick-start.md). |
| Automation is running but no orders appear | Skip reason, shadow readiness, risk limits, order history, and logs; see [FAQ: no orders](./faq.md#q13). |
| External exposure remains after stop/restart | Exchange-side open orders, partial fills, positions, and protection; see [FAQ: stopping](./faq.md#q14). |
| Fill results differ from a historical replay | Price, latency, fees, partial fills, and market rules; see [FAQ: paper vs live](./faq.md#q18). |

### How to request support

Use [GitHub Issues](https://github.com/naka2027/polymarket-bot/issues) or [Telegram @polymarket_b](https://t.me/polymarket_b). Include the software version, operating system, current run mode, occurrence time, redacted logs, reproduction steps, and screenshots.

Before submitting, remove or obscure private keys, seed phrases, Relayer API Keys and addresses, server and administrator passwords, device codes, cookies, and tokens.

## Activation and licensing

For license scope, duration and relevant terms, see the [Software Licensing Terms & Disclaimer](./licensing.md). This repository does not publish the complete proprietary strategy source; see [`LICENSE`](../../LICENSE) for licensing and reserved rights.

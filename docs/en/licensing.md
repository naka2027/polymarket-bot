# Software Activation, Licensing & Pricing

[← Product overview](../../README_EN.md) · [Quick Start](./quick-start.md) · [Documentation](./README.md) · [简体中文](../zh-CN/licensing.md)

This guide explains license durations, activation and expiry behavior. **The product is proprietary software requiring activation, not a custody service or a promise of trading returns.**

## License options and pricing

| License | Duration | Fixed China price | Fixed international price |
| --- | --- | ---: | ---: |
| Free trial | 7 days | Free | Free |
| Monthly | 30 days | ¥899 | 129 USDT |
| Quarterly | 90 days | ¥2,399 | 349 USDT |
| Annual | 365 days | ¥7,999 | 1,199 USDT |

CNY and USDT prices are separately listed fixed prices, not daily exchange-rate conversions. Confirm available license types and payment arrangements when requesting activation. **The trial also requires activation; installing the application alone does not authorize its use.**

## License terms

Read these terms **before paying, submitting a device code, or requesting issuance of an activation code**:

1. **No refunds after the activation code is sent.** The decisive event is **delivery of the activation code to the customer**, not whether it was entered, successfully activated in the app, used, or how long it has been used. Refund requests made for personal, operational or device-related reasons are not accepted once the code is delivered.
2. **Each license is permanently tied to the device for which it was issued.** Replacing a computer, changing hardware, reinstalling the operating system, rebuilding an environment, rebuilding or migrating a VPS/cloud server, or any action that changes the licensed device identity **is treated as a new device**. This policy applies even when the physical computer or server is otherwise the same.
3. **No license transfers, re-binding, resets or replacement activation codes are provided.** If the original code no longer works following these changes, there is no migration, reissue, free reactivation or replacement. Continued use on the new or rebuilt device requires purchasing a new license.
4. **The application exits immediately upon license expiry.** It does not take responsibility for continuing to manage pending orders, positions or protective measures. Exiting does not cancel venue-side orders or close positions. See the expiry section below.

**Verify the device code and intended device/environment before requesting a license. Avoid purchasing a long-term license for a device or environment you expect to reinstall or migrate.**


License fees do not include trading capital, venue fees, on-chain fees, or your own computer/VPS expenses. Neither the application nor historical research results guarantee trading returns.

## Activation

1. Install an official build from [Releases](https://github.com/naka2027/polymarket-bot/releases/latest).
2. Obtain the device code shown on first launch.
3. Contact [Telegram @polymarket_b](https://t.me/polymarket_b) to request a 7-day trial or a paid time-limited license, supplying your device code as instructed.
4. Complete activation. The license is associated with the current device; **actual start/end times and authorized scope follow the issued license information**.
5. Before live trading, complete paper-mode verification and account checks in [Quick Start](./quick-start.md).

Never disclose device codes, private keys, API credentials, server passwords or tokens in public Issues, comments or screenshots.

## What happens when a license expires? (Read before live trading)

**On license expiry, the application process exits and its automated operation stops.** This is **not** a grace mode in which new signals stop but background order/position protection continues.

- After expiry, the exited application does **not** keep tracking or handling submitted, in-flight or incomplete orders. It does not continue cancellation, reconciliation or recovery for them.
- It does **not** continue managing existing positions or updating/rebuilding stop-loss, take-profit or other protective arrangements.
- **Exiting the app does not cancel venue-side orders, close positions, or guarantee that protective orders disappear.** The actual state of orders, partial fills, positions and venue-side protective orders must be checked directly on Polymarket, OKX or the applicable venue.
- Users must monitor and manage any continuing venue-side exposure themselves; **do not depend on an expired application for ongoing trading or risk management**.

**Live users are responsible for monitoring their license end time.** Arrange renewal or a controlled halt in advance. Check open orders, fills, positions and protection directly at the trading venue and take any necessary action. Do not treat expiry as an automatic cancel-all, close-all or risk-reset feature.

## Renewal, refunds, device binding & support

- **Renewal:** To continue using the software on the same device, request renewal before expiry via [Telegram @polymarket_b](https://t.me/polymarket_b). Validity is determined by the issued license. No grace period or automatic renewal is promised. Renewal does not entitle the customer to change devices.
- **Refunds:** **No refunds after an activation code has been sent**, regardless of whether the software was actually activated or used. Confirm your purchase decision before code issuance.
- **Device binding:** A license is valid only on the device for which it was issued. **OS reinstallation, hardware changes, computer replacement, and VPS/cloud-server rebuilding or migration are all treated as a new device.** No transfer, re-binding, reset, code replacement/reissuance or free reactivation is provided. A new device requires a new license purchase.
- **Software updates are not license migration:** An officially supported in-place version update is not a device transfer. Any OS rebuild, environment replacement or change in device identity is subject to the new-device policy.
- **Support:** Consult the [Documentation Center](./README.md) and [FAQ](./faq.md). Technical questions can be sent via [GitHub Issues](https://github.com/naka2027/polymarket-bot/issues) or Telegram. Support does not include device transfers, re-binding or replacement activation codes. No unagreed response-time guarantee is made. Do not share credentials or unredacted logs publicly.

## Disclaimer & risk notice

- **Software and trading outcomes:** This independently developed automated trading tool provides a license to use software, not an investment product or investment advisory service. Historical replays, paper trading, strategy research and published figures are not realized account profits and do not guarantee future returns or protection of principal. Live trading can result in partial or total loss of capital.
- **Funds, accounts and execution:** The software does not custody users' funds. Users remain responsible for wallets, accounts, permissions, credentials and trading risks, including reviewing venue-side orders, fills, positions and protective orders. Running, stopping or expiring software does not replace direct checks with trading venues. In particular, **the application exits when its license expires and no longer manages pending orders, existing positions or stop-loss/take-profit arrangements**. Exiting does not automatically cancel venue-side orders or close positions; see the expiry section above.
- **Third parties and operating environment:** Trading venues, networks, market-data APIs, devices and servers may experience delays, outages or changes. Continuous fault-free operation and execution at an expected price cannot be guaranteed. This project is independent of and not affiliated with or endorsed by Polymarket or OKX.
- **Usage conditions and applicable law:** Users should confirm relevant local laws, platform eligibility and restrictions, account permissions and their own risk tolerance. Refunds, device binding and software use are governed by the terms on this page.
- **Scope of responsibility and source license:** To the extent permitted by applicable law, the developer makes no guarantee against trading losses arising from market conditions, third-party services or user device/account operations. Public repository access is not an open-source license to the complete proprietary strategy implementation; see [`LICENSE`](../../LICENSE).

**Please read and understand these terms before requesting or purchasing a license, and clarify any questions before your activation code is issued.**

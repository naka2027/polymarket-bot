# FAQ · Polymarket BTC 5m & OKX BTC Automation

[← Project overview](../../README_EN.md) · [Documentation](./README.md) · [简体中文](../zh-CN/faq.md)

Straight answers to common questions about evaluating, installing, running, and using the software. For version-specific operations, follow [Quick Start](./quick-start.md), [Installation & Deployment](./deployment.md), and the relevant release notes.

> **Before you start:** Backtests, capital models, and paper results are not realized live profits or guarantees. This is an independent project, not an official Polymarket or OKX product, and it must not be used to evade geographic restrictions. Proprietary strategy rules and parameters are not published here.

## 1. Product and suitability

<a id="q01"></a>

### Q1. What does this software do? Which markets does it support?

It is a self-hosted automated trading system. The public documentation covers **Polymarket BTC 5-minute Up/Down** and **OKX `BTC-USDT-SWAP` perpetual futures**. They have separate signal strategies and execution paths; this is not one strategy automatically copied across venues. [Public architecture](./architecture.md)

<a id="q02"></a>

### Q2. Is there a Windows version? Can I deploy it on Linux or a VPS?

Yes. The documented options are a **Windows 10/11 (64-bit) installer** and **Linux x86_64 / VPS deployment** (Ubuntu LTS recommended). Linux use also requires SSH access, suitable privileges, and connectivity to the required services. [Installation guide](./deployment.md)

<a id="q03"></a>

### Q3. Can I use it without programming?

Windows users can install the released package without compiling source code and then configure it through the application. Linux provides a command-based deployment path, but basic SSH and server administration skills remain useful. **Installed does not mean licensed, configured, or ready for live trading.** [Quick Start](./quick-start.md)

<a id="q04"></a>

### Q4. Is this an official Polymarket or OKX bot?

No. This is an independent project, not affiliated with or endorsed by Polymarket or OKX. Each platform's own terms, market rules, availability, and account restrictions still apply.

<a id="q05"></a>

### Q5. Is the complete application and trading strategy open source?

No. The repository primarily provides public documentation, research reports, installation/migration scripts, and download links to official releases. **The complete proprietary strategy source is not published.** Public repository access is not an open-source license. [License notice](../../LICENSE)

<a id="q06"></a>

### Q6. Is the application completely free? Can I trade as soon as I download it?

Public access to the repository and downloads **does not mean the application has no licensing restrictions**. First use requires device activation; actual authorization scope and duration are determined by the issued license. For fees or terms not published in the current documentation, contact [Telegram @polymarket_b](https://t.me/polymarket_b). Activate, configure, and validate paper mode before considering live operation. [Activation guide](./quick-start.md)

## 2. Download, activation, deployment, and updates

<a id="q07"></a>

### Q7. Where do I download it, and what should I do after installation?

Get an official release from [GitHub Releases](https://github.com/naka2027/polymarket-bot/releases/latest). After installation, obtain your device code, request activation through the official support channel, finish basic configuration, and use **Paper mode** to check data, signals, order state, and logs first. [Step-by-step setup](./quick-start.md)

<a id="q08"></a>

### Q8. Does one-command Linux deployment mean the bot is ready to trade?

No. The installer handles retrieving, verifying, installing, and starting the software. You still need administrator setup where applicable, activation, configuration, required strategy-state preparation, and paper-mode checks. A healthy service is not proof that live trading is ready. [Cloud deployment](./deployment.md)

<a id="q09"></a>

### Q9. Why can't I open the Linux dashboard at the server's public IP on port 8765?

The documented default bind address is **`127.0.0.1:8765`**, accessible locally on the server. Use an **SSH tunnel** for private access or configure an HTTPS reverse proxy for domain-based access; do not simply expose the local dashboard listener to the public Internet. [Nginx / BT Panel instructions](./deployment.md)

<a id="q10"></a>

### Q10. Will updating wipe my settings, logs, or persistent state?

Updates and migrations have dedicated procedures, but you should not assume data is impossible to lose regardless of version, host state, or migration prerequisites. Review release notes, reconcile any open orders and positions, back up important data as appropriate, and verify configuration, version, orders, and strategy readiness after upgrading. [Updates & migration](./deployment.md)

## 3. Paper, live, and execution

<a id="q11"></a>

### Q11. What's the difference between Paper mode and Live mode?

Paper mode is for observing and validating the workflow and simulated results; it is not proof of real fills. Live mode involves real orders, market prices, fees, slippage, and capital at risk. **Paper PnL is not verified live performance.** Paper-mode validation is recommended for first-time setup. [Quick Start](./quick-start.md)

<a id="q12"></a>

### Q12. Why do some strategies show Preparing? Is a shadow state marked Off necessarily broken?

Some strategies need to check and repair historical data and rebuild dependent state in time order. Do not start automation while required items still show Preparing or Error. However, some shadow states marked Off can be valid; not every item must show On. [State preparation](./quick-start.md)

<a id="q13"></a>

### Q13. Why is the bot running but not placing orders?

That is not necessarily a fault. A window may have no eligible trade, a strategy may intentionally skip, required state may not be ready, risk controls may block an order, or data/execution services may be unhealthy. Check **current status, order history, and logs together** rather than judging solely by order count. [Operations checks](./operations-security.md)

<a id="q14"></a>

### Q14. Does stopping automation, closing the app, or closing a browser cancel all orders and positions?

**Do not assume so.** Stopping the process does not guarantee that external orders have been cancelled or positions closed. Check the application's order history and the trading venue's open orders, fills, and positions after stopping. [Operations & recovery](./operations-security.md)

<a id="q15"></a>

### Q15. Why must I review existing OKX positions and orders before enabling automation?

According to the public documentation, live operation **exclusively maintains `BTC-USDT-SWAP` positions and related orders on the connected account**. Reconciliation or recovery may cancel orders inconsistent with its expected state or rebuild protection. Check existing positions, regular/conditional orders, and protection orders first. Avoid manual trading or another bot on the same account and instrument; a dedicated account or sub-account may help. [OKX first-use checks](./quick-start.md)

<a id="q16"></a>

### Q16. Will network failures or abnormal restarts always resolve without intervention?

The system includes data repair, state recovery, retries, and process supervision, but **a restarted process does not mean exchange-side orders disappeared, and not every failure can be assumed fully recovered**. Reconcile live data, orders, fills, positions, and protections after an interruption. [Operations & security](./operations-security.md)

## 4. Market data, backtests, and returns

<a id="q17"></a>

### Q17. Why might Binance price action differ from the final Polymarket BTC 5m result?

Exchange data used for signal research and decisions is not automatically the official settlement reference. **The resolution rules and designated data source on the specific Polymarket market page control the outcome.** Different price definitions, sources, or time boundaries may produce different results. Do not infer settlement solely from a Binance candle. [Public architecture](./architecture.md)

<a id="q18"></a>

### Q18. Why can a strong backtest or paper result differ from live execution?

Live orders face order books, fill prices, latency, slippage, partial fills, fees, API status, and interruptions. Historical research is also constrained by sample selection and validation assumptions. **Backtest, paper, and live records must be evaluated separately.** [Research reports](../../reports/REPORTS_EN.md)

<a id="q19"></a>

### Q19. Does a high win rate guarantee profitability?

No. Profitability also depends on entry prices, odds, fees, payoff asymmetry, sizing, fills, and drawdown paths. Predicting direction correctly does not ensure a profitable executed order, and a short high-win-rate interval does not establish long-term robustness.

<a id="q20"></a>

### Q20. Is the standardized `+4 / -5 / 0` score a USD profit figure?

No. It is a **research scoring convention** for specific Polymarket historical replays, not realized USD or pUSD PnL. It cannot be directly combined with OKX futures capital-model results. Strategies with different participation rates should not be ranked solely by cumulative scores. [Polymarket research reports](../../reports/REPORTS_EN.md)

<a id="q21"></a>

### Q21. Do the historical reports prove future consistent profits?

No. Each report is a dated research snapshot under stated assumptions—not an independent audit or evidence of realized live profits. Review the time span, number of selections, fill/cost assumptions, cross-period behavior, drawdown, and validation limits. Past results do not guarantee future outcomes. [Report index](../../reports/REPORTS_EN.md)

## 5. Credentials, account safety, and geographic restrictions

<a id="q22"></a>

### Q22. Does the software custody my funds? Where are private keys and API keys stored?

The documented model is **self-hosted**: funds remain in the user's own wallet/trading accounts and trade signing occurs on the user's device or server. Polymarket private keys and Relayer API Keys use local encryption. **This does not remove host compromise, credential theft, or trading risks.** Protect the host and account independently. [Credential security](./operations-security.md)

<a id="q23"></a>

### Q23. Do the risk controls prevent all losses or failures?

No. Sizing limits, account checks, data-health checks, and exception handling reduce certain risks but cannot eliminate wrong signals, slippage, thin liquidity, network failures, or third-party API failures. Define an affordable risk exposure before using live trading.

<a id="q24"></a>

### Q24. Can I use this software to bypass Polymarket or OKX regional restrictions?

No. It is not intended to bypass geographic/account restrictions, regulatory obligations, or applicable law. Check whether the relevant service is legally available in your jurisdiction before trading.

## 6. Troubleshooting and support

<a id="q25"></a>

### Q25. What should I include when reporting an issue?

Include the **software version, operating system, mode, timestamp, reproduction steps, relevant status, redacted logs, and screenshots**. Remove private keys, seed phrases, API keys, tokens, passwords, device codes, and other sensitive data before sharing anything publicly.

<a id="q26"></a>

### Q26. Where can I get support or ask about activation?

Use [GitHub Issues](https://github.com/naka2027/polymarket-bot/issues) for public technical issues. For device activation, licensing, or matters requiring private communication, contact [Telegram @polymarket_b](https://t.me/polymarket_b). Before filing, check this FAQ, [Installation](./deployment.md), [Quick Start](./quick-start.md), [Operations](./operations-security.md), and [Releases](https://github.com/naka2027/polymarket-bot/releases).

---

**Related:** [Installation](./deployment.md) · [Quick Start](./quick-start.md) · [Architecture](./architecture.md) · [Operations & Security](./operations-security.md) · [Research Reports](../../reports/REPORTS_EN.md) · [Naka Research blog](https://naka2027.github.io/)

# Installation, Cloud Deployment & Updates

[← Project overview](../../README_EN.md) · [简体中文](../zh-CN/deployment.md) · [Quick Start & Activation](./quick-start.md) · [Operations](./operations-security.md)

Install the Windows edition using its installer. On Linux / VPS, choose one-command deployment or BT Panel deployment. After installing the cloud edition, configure a domain reverse proxy through BT Panel or Nginx to access the dashboard. This guide also covers custom directories, process supervisors, and updates.

## 1. Windows: installation and updates

### Install

1. Open [GitHub Releases](https://github.com/naka2027/polymarket-bot/releases/latest) and download the Windows `.exe` installer for the relevant release.
2. Run it and launch the application.
3. Follow [Quick Start & Activation](./quick-start.md) to activate and configure the application.

### Update

Use the **Update** control in the application, or download a newer installer from [Releases](https://github.com/naka2027/polymarket-bot/releases) and install over the existing version. Afterward, check the version, saved configuration, and strategy status. If historical state needs rebuilding, wait for it to finish before resuming automation.

## 2. Linux / VPS: preparation

- **Host**: Linux x86_64; Ubuntu LTS is a typical choice.
- **Access**: SSH with `root` or `sudo` privileges.
- **Connectivity**: access to GitHub Releases and the market/exchange endpoints used by the application.
- **Domain**: for HTTPS reverse proxying, point a domain at the host and allow inbound ports 80 and 443.

Choose one of the two installation methods below. The default installation directory is `/opt/polymarket-cloud`; the local dashboard listens on `127.0.0.1:8765`.

### Method A: one-command deployment

Log in via SSH and run:

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh | sudo bash -s -- install
```

The script downloads and verifies the official cloud release, initializes its directories, and starts the service. The default `auto` supervisor uses `systemd` if available or standalone supervision otherwise.

On a typical Ubuntu installation, the `systemd` service is `polymarket-cloud.service`. Verify it:

```bash
sudo systemctl status polymarket-cloud.service --no-pager
curl -fsS http://127.0.0.1:8765/api/health
```

The first command applies to a `systemd` deployment; the second tests the local dashboard service. To inspect logs:

```bash
sudo journalctl -u polymarket-cloud.service -n 100 --no-pager
```

### Method B: BT Panel deployment

Install the application with the same script, then manage it using BT Panel's **Process Supervisor**. Run over SSH:

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --supervisor baota install
```

After installation, open **BT Panel → Process Supervisor → Add process** and enter:

| Field | Value |
| --- | --- |
| Name | `polymarket-cloud` (or another name) |
| Start command | `bash /opt/polymarket-cloud/bt-cloud-guard.sh` |
| Working directory | `/opt/polymarket-cloud` |
| Startup / restart | Start on boot; restart after unexpected exit |

Save and start the supervisor task. BT Panel supervises `bt-cloud-guard.sh`, not a separate internal worker process. Verify from SSH:

```bash
curl -fsS http://127.0.0.1:8765/api/health
```

BT Panel site, TLS certificate, and reverse proxy steps are covered in [Section 4](#4-domain-and-reverse-proxy-access).

## 3. Custom directories and supervisors

### Custom installation directory

For a new installation, add `--install-dir` with an absolute path. For example, to use `/srv/polymarket-cloud`:

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --install-dir /srv/polymarket-cloud install
```

Combine it with BT Panel supervision when appropriate:

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --install-dir /srv/polymarket-cloud --supervisor baota install
```

In that case, set the BT Panel start command to `bash /srv/polymarket-cloud/bt-cloud-guard.sh` and working directory to `/srv/polymarket-cloud`. The application installation directory need not be a website document root. Keep an existing installation's directory unchanged when updating.

### Supervisor options

Use `--supervisor` to select the mode (default: `auto`):

| Option | Behavior | Management |
| --- | --- | --- |
| `auto` | Use `systemd` when available, otherwise standalone | Follow the selected mode |
| `systemd` | Install a system service | `systemctl` commands |
| `baota` | Use BT Panel Process Supervisor | Manage it through BT Panel |
| `standalone` | Start a standalone guard | Configure boot-time startup separately if needed |

For explicit `systemd` supervision:

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --supervisor systemd install
```

Useful `systemd` commands:

```bash
sudo systemctl status polymarket-cloud.service
sudo systemctl restart polymarket-cloud.service
sudo systemctl stop polymarket-cloud.service
sudo journalctl -u polymarket-cloud.service -n 100 --no-pager
```

Use one external supervisor per application instance rather than having both BT Panel and `systemd` start it.

## 4. Domain and reverse proxy access

The dashboard listens on the server's `127.0.0.1:8765` by default. Point a domain reverse proxy to this local endpoint to access the dashboard through `https://your-domain`. Two setup paths are provided below.

Before configuring the proxy, confirm the local service responds:

```bash
curl -fsS http://127.0.0.1:8765/api/health
```

### Method A: BT Panel reverse proxy

1. Create an A DNS record for your domain (for example, `bot.example.com`) pointing to the VPS IP.
2. Create a website for the domain in BT Panel. Use a separate website directory, not the application installation directory.
3. Open **Reverse Proxy** for the site and add the following settings:

   | Field | Value |
   | --- | --- |
   | Proxy name | `bot-console` (or any name) |
   | Target URL | `http://127.0.0.1:8765` |
   | Sent host | Original request host or panel default |
   | WebSocket | Enable when the panel provides this option |

4. Open the site's **SSL** settings, issue and enable a certificate, and optionally enable HTTP-to-HTTPS redirection.
5. Visit `https://bot.example.com` and verify login and live status updates.

Menu names vary slightly by BT Panel version. The important settings are the **local proxy target** and the **domain's HTTPS certificate**.

### Method B: Nginx reverse proxy (Ubuntu example)

This example assumes Nginx is managed directly on Ubuntu. If BT Panel manages your Nginx installation, use the BT Panel method above instead.

**Step 1:** Point `bot.example.com` to your server and allow inbound ports 80 and 443. Install Nginx and Certbot:

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

**Step 2:** Create `/etc/nginx/sites-available/bot.example.com`, replacing the example hostname with your own:

```nginx
server {
    listen 80;
    server_name bot.example.com;

    location / {
        proxy_pass http://127.0.0.1:8765;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600s;
        proxy_buffering off;
    }
}
```

Enable and validate the site:

```bash
sudo ln -s /etc/nginx/sites-available/bot.example.com /etc/nginx/sites-enabled/bot.example.com
sudo nginx -t
sudo systemctl reload nginx
```

**Step 3:** Let Certbot configure HTTPS (the domain must resolve correctly and public port 80 must be reachable for issuance):

```bash
sudo certbot --nginx -d bot.example.com --redirect
```

Then visit `https://bot.example.com`. If the page loads but live status fails to refresh, inspect the WebSocket/long-connection proxy settings.

### Temporary access through SSH

Before setting up a domain, you can open a tunnel from your own computer:

```bash
ssh -L 18765:127.0.0.1:8765 root@SERVER_IP
```

Keep the SSH connection open and visit `http://127.0.0.1:18765` locally. Replace `root@SERVER_IP` with your SSH username and server address.

## 5. Cloud updates and legacy migration

### Cloud updates

When a newer version appears in the dashboard, use **Update**. After completion, confirm the version, configuration, and runtime status.

If the dashboard cannot perform the update, run the installed bootstrap over SSH:

```bash
sudo bash /opt/polymarket-cloud/install-cloud.sh update
```

For a custom installation, use its existing directory:

```bash
sudo bash /srv/polymarket-cloud/install-cloud.sh update
```

Check the corresponding [Release notes](https://github.com/naka2027/polymarket-bot/releases) beforehand and review any open orders or abnormal conditions.

### Legacy cloud migration

Older directory layouts use the migration script rather than repeating the first-install command. Verify any release-specific prerequisites and rollback conditions first. To auto-detect an older installation:

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/migrate-cloud.sh \
  | sudo bash -s -- --auto
```

If detection fails, consult the relevant release instructions and specify the old directory with `--source-dir`. The migration script stops when it cannot verify the old version or the required rollback conditions.

## 6. Next steps

Install service → [Configure reverse proxy](#4-domain-and-reverse-proxy-access) → [Activate and configure](./quick-start.md) → [Operations & troubleshooting](./operations-security.md).

# 安装、云端部署与更新

[← 项目首页](../../README.md) · [English](../en/deployment.md) · [快速开始与激活授权](./quick-start.md) · [运行维护](./operations-security.md)

Windows 使用安装程序；Linux / VPS 可选择命令一键部署或宝塔面板部署。云端安装后，可通过宝塔或 Nginx 配置域名反向代理访问控制台。本页同时介绍安装目录、进程守护和软件更新。

## 1. Windows：安装与更新

### 下载安装

1. 打开 [GitHub Releases](https://github.com/naka2027/polymarket-bot/releases/latest)，下载对应版本的 Windows `.exe` 安装包。
2. 双击安装程序，按向导完成安装并打开软件。
3. 参照 [快速开始与激活授权](./quick-start.md)，完成激活授权及首次配置。

### 更新版本

可使用软件控制台中的**更新**入口，或前往 [Releases](https://github.com/naka2027/polymarket-bot/releases) 下载新版本安装包覆盖安装。完成后确认版本号、原有配置和策略运行状态；如提示需要重新准备历史状态，待准备完成后再启动自动化。

## 2. Linux / VPS：安装准备

- **系统**：Linux x86_64，建议使用 Ubuntu LTS。
- **权限**：SSH 连接权限，以及 `root` 或 `sudo` 权限。
- **网络**：服务器能够访问 GitHub Releases 及实际使用的行情、交易服务。
- **域名**：若使用 HTTPS 反向代理，准备解析到服务器的域名，并开放 80、443 端口。

下方两种安装方式任选其一。程序默认安装在 `/opt/polymarket-cloud`，Web 控制台监听 `127.0.0.1:8765`。

### 方式 A：命令一键部署

SSH 登录服务器并执行：

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh | sudo bash -s -- install
```

脚本会获取官方云端发行包、校验并安装，初始化运行目录后启动程序。默认 `auto` 守护方式会在可用时使用 `systemd`，否则使用独立守护。

Ubuntu 常用的 `systemd` 服务名是 `polymarket-cloud.service`。安装后检查：

```bash
sudo systemctl status polymarket-cloud.service --no-pager
curl -fsS http://127.0.0.1:8765/api/health
```

第一条命令适用于 `systemd` 守护；第二条用于检测本机控制台服务。若需要查看服务日志：

```bash
sudo journalctl -u polymarket-cloud.service -n 100 --no-pager
```

### 方式 B：宝塔面板部署

宝塔部署同样使用一键脚本安装程序，再由宝塔的**进程守护管理器**负责运行。通过 SSH 执行：

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --supervisor baota install
```

安装完成后，在宝塔 **进程守护管理器 → 添加守护进程** 中填写：

| 配置项 | 填写内容 |
| --- | --- |
| 进程名称 | `polymarket-cloud`（可自定义） |
| 启动命令 | `bash /opt/polymarket-cloud/bt-cloud-guard.sh` |
| 运行目录 | `/opt/polymarket-cloud` |
| 运行方式 | 启用开机启动、异常退出自动重启 |

保存并启动守护任务。宝塔管理的是 `bt-cloud-guard.sh`；无需单独添加内部工作进程。可通过 SSH 检查：

```bash
curl -fsS http://127.0.0.1:8765/api/health
```

宝塔的网站、SSL 证书和反向代理配置见[第 4 节](#4-域名与反向代理访问控制台)。

## 3. 自定义目录与守护方式

### 更改安装目录

首次安装时可添加 `--install-dir`，使用绝对路径。例如将程序安装到 `/srv/polymarket-cloud`：

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --install-dir /srv/polymarket-cloud install
```

如同时使用宝塔：

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --install-dir /srv/polymarket-cloud --supervisor baota install
```

此时宝塔守护任务的启动命令改为 `bash /srv/polymarket-cloud/bt-cloud-guard.sh`，运行目录改为 `/srv/polymarket-cloud`。安装目录无需设置为网站根目录。已有实例更新时继续使用原安装路径。

### 选择守护方式

通过 `--supervisor` 指定运行方式（不填写时为 `auto`）：

| 参数 | 运行方式 | 管理方法 |
| --- | --- | --- |
| `auto` | 有 `systemd` 时使用 `systemd`，否则独立守护 | 按实际选定方式管理 |
| `systemd` | 注册系统服务 | 使用 `systemctl` 管理服务 |
| `baota` | 由宝塔进程守护管理器托管 | 在宝塔面板启停和查看日志 |
| `standalone` | 独立守护运行 | 无自动注册的开机服务，需自行安排开机启动 |

例如显式启用 `systemd`：

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/install-cloud.sh \
  | sudo bash -s -- --supervisor systemd install
```

`systemd` 常用管理命令：

```bash
sudo systemctl status polymarket-cloud.service
sudo systemctl restart polymarket-cloud.service
sudo systemctl stop polymarket-cloud.service
sudo journalctl -u polymarket-cloud.service -n 100 --no-pager
```

同一实例只需由一种外部方式守护，避免宝塔与 `systemd` 同时重复启动。

## 4. 域名与反向代理访问控制台

程序默认监听服务器本机 `127.0.0.1:8765`。可将域名反向代理到该地址，在浏览器中通过 `https://你的域名` 访问控制台。以下分别介绍宝塔和 Nginx 的配置。

配置前先确认本机服务已启动：

```bash
curl -fsS http://127.0.0.1:8765/api/health
```

### 方式 A：宝塔反向代理

1. 在域名服务商处添加 A 记录，将域名（示例：`bot.example.com`）解析到服务器 IP。
2. 在宝塔 **网站** 中创建对应域名的站点。站点目录使用普通空目录，不使用程序安装目录。
3. 打开该站点的 **反向代理**，添加代理规则：

   | 配置项 | 填写内容 |
   | --- | --- |
   | 代理名称 | 自定义，如 `bot-console` |
   | 目标 URL | `http://127.0.0.1:8765` |
   | 发送域名 | 使用原请求域名或面板默认值 |
   | WebSocket | 面板提供该选项时开启 |

4. 在网站的 **SSL** 页面申请并启用证书，按需要启用 HTTP 跳转 HTTPS。
5. 在浏览器中打开 `https://bot.example.com`，检查登录和状态刷新是否正常。

不同宝塔版本的菜单名称可能略有不同，关键是**网站反向代理目标地址**与**域名的 HTTPS 证书**这两项配置。

### 方式 B：Nginx 反向代理（Ubuntu 示例）

本例适用于自行管理 Nginx 的 Ubuntu 服务器。如果已使用宝塔管理 Nginx，直接采用上面的宝塔方式即可。

**第 1 步：** 将 `bot.example.com` 解析到服务器公网 IP，允许服务器的 80 / 443 端口访问。安装 Nginx 和 Certbot：

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

**第 2 步：** 创建站点配置 `/etc/nginx/sites-available/bot.example.com`，将示例域名替换为自己的域名：

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

启用站点并检查配置：

```bash
sudo ln -s /etc/nginx/sites-available/bot.example.com /etc/nginx/sites-enabled/bot.example.com
sudo nginx -t
sudo systemctl reload nginx
```

**第 3 步：** 使用 Certbot 为该域名配置 HTTPS（证书签发需要域名已正确解析且公网 80 端口可访问）：

```bash
sudo certbot --nginx -d bot.example.com --redirect
```

完成后打开 `https://bot.example.com`。如控制台页面可打开但实时状态没有刷新，请检查反向代理的 WebSocket / 长连接配置。

### 临时通过 SSH 访问

尚未配置域名时，可从自己的电脑建立 SSH 隧道：

```bash
ssh -L 18765:127.0.0.1:8765 root@SERVER_IP
```

保持 SSH 连接，在本地浏览器打开 `http://127.0.0.1:18765`。其中 `root@SERVER_IP` 按实际 SSH 账户与服务器地址替换。

## 5. 云端更新与旧版迁移

### 云端更新

控制台提示新版本时，可使用**更新**入口升级。更新完成后检查版本、配置及运行状态。

如果无法通过控制台更新，可以在 SSH 中运行已安装目录下的脚本：

```bash
sudo bash /opt/polymarket-cloud/install-cloud.sh update
```

自定义目录时改用原安装路径，例如：

```bash
sudo bash /srv/polymarket-cloud/install-cloud.sh update
```

更新前可查看对应的 [Release 说明](https://github.com/naka2027/polymarket-bot/releases)，并检查是否存在需要处理的订单或异常。

### 旧版云端迁移

旧目录结构的安装需要使用迁移脚本，而不是重新执行首次安装命令。迁移前需满足对应版本的检查和回退要求。自动识别旧安装目录的命令：

```bash
curl -fsSL https://raw.githubusercontent.com/naka2027/polymarket-bot/main/migrate-cloud.sh \
  | sudo bash -s -- --auto
```

如果旧安装无法自动识别，可参考相应版本说明，使用 `--source-dir` 指定实际的旧安装目录。迁移脚本在无法确认旧版本或回退条件时会停止执行。

## 6. 安装后的下一步

安装服务 → [配置反向代理](#4-域名与反向代理访问控制台) → [激活授权及首次配置](./quick-start.md) → [运行维护与常见问题](./operations-security.md)。
